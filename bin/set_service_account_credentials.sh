#!/bin/bash

filename=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -filename|--filename) filename="$2"; shift 2;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

echo "***** Exporting TF_VAR_google_credentials_file=$ROOT_DIR/.secrets/$filename"
export TF_VAR_google_credentials_file_path="$ROOT_DIR/.secrets/$filename"
echo "$TF_VAR_google_credentials_file_path"

echo "***** Activating gcloud CLI"
gcloud auth activate-service-account --key-file="$TF_VAR_google_credentials_file_path"
