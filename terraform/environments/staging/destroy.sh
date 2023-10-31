#!/bin/bash

echo "***** Fetching credentials, authenticating and configuring gcloud CLI"
# Update below with appropriate credentials file path
GOOGLE_APPLICATION_CREDENTIALS=".secrets/dem-prj-s-gsa-g-terraform.json"

echo ""
echo "***** Authenticating gcloud CLI & fetching project variables"
cd bootstrap || exit
export TF_VAR_google_credentials_file_path="../../../../${GOOGLE_APPLICATION_CREDENTIALS}"
terraform init
terraform refresh
PROJECT_ID=$(terraform output -raw project_id)
ASSETS_BUCKET=$(terraform output -raw assets_bucket)
REPOSITORY_BASE_URL=$(terraform output -raw registry_base_url)
REPOSITORY_ID=$(terraform output -raw repository_id)
gcloud auth activate-service-account \
    --key-file="../../../../${GOOGLE_APPLICATION_CREDENTIALS}"

cd ../../../../code/demo-image || exit
IMAGE_URI="${REPOSITORY_BASE_URL}/${PROJECT_ID}/${REPOSITORY_ID}/$(basename "$PWD"):latest"

echo ""
echo "***** Destroying main staging infrastrcuture"
cd ../../terraform/environments/staging || exit
export TF_VAR_google_credentials_file_path="../../../${GOOGLE_APPLICATION_CREDENTIALS}"
terraform init -migrate-state \
    -backend-config="bucket=${ASSETS_BUCKET}" \
    -backend-config="credentials=../../../${GOOGLE_APPLICATION_CREDENTIALS}"
terraform destroy \
    -var="artifact_registry_repository=${REPOSITORY_ID}" \
    -var="image_uri=${IMAGE_URI}" \
    -auto-approve

echo ""
echo "***** Destroying staging bootstrap infrasctruture"
cd bootstrap || exit
export TF_VAR_google_credentials_file_path="../../../../${GOOGLE_APPLICATION_CREDENTIALS}"
terraform destroy -auto-approve
echo ""
echo "***** You will need to delete the terraform state bucket, terraform service account, and project manually"

echo ""
echo "***** Disabling Google Cloud Service APIs (you will need to disable the Service Usage API manually)"
gcloud services disable cloudresourcemanager.googleapis.com --project "${PROJECT_ID}"

echo ""
echo "***** Removing local Docker image"
docker rmi -f "${IMAGE_URI}"

echo ""
echo "***** Destroy process complete!"
