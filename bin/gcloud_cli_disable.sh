#!/bin/bash

echo "***** Disabling Cloud Resource Manager API in ${PROJECT_ID}"
gcloud services disable cloudresourcemanager.googleapis.com --project "${PROJECT_ID}"

echo ""
