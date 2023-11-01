#!/bin/bash

set -e

# Get the directory of the current script and export root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR="$(cd "$SCRIPT_DIR/../../../" && pwd)"

echo "***** Starting destroy process"
echo ""

# Update with  environment name (matching `terraform/environments/`)
source "$ROOT_DIR/bin/env_set.sh" \
    --environment staging

# Update with credentials json file name in `.secrets/`
source "$ROOT_DIR/bin/service_account_credentials_set.sh" \
    --filename dem-prj-s-gsa-g-terraform.json

source "$ROOT_DIR/bin/bootstrap_variables_set.sh"

source "$ROOT_DIR/bin/gcloud_cli_enable.sh"

# "destroy" command passed to terraform and "--auto-approve" flag (must be) passed to terraform
source "$ROOT_DIR/bin/terraform_main.sh" \
    --terraform destroy \
    --auto-approve

source "$ROOT_DIR/bin/terraform_bootstrap.sh" \
    --terraform destroy \
    --auto-approve

# Image name defaults to "--image-path" and label to latest (optional args available)
source "$ROOT_DIR/bin/docker_image.sh" \
    --docker rmi \
    --image-path code/demo-image \
    --image-name demo-image

source "$ROOT_DIR/bin/gcloud_cli_disable.sh"

echo "***** Destroy process complete!"
