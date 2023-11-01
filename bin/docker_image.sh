#!/bin/bash

quiet=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -quiet|--quiet) quiet="--quiet"; shift 1;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

echo "***** Authenticating remote docker repository and pushing [$IMAGE_URL]"
gcloud auth configure-docker "$REPOSITORY_BASE_URL" $quiet
docker push "$IMAGE_URL"
