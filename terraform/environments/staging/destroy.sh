#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../" && pwd)"

# Fill in!
env="staging"
gcreds="$ROOT_DIR/.secrets/dem-prj-s-gsa-g-terraform.json"
assets=$ASSETS_BUCKET
ghcreds="${GITHUB_CREDENTIALS_PATH:-$ROOT_DIR/.secrets/github.env}"
github=$GITHUB_RESOURCES
keepdocker=false
keepbase=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -env|--environment) env="$2"; shift 2;;
        -gcreds|--goog-credentials) gcreds="$2"; shift 2;;
        -assets|--assets-bucket) assets="$2"; shift 2;;
        -github|--github-actions) github=true; shift 1;;
        -keepdocker|--keep-docker) keepdocker=true; shift 1;;
        -keepbase|--keep-base) keepbase=true; shift 1;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

if [ -z "$GITHUB_RESOURCES" ]; then
    github=false
fi
if [ "$github" == true ] && [ -z "$GITHUB_TOKEN" ]; then
    export GITHUB_CREDENTIALS_PATH="$ghcreds"
fi
if [ -z "$ASSETS_BUCKET" ] && [ -n "$assets" ]; then
    ASSETS_BUCKET="$assets"
fi

export ROOT_DIR="$ROOT_DIR"
export ENV_PATH="$env"
export GOOGLE_CREDENTIALS_PATH="$gcreds"
export ASSETS_BUCKET=$ASSETS_BUCKET

echo "***** Starting destroy process"

# Get outputs as variables
source "$ROOT_DIR/bin/tf_main.sh" \
    --terraform output

# `destroy` command passed to terraform and '--auto-approve' flag (must be) passed to terraform
source "$ROOT_DIR/bin/tf_main.sh" \
    --terraform destroy \
    --auto-approve

if [ "$keepbase" == false ]; then
    source "$ROOT_DIR/bin/tf_base.sh" \
        --terraform destroy \
        --auto-approve
fi

# Image name defaults to `--image-path` and label to latest (optional args available)
if [ "$keepdocker" == false ]; then
    source "$ROOT_DIR/bin/docker.sh" \
        --docker rmi \
        --image-path demo-image \
        --image-name demo-image
fi

echo "***** Destroy process complete!"
