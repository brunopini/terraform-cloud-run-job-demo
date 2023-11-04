#!/bin/bash

set -e

if [ -z "$ROOT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(cd "$SCRIPT_DIR/../../../" && pwd)"
fi

# Fill in!
env="${ENV_PATH:-staging}"
gcreds="${GOOGLE_CREDENTIALS_PATH:-$ROOT_DIR/.secrets/dem-prj-s-gsa-g-terraform.json}"
ghcreds="${GITHUB_CREDENTIALS_PATH:-$ROOT_DIR/.secrets/github.env}"
github=false
first=""
import=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -env|--environment) env="$2"; shift 2;;
        -gcreds|--google-credentials) gcreds="$2"; shift 2;;
        -github|--github-actions) github=true; shift 1;;
        -first|--first-build) first="--first-build"; shift 1;;
        -import|--import-bucket) import="$2"; shift 2;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

export ROOT_DIR="$ROOT_DIR"
export ENV_PATH="$env"
export GOOGLE_CREDENTIALS_PATH=$gcreds

if [ "$github" == true ] && [ -z "$GITHUB_TOKEN" ]; then
    export GITHUB_CREDENTIALS_PATH="$ghcreds"
fi

echo "***** Starting build process"

# Reads output of main or base infrastructure
if [ "$first" == "--first-build" ]; then
    source "$ROOT_DIR/bin/base_var.sh"; else
    source "$ROOT_DIR/bin/tf_main.sh" -tf output
fi

# `--enable` or `--disable`
source "$ROOT_DIR/bin/gcloud.sh" --enable

# `apply` command passed to terraform and '--auto-approve' flag (must be) passed to terraform
source "$ROOT_DIR/bin/tf_base.sh" \
    --terraform apply \
    ${import:+--import-bucket "$import"} \
    --auto-approve

# Image name defaults to `--image-path` and label to latest (optional args available)
# If `--push` is passed, Docker will push to repositoy, and `--quiet` flag must be passed
source "$ROOT_DIR/bin/docker.sh" \
    --docker build \
    --image-path demo-image \
    --image-name demo-image \
    --push \
    --quiet

# `--first-build` will import artifact registry created by base
# `--github-resources` will create a github google service account secret
source "$ROOT_DIR/bin/tf_main.sh" \
    --terraform apply \
    $first \
    --auto-approve

echo "***** Build process complete!"
