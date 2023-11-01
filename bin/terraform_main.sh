#!/bin/bash

tf=""
auto=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -tf|--terraform) tf="$2"; shift 2;;
        -auto|--auto-approve) auto="--auto-approve"; shift 1;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

echo "***** Building [$ENV_PATH] main infrastrcuture"
cd "$ROOT_DIR/terraform/environments/$ENV_PATH" || { echo "Cannot cd into ${ROOT_DIR}/${path}"; exit 1; }
terraform init -migrate-state \
    -backend-config="bucket=$ASSETS_BUCKET" \
    -backend-config="credentials=$TF_VAR_google_credentials_file_path"
terraform "$tf" \
    -var="artifact_registry_repository=$REPOSITORY_ID" \
    -var="image_uri=$IMAGE_URL" \
    $auto

echo ""
