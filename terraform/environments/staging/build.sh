#!/bin/bash

set -e

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR="$(cd "$SCRIPT_DIR/../../../" && pwd)"

echo "***** Starting build process"
echo ""

# Update with  environment name (matching `terraform/environments/`)
source "$ROOT_DIR/bin/set_env.sh" --environment staging
echo ""

# Update with credentials json file name in `.secrets/`
source "$ROOT_DIR/bin/set_service_account_credentials.sh" \
    --filename dem-prj-s-gsa-g-terraform.json
echo ""

source "$ROOT_DIR/bin/set_bootstrap_variables.sh"
echo ""

source "$ROOT_DIR/bin/enable_gcloud_cli.sh"
echo ""

# "apply" command passed to terraform and "--auto-approve" flag (must be) passed to terraform
source "$ROOT_DIR/bin/terraform_bootstrap.sh" --terraform apply --auto-approve
echo ""

# Image name defaults to "--image-path" and label to latest (optional args available)
source "$ROOT_DIR/bin/docker_image.sh" --docker build \
    --image-path code/demo-image \
    --image-name demo-image
echo ""

# "--quiet" flag (must be) passed to gcloud auth configure-docker
source "$ROOT_DIR/bin/push_docker_image.sh" --quiet
echo ""

source "$ROOT_DIR/bin/terraform_main.sh" --terraform apply --auto-approve
echo ""

echo "***** Build process complete!"
