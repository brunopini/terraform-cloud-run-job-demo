#!/bin/bash

set -e

# Get the directory of the current script and export root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR="$(cd "$SCRIPT_DIR/../../../" && pwd)"

echo "***** Starting build process"
echo ""

# Update with  environment name (matching `terraform/environments/`)
source "$ROOT_DIR/bin/env_set.sh" \
    --environment staging

# Update with credentials json file name in `.secrets/`
source "$ROOT_DIR/bin/service_account_credentials_set.sh" \
    --filename dem-prj-s-gsa-g-terraform.json

source "$ROOT_DIR/bin/bootstrap_variables_set.sh"

source "$ROOT_DIR/bin/gcloud_cli_enable.sh"

# "apply" command passed to terraform and "--auto-approve" flag (must be) passed to terraform
source "$ROOT_DIR/bin/terraform_bootstrap.sh" \
    --terraform apply \
    --auto-approve

# Image name defaults to "--image-path" and label to latest (optional args available)
# If "--push" is passed, Docker will push to repositoy, and "--quiet" flag must be passed
source "$ROOT_DIR/bin/docker_image.sh" \
    --docker build \
    --image-path code/demo-image \
    --image-name demo-image \
    --push \
    --quiet

source "$ROOT_DIR/bin/terraform_main.sh" \
    --terraform apply \
    --auto-approve

echo "***** Build process complete!"
