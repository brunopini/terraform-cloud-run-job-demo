#!/bin/bash

if [ -n "$GITHUB_ENV" ]; then
    {
        echo "project_id=$PROJECT_ID"
        echo "assets_bucket=$ASSETS_BUCKET"
        echo "repository_id=$REPOSITORY_ID"
        echo "registry_base_url=$REGISTRY_BASE_URL"
        echo "image_url=$IMAGE_URL"
        echo "google_credentials_path=$GOOGLE_CREDENTIALS_PATH"
        echo "registry_id=$REGISTRY_ID"
    } >> "$GITHUB_ENV"
fi
