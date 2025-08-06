#!/usr/bin/env bash
set -e

# set up 

# set up conda 

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
sudo -u ec2-user git config --global user.name

# set up dvc
# sudo -u ec2-user /home/ec2-user/.local/bin/micromamba install -c conda-forge dvc-s3 -y

# set up tailscale
sudo yum-config-manager -y --add-repo https://pkgs.tailscale.com/stable/amazon-linux/2/tailscale.repo
sudo yum install tailscale -y
sudo systemctl enable --now tailscaled