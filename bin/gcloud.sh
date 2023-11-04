#!/bin/bash

cmd=""
gcreds="$GOOGLE_CREDENTIALS_PATH"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -gcreds|--google-credentials) gcreds="$2"; shift 2;;
        -enable|--enable) cmd="enable"; shift 1;;
        -disable|--disable) cmd="disable"; shift 1;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

if [ -z "$cmd" ]; then
    echo "Missing action command. --enable or --disable"
    exit 1
fi

if [ "$cmd" == "enable" ]; then
    log="Enabling"
fi

if [ "$cmd" == "disable" ]; then
    log="Disabling"
fi

echo "***** $log Cloud Resource Manager API in $PROJECT_ID"

gcloud auth activate-service-account --key-file="$gcreds"
if [ "$cmd" == "destroy" ]; then
  gcloud services disable cloudresourcemanager.googleapis.com --project "$PROJECT_ID" --force
else
  gcloud services $cmd cloudresourcemanager.googleapis.com --project "$PROJECT_ID"
fi

if [ "$cmd" == "enable" ]; then
    gcloud config set project "$PROJECT_ID"
fi
