#!/bin/bash

set -e

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR="$(cd "$SCRIPT_DIR/../../../" && pwd)"

echo "***** Starting destroy process"
echo ""

# Update with  environment name (matching `terraform/environments/`)
source "$ROOT_DIR/bin/set_env.sh" -environment staging
echo ""

# Update with credentials json file name in `.secrets/`
source "$ROOT_DIR/bin/set_service_account_credentials.sh" -filename dem-prj-s-gsa-g-terraform.json
echo ""

source "$ROOT_DIR/bin/set_bootstrap_variables.sh"
echo ""

source "$ROOT_DIR/bin/enable_gcloud_cli.sh"
echo ""

# "destroy" command passed to terraform and "--auto-approve" flag (must be) passed to terraform
source "$ROOT_DIR/bin/terraform_main.sh" --terraform destroy --auto-approve
echo ""

source "$ROOT_DIR/bin/terraform_bootstrap.sh" --terraform destroy --auto-approve
echo ""

# Image name defaults to "--image-path" and label to latest (optional args available)
source "$ROOT_DIR/bin/docker_image.sh" --docker rmi \
    --image-path code/demo-image \
    --image-name demo-image
echo ""

source "$ROOT_DIR/bin/disable_gcloud_cli.sh"
echo ""

echo ""
echo "***** Destroy process complete!"
