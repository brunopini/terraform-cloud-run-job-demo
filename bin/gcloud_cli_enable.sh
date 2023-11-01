#!/bin/bash

echo "***** Enabling Cloud Resource Manager API in ${PROJECT_ID}"
gcloud services enable cloudresourcemanager.googleapis.com --project "${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}"

echo ""
