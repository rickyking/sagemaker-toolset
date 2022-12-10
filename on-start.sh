#!/usr/bin/env bash
set -e

# set up ngrok ssh tunnel
export NGROK_AUTH_TOKEN="2HawVv4s3VLRT8LDNqkn7NwmBeZ_6xd3c42Y23RnBFojW4dKd"
curl https://raw.githubusercontent.com/rickyking/sagemaker-toolset/main/ssh/on-start-ngrok.sh | bash

# set up conda env persist
curl https://raw.githubusercontent.com/rickyking/sagemaker-toolset/main/save-conda-env/on-start.sh | bash

# set up micromamba
export MAMBA_ROOT_PREFIX="/home/ec2-user/SageMaker/.persisted_conda"
cd /home/ec2-user/
sudo -u ec2-user curl micro.mamba.pm/install.sh --output install.sh
chmod +x install.sh
sudo -u ec2-user bash install.sh

# set up GH
sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
sudo yum install -y gh

# set up git
sudo -u ec2-user git config --global user.name 'Yi Jin'
sudo -u ec2-user git config --global user.email "yi.jin@riotinto.com"

# set up dvc
# sudo -u ec2-user /home/ec2-user/.local/bin/micromamba install -c conda-forge dvc-s3 -y
