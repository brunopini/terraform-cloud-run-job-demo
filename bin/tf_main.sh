#!/bin/bash

tf=""
gcreds="$GOOGLE_CREDENTIALS_PATH"
env="$ENV_PATH"
ghcreds="$GITHUB_CREDENTIALS_PATH"
first=""
auto=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -tf|--terraform) tf="$2"; shift 2;;
        -gcreds|--google-credentials) gcreds="$2"; shift 2;;
        -env|--environment) env="$2"; shift 2;;
        -ghcreds|--github-credentials) ghcreds="$2"; shift 2;;
        -first|--first-build) first="--first-build"; shift 1;;
        -auto|--auto-approve) auto="--auto-approve"; shift 1;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

echo "***** Building [$env] main infrastrcuture"
cd "$ROOT_DIR/terraform/environments/$env" ||
    { echo "Cannot cd into $ROOT_DIR/terraform/environments/$env"; exit 1; }

if [ -z "$GOOGLE_CREDENTIALS_PATH" ] && [ -n "$gcreds" ]; then
    GOOGLE_CREDENTIALS_PATH="$gcreds"
fi

if [ -z "$GITHUB_CREDENTIALS_PATH" ] && [ -n "$ghcreds" ]; then
    GITHUB_CREDENTIALS_PATH="$ghcreds"
fi

export TF_VAR_google_credentials_path="$GOOGLE_CREDENTIALS_PATH"
echo "google_credentials_path=$GOOGLE_CREDENTIALS_PATH" >> "$GITHUB_ENV"

if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID=$(terraform output -raw project_id);
fi
if [ -z "$ASSETS_BUCKET" ]; then
    ASSETS_BUCKET=$(terraform output -raw assets_bucket)
fi
if [ -z "$REGISTRY_ID" ]; then
    REGISTRY_ID=$(terraform output -raw registry_id)
fi
if [ -z "$REPOSITORY_ID" ]; then
    REPOSITORY_ID=$(terraform output -raw docker_repository_id)
fi
if [ -z "$IMAGE_URL" ]; then
    IMAGE_URL=$(terraform output -raw image_url)
fi
if [ -n "$GITHUB_TOKEN" ]; then
    github=$(terraform output -raw create_github_resources)
fi

if [ -z "$PROJECT_ID" ] ||
    [ -z "$ASSETS_BUCKET" ] ||
    [ -z "$REGISTRY_ID" ] ||
    [ -z "$REPOSITORY_ID" ] ||
    [ -z "$IMAGE_URL" ]; then
        cd base || { echo "Cannot cd into base"; exit 1; }
        PROJECT_ID=$(terraform output -raw project_id)
        ASSETS_BUCKET=$(terraform output -raw assets_bucket)
        REGISTRY_ID=$(terraform output -raw registry_id)
        REPOSITORY_ID=$(terraform output -raw docker_repository_id)
        IMAGE_URL=$(terraform output -raw image_url)
fi

export PROJECT_ID="$PROJECT_ID"
export TF_VAR_assets_bucket="$ASSETS_BUCKET"
export TF_VAR_docker_repository_id="$REPOSITORY_ID"
export TF_VAR_image_url="$IMAGE_URL"

{
        echo "project_id=$PROJECT_ID"
        echo "assets_bucket=$ASSETS_BUCKET"
        echo "repository_id=$REPOSITORY_ID"
        echo "image_url=$IMAGE_URL"
    } >> "$GITHUB_ENV"

echo "::set-output name=project_id::$PROJECT_ID"
echo "::set-output name=docker_repository_id::$REPOSITORY_ID"
echo "::set-output name=image_url::$IMAGE_URL"
echo "::set-output name=assets_bucket::$ASSETS_BUCKET"

terraform init \
    -migrate-state \
    -backend-config="bucket=$ASSETS_BUCKET" \
    -backend-config="credentials=$GOOGLE_CREDENTIALS_PATH"

if [ -n "$first" ] && [ "$first" == "--first-build" ]; then
    terraform import google_artifact_registry_repository.docker "$REGISTRY_ID"
fi

if [ "$tf" == "apply" ] || [ "$tf" == "destroy" ]; then
    if [ -n "$ghcreds" ] && [ -z "$GITHUB_TOKEN" ]; then
        source "$ROOT_DIR/.secrets/github.env"
        export TF_VAR_create_github_resources=$github
    fi
    terraform "$tf" $auto; else
    terraform "$tf"
fi
