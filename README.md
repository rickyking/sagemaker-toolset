# Sagemaker Toolset 

This tools set enables via [Ngrok](https://dashboard.ngrok.com/get-started/setup) the `ssh` into AWS Sagemaker Instance, persists self created environment.

Heavily borrowed by https://modelpredict.com/, repo serves as my personal toolset.

## Steps to follow

### Step 1. Create lifecycle configuration for Instance

```bash
# fill in the instance name here
INSTANCE_NAME="yi"

# check if a configuration is set
CONFIGURATION_NAME=$(aws sagemaker describe-notebook-instance --notebook-instance-name "${INSTANCE_NAME}" | jq -e '.NotebookInstanceLifecycleConfigName | select (.!=null)' | tr -d '"')
echo "Configuration \"$CONFIGURATION_NAME\" attached to notebook instance $INSTANCE_NAME"

# if not create 1 configuration file
if [[ -z "$CONFIGURATION_NAME" ]]; then
    # there is no attached configuration name, create a new one
    CONFIGURATION_NAME="better-sagemaker"
    echo "Creating new configuration $CONFIGURATION_NAME..."
    aws sagemaker create-notebook-instance-lifecycle-config \
        --notebook-instance-lifecycle-config-name "$CONFIGURATION_NAME" \
        --on-start Content=$(echo '#!/usr/bin/env bash'| base64) \
        --on-create Content=$(echo '#!/usr/bin/env bash' | base64)

    # attaching lifecycle configuration to the notebook instance
    echo "Attaching configuration $CONFIGURATION_NAME to ${INSTANCE_NAME}..."
    aws sagemaker update-notebook-instance \
        --notebook-instance-name "$INSTANCE_NAME" \
        --lifecycle-config-name "$CONFIGURATION_NAME"
fi
```

### Step 2. Set up SSH with Ngrok & Conda env persist & mamba

Ngrok is a third party reverse proxy that will tunnel our your traffic. Don’t worry, SSH is encrypted end to end so ngrok can’t read any of it.

To get permissions for creating TCP tunnels, you’ll need a free ngrok account and find an authentication token in their dashboard.

```bash
export NGROK_AUTH_TOKEN="FILL_TOKEN_HERE"

echo "Downloading on-start.sh..."
# save the existing on-start script into on-start.sh
aws sagemaker describe-notebook-instance-lifecycle-config --notebook-instance-lifecycle-config-name "$CONFIGURATION_NAME" | jq '.OnStart[0].Content'  | tr -d '"' | base64 --decode > on-start.sh

echo "Adding setups to on-start.sh..."
# add the code to setup SSH
echo '' >> on-start.sh
echo '# set up ngrok ssh tunnel' >> on-start.sh
echo "export NGROK_AUTH_TOKEN=\"${NGROK_AUTH_TOKEN}\"" >> on-start.sh
echo 'curl https://raw.githubusercontent.com/rickyking/sagemaker-toolset/main/ssh/on-start-ngrok.sh | bash' >> on-start.sh

# set up persisted conda environments
echo '# set up conda env persist' >> on-start.sh
echo 'curl https://raw.githubusercontent.com/rickyking/sagemaker-toolset/main/save-conda-env/on-start.sh | bash' >> on-start.sh

# set up micromamba
echo '# set up micromamba' >> on-start.sh
echo 'export MAMBA_ROOT_PREFIX="/home/ec2-user/SageMaker/.persisted_conda"' >> on-start.sh
echo 'cd /home/ec2-user/' >> on-start.sh
echo 'sudo -u ec2-user curl micro.mamba.pm/install.sh --output install.sh' >> on-start.sh
echo 'chmod +x install.sh' >> on-start.sh
echo 'sudo -u ec2-user bash install.sh' >> on-start.sh

# set up GH
echo '# setup GH' >> on-start.sh
echo 'sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo' >> on-start.sh
echo 'sudo yum install -y gh' >> on-start.sh

# set up Git
echo 'Set up Git' >> on-start.sh
echo 'sudo -u ec2-user git config --global user.email "yi.jin@riotinto.com"' >> on-start.sh
echo 'sudo -u ec2-user git config --global user.name "Yi Jin"' >> on-start.sh

# set up dvc
# echo 'sudo -u ec2-user micromamba install -c conda-forge dvc-s3' >> on-start.sh

# set up tailscale
echo '# setup tailscale' >> on-start.sh
echo 'sudo yum-config-manager -y --add-repo https://pkgs.tailscale.com/stable/amazon-linux/2/tailscale.repo' >> on-start.sh
echo 'sudo yum install tailscale -y' >> on-start.sh
echo 'sudo systemctl enable --now tailscaled' >> on-start.sh
echo 'sudo tailscale up --authkey TAILSCALE_KEY' >> on-start.sh

# make code cli available
echo '# setup code cli' >> on-start.sh
echo 'sudo -u ec2-user curl -Lk "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" --output /home/ec2-user/vscode_cli.tar.gz' >> on-start.sh
echo 'sudo -u ec2-user tar -xf /home/ec2-user/vscode_cli.tar.gz -C /home/ec2-user/' >> on-start.sh


echo "Uploading on-start.sh..."
# update the lifecycle configuration config with updated on-start.sh script
aws sagemaker update-notebook-instance-lifecycle-config \
    --notebook-instance-lifecycle-config-name "$CONFIGURATION_NAME" \
    --on-start Content="$((cat on-start.sh)| base64)"
```

That just made sure that ngrok starts every time the notebook instance starts, with your authentication token.

The ngrok config is located in /home/ec2-user/SageMaker/.ngrok/config.yml. If you want to add a fixed remote_addr to have the stable address to connect to (you’ll need a pro account for this), you can change it in the config file.

Also, if the tunnel ever closes (connections can drop), you can start the tunnel again by running start-ssh-ngrok in your SageMaker terminal. It will run in the background.

### Step 3. Setup SSH public key and connect

The public key should be placed under `~/SageMaker/ssh/authorized_keys`.

And the ssh command is `ssh -p 17887 ec2-user@0.tcp.ngrok.io` based on `~/SageMaker/SSH_INSTRUCTIONS` file.