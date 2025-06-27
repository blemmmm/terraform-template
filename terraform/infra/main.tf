terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Set the variable value in *.tfvars file
# or using -var="digitalocean_token=..." CLI option
variable "digitalocean_token" {
  type      = string
  sensitive = true
}

variable "github_token" {
  type      = string
  sensitive = true
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.digitalocean_token
}

provider "github" {
  token = var.github_token
  owner = "blemmmm"
}

# tls_private_key
resource "tls_private_key" "staging" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "blem_staging" {
  title      = "staging"
  repository = "terraform-template"
  key        = tls_private_key.staging.public_key_openssh
}

# Create a web server
# Create a new Web Droplet in the nyc2 region
resource "digitalocean_droplet" "web" {
  image     = "ubuntu-24-10-x64"
  name      = "staging-blem-dev"
  region    = "sgp1"
  size      = "s-2vcpu-2gb-amd"
  user_data = <<EOF
#!/bin/bash

curl -fsSL https://get.docker.com | sh

mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "${tls_private_key.staging.private_key_openssh}" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
chown root:root ~/.ssh/id_ed25519

echo "${tls_private_key.staging.public_key_openssh}" > ~/.ssh/id_ed25519.pub
chmod 644 ~/.ssh/id_ed25519.pub
chown root:root ~/.ssh/id_ed25519.pub

ssh-keyscan -t ed25519 -H github.com >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts

git clone git@github.com:blemmmm/terraform-template.git ~/terraform-template

cd ~/terraform-template/
git checkout staging

echo "ENVIRONMENT=staging" >> ~/terraform-template/.env
chmod 600 ~/terraform-template/.env

docker compose up -d
EOF
}


