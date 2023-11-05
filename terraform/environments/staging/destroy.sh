#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../" && pwd)"

# Fill in!
env="staging"
gcreds="$ROOT_DIR/.secrets/dem-prj-s-gsa-g-terraform.json"
ghcreds="${GITHUB_CREDENTIALS_PATH:-$ROOT_DIR/.secrets/github.env}"
github=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -env|--environment) env="$2"; shift 2;;
        -gcreds|--goog-credentials) gcreds="$2"; shift 2;;
        -github|--github-actions) github=true; shift 1;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

if [ "$github" == true ] && [ -z "$GITHUB_TOKEN" ]; then
    export GITHUB_CREDENTIALS_PATH="$ghcreds"
fi

export ROOT_DIR="$ROOT_DIR"
export ENV_PATH="$env"
export GOOGLE_CREDENTIALS_PATH="$gcreds"


if [ -n "$GITHUB_ENV" ]; then
    {
        echo "env_path=$ENV_PATH"
        echo "google_credentials_path=$GOOGLE_CREDENTIALS_PATH"
    } >> "$GITHUB_ENV"
fi

echo "***** Starting destroy process"

# Get outputs as variables
source "$ROOT_DIR/bin/tf_main.sh" \
    --terraform output

# `--enable` or `--disable`
source "$ROOT_DIR/bin/gcloud.sh" \
    --enable

# `destroy` command passed to terraform and '--auto-approve' flag (must be) passed to terraform
source "$ROOT_DIR/bin/tf_main.sh" \
    --terraform destroy \
    --auto-approve

source "$ROOT_DIR/bin/tf_base.sh" \
    --terraform destroy \
    --auto-approve

# Image name defaults to `--image-path` and label to latest (optional args available)
source "$ROOT_DIR/bin/docker.sh" \
    --docker rmi \
    --image-path demo-image \
    --image-name demo-image

source "$ROOT_DIR/bin/gcloud.sh" \
    --disable

echo "***** Destroy process complete!"
