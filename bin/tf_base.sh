#!/bin/bash

tf=""
gcreds="$GOOGLE_CREDENTIALS_PATH"
env="$ENV_PATH"
import=""
auto=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -tf|--terraform) tf="$2"; shift 2;;
        -gcreds|--google-credentials) gcreds="$2"; shift 2;;
        -env|--environment) env="$2"; shift 2;;
        -import|--import-bucket) import="$2"; shift 2;;
        -auto|--auto-approve) auto="--auto-approve"; shift 1;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

echo "***** Building $env base infrastructure"
cd "$ROOT_DIR/terraform/environments/$env/base" ||
    { echo "Cannot cd into $ROOT_DIR/terraform/environments/$env/base"; exit 1; }

if [ -z "$GOOGLE_CREDENTIALS_PATH" ] && [ -n "$gcreds" ]; then
    GOOGLE_CREDENTIALS_PATH="$gcreds"
fi

source "${ROOT_DIR}/bin/_github_env.sh"

export GOOGLE_CREDENTIALS_PATH=$GOOGLE_CREDENTIALS_PATH
export TF_VAR_google_credentials_path=$GOOGLE_CREDENTIALS_PATH

if [ -z "$PROJECT_ID" ]; then
        source ${ROOT_DIR}/bin/_read_project_id.sh
fi

source "${ROOT_DIR}/bin/_gcloud.sh" --enable

terraform init

if [ -n "$import" ]; then
    echo "importing bucket $import"
    terraform import google_storage_bucket.terraform_state "$import"
fi

terraform "$tf" $auto

if [ "$tf" != "destroy" ]; then
    project_id=$(terraform output -raw project_id)
    assets_bucket=$(terraform output -raw assets_bucket)
    registry_base_url=$(terraform output -raw registry_base_url)
    repository_id=$(terraform output -raw repository_id)
    registry_id=$(terraform output -raw registry_id 2>/dev/null)

    export PROJECT_ID="$project_id"
    export ASSETS_BUCKET="$assets_bucket"
    export REGISTRY_BASE_URL="$registry_base_url"
    export REPOSITORY_ID="$repository_id"
    export REGISTRY_ID="$registry_id"

    source "${ROOT_DIR}/bin/_github_env.sh"
else
    source "${ROOT_DIR}/bin/_gcloud.sh" --disable
fi
