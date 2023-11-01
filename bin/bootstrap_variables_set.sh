#!/bin/bash

cd "${ROOT_DIR}/terraform/environments/${ENV_PATH}/bootstrap" || { echo "Cannot cd into ${ROOT_DIR}/${path}"; exit 1; }

echo "***** Exporting TF bootstrap variables"
terraform init && terraform refresh

export PROJECT_ID=$(terraform output -raw project_id)
export ASSETS_BUCKET=$(terraform output -raw assets_bucket)
export REPOSITORY_BASE_URL=$(terraform output -raw registry_base_url)
export REPOSITORY_ID=$(terraform output -raw repository_id)

echo ""
