#!/bin/bash

gcreds="$GOOGLE_CREDENTIALS_PATH"
env="$ENV_PATH"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -gcreds|--google-credentials) gcreds="$2"; shift 2;;
        -env|--environment) env="$2"; shift 2;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

echo "***** Exporting TF base variables"
cd "$ROOT_DIR/terraform/environments/$env/base" ||
    { echo "Cannot cd into $ROOT_DIR/terraform/environments/$env/base"; exit 1; }

export GOOGLE_CREDENTIALS_PATH="$gcreds"
export TF_VAR_google_credentials_path="$gcreds"

terraform init && terraform refresh
project_id=$(terraform output -raw project_id)
assets_bucket=$(terraform output -raw assets_bucket)
repository_base_url=$(terraform output -raw registry_base_url)
repository_id=$(terraform output -raw repository_id)
registry_id=$(terraform output -raw registry_id)

export PROJECT_ID="$project_id"
export ASSETS_BUCKET="$assets_bucket"
export REPOSITORY_BASE_URL="$repository_base_url"
export REPOSITORY_ID="$repository_id"
export REGISTRY_ID="$registry_id"

echo "::set-output name=project_id::$PROJECT_ID"
echo "::set-output name=assets_bucket::$ASSETS_BUCKET"
echo "::set-output name=repository_base_url::$REPOSITORY_BASE_URL"
echo "::set-output name=repository_id::$REPOSITORY_ID"
echo "::set-output name=registry_id::$REGISTRY_ID"
