#!/bin/bash

echo "***** Fetching credentials, authenticating and configuring gcloud CLI"
# Update below with appropriate credentials file path
GOOGLE_APPLICATION_CREDENTIALS=".secrets/dem-prj-s-gsa-g-terraform.json"

echo ""
echo "***** Authenticating gcloud CLI & building staging bootstrap infrasctruture"
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
gcloud services enable cloudresourcemanager.googleapis.com --project "${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}"
terraform apply -auto-approve

echo ""
echo "***** Building and pushing images to remote repository"
cd ../../../../code/demo-image || exit
IMAGE_URI="${REPOSITORY_BASE_URL}/${PROJECT_ID}/${REPOSITORY_ID}/$(basename "$PWD"):latest"
docker build -t "${IMAGE_URI}" .
gcloud auth configure-docker "${REPOSITORY_BASE_URL}" --quiet
docker push "${IMAGE_URI}"

echo ""
echo "***** Building main staging infrastrcuture"
cd ../../terraform/environments/staging || exit
export TF_VAR_google_credentials_file_path="../../../${GOOGLE_APPLICATION_CREDENTIALS}"
terraform init -migrate-state \
    -backend-config="bucket=${ASSETS_BUCKET}" \
    -backend-config="credentials=../../../${GOOGLE_APPLICATION_CREDENTIALS}"
terraform apply \
    -var="artifact_registry_repository=${REPOSITORY_ID}" \
    -var="image_uri=${IMAGE_URI}" \
    -auto-approve

echo ""
echo "***** Build process complete!"
