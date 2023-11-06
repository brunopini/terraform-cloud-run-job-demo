#!/bin/bash

set -e

if [ -z "$ROOT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(cd "$SCRIPT_DIR/../../../" && pwd)"
fi

# Default config
env="${ENV_PATH:-staging}"
gcreds="${GOOGLE_CREDENTIALS_PATH:-$ROOT_DIR/.secrets/dem-prj-s-gsa-g-terraform.json}"
ghcreds="${GITHUB_CREDENTIALS_PATH:-$ROOT_DIR/.secrets/github.env}"
assets=$ASSETS_BUCKET
github=$GITHUB_RESOURCES
frombase=""
import=""
skipdocker=false
dockeronly=false
imagename="demo-image"
imagepath="demo-image"
imagelabel="latest"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -env|--environment) env="$2"; shift 2;;
        -gcreds|--google-credentials) gcreds="$2"; shift 2;;
        -assets|--assets-bucket) assets="$2"; shift 2;;
        -github|--github-actions) github=true; shift 1;;
        -frombase|--from-base) frombase="--from-base"; shift 1;;
        -import|--import-bucket) import="$2"; shift 2;;
        -skipdocker|--skip-docker) skipdocker=true; shift 1;;
        -dockeronly|--docker-only) dockeronly=true; shift 1;;
        -image-name|--image-name) imagename="$2"; shift 2;;
        -image-path|--image-path) imagepath="$2"; shift 2;;
        -image-label|--image-label) imagelabel="$2"; shift 2;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

if [ -z "$GITHUB_RESOURCES" ] && [ -z "$github" ]; then
    github=false
fi
if [ "$github" == true ] && [ -z "$GITHUB_TOKEN" ]; then
    GITHUB_CREDENTIALS_PATH="$ghcreds"
    # shellcheck disable=SC1090
    source "${ghcreds}"
fi
if [ -n "$GITHUB_TOKEN" ]; then
    github=true
fi
if [ -z "$ASSETS_BUCKET" ] && [ -n "$assets" ]; then
    ASSETS_BUCKET="$assets"
fi

export ROOT_DIR="$ROOT_DIR"
export ENV_PATH="$env"
export GOOGLE_CREDENTIALS_PATH=$gcreds
export ASSETS_BUCKET=$ASSETS_BUCKET
export GITHUB_RESOURCES=$github
export GITHUB_CREDENTIALS_PATH=$ghcreds
export GITHUB_TOKEN=$GITHUB_TOKEN

echo "***** Starting build process"

# Reads output of main or base infrastructure
if [ "$frombase" == "--from-base" ]; then
    # source "${ROOT_DIR}/bin/base_var.sh"
    source "${ROOT_DIR}/bin/tf_base.sh" \
        --terraform apply \
        ${import:+--import-bucket "$import"} \
        --auto-approve
else
    source "${ROOT_DIR}/bin/tf_main.sh" --terraform output
fi

# Image name defaults to `--image-path` and label to latest (optional args available)
# If `--push` is passed, Docker will push to repositoy, and `--quiet` flag must be passed
if [ "$skipdocker" == false ]; then
    source "${ROOT_DIR}/bin/docker.sh" \
        --docker build \
        --image-path "$imagepath" \
        --image-name "$imagename" \
        --image-label "$imagelabel" \
        --push \
        --quiet
fi

# `--first-build` will import artifact registry created by base
# `--github-resources` will create a github google service account secret
if [ "$dockeronly" != true ]; then
    source "${ROOT_DIR}/bin/tf_main.sh" \
        --terraform apply \
        $frombase \
        --auto-approve
fi

echo "***** Build process complete!"
