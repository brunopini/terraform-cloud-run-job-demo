#!/bin/bash

tf=""
gcreds="$GOOGLE_CREDENTIALS_PATH"
env="$ENV_PATH"
ghcreds="$GITHUB_CREDENTIALS_PATH"
assets="$ASSETS_BUCKET"
first=""
auto=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -tf|--terraform) tf="$2"; shift 2;;
        -gcreds|--google-credentials) gcreds="$2"; shift 2;;
        -env|--environment) env="$2"; shift 2;;
        -ghcreds|--github-credentials) ghcreds="$2"; shift 2;;
        -assets|--assets-bucket) assets="$2"; shift 2;;
        -first|--first-build) first="--first-build"; shift 1;;
        -auto|--auto-approve) auto="--auto-approve"; shift 1;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

echo "***** Building [$env] main infrastrcuture"
cd "$ROOT_DIR/terraform/environments/$env" ||
    { echo "Cannot cd into $ROOT_DIR/terraform/environments/$env"; exit 1; }

if [ -z "$GOOGLE_CREDENTIALS_PATH" ] && [ -n "$gcreds" ]; then
    export GOOGLE_CREDENTIALS_PATH="$gcreds"
fi

if [ -z "$GITHUB_CREDENTIALS_PATH" ] && [ -n "$ghcreds" ]; then
    export GITHUB_CREDENTIALS_PATH="$ghcreds"
fi

if [ -z "$ASSETS_BUCKET" ] && [ -n "$assets" ]; then
    export ASSETS_BUCKET="$assets"
fi

export TF_VAR_google_credentials_path="$GOOGLE_CREDENTIALS_PATH"
if [ -n "$GITHUB_ENV" ]; then
    echo "google_credentials_path=$GOOGLE_CREDENTIALS_PATH" >> "$GITHUB_ENV"
fi

if [ -z "$PROJECT_ID" ] ||
    [ -z "$ASSETS_BUCKET" ] ||
    [ -z "$REGISTRY_BASE_URL" ] ||
    [ -z "$REGISTRY_ID" ] ||
    [ -z "$REPOSITORY_ID" ] ||
    [ -z "$IMAGE_URL" ]; then
        terraform init \
            -migrate-state \
            -backend-config="bucket=$ASSETS_BUCKET" \
            -backend-config="credentials=$GOOGLE_CREDENTIALS_PATH"
fi

if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID=$(terraform output -raw project_id);
    export PROJECT_ID="$PROJECT_ID"
fi
if [ -z "$ASSETS_BUCKET" ]; then
    ASSETS_BUCKET=$(terraform output -raw assets_bucket)
    export ASSETS_BUCKET="$ASSETS_BUCKET"
fi
if [ -z "$REGISTRY_BASE_URL" ]; then
    REGISTRY_BASE_URL=$(terraform output -raw registry_base_url)
    export REGISTRY_BASE_URL="$REGISTRY_BASE_URL"
fi
if [ -z "$REGISTRY_ID" ]; then
    REGISTRY_ID=$(terraform output -raw registry_id)
    export REGISTRY_ID="$REGISTRY_ID"
fi
if [ -z "$REPOSITORY_ID" ]; then
    REPOSITORY_ID=$(terraform output -raw docker_repository_id)
    export REPOSITORY_ID="$REPOSITORY_ID"
fi
if [ -z "$IMAGE_URL" ]; then
    IMAGE_URL=$(terraform output -raw image_url)
    export IMAGE_URL="$IMAGE_URL"
fi
if [ -n "$GITHUB_TOKEN" ]; then
    github=true
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
        REGISTRY_BASE_URL=$(terraform output -raw registry_base_url)
        REPOSITORY_ID=$(terraform output -raw docker_repository_id)
        IMAGE_URL=$(terraform output -raw image_url)
        export PROJECT_ID="$PROJECT_ID"
        export ASSETS_BUCKET="$ASSETS_BUCKET"
        export REGISTRY_ID="$REGISTRY_ID"
        export REGISTRY_BASE_URL="$REGISTRY_BASE_URL"
        export REPOSITORY_ID="$REPOSITORY_ID"
        export IMAGE_URL="$IMAGE_URL"
fi

export PROJECT_ID="$PROJECT_ID"
export TF_VAR_assets_bucket="$ASSETS_BUCKET"
export TF_VAR_docker_repository_id="$REPOSITORY_ID"
export TF_VAR_image_url="$IMAGE_URL"


if [ -n "$GITHUB_ENV" ]; then
    {
        echo "project_id=$PROJECT_ID"
        echo "assets_bucket=$ASSETS_BUCKET"
        echo "repository_id=$REPOSITORY_ID"
        echo "registry_base_url=$REGISTRY_BASE_URL"
        echo "image_url=$IMAGE_URL"
    } >> "$GITHUB_ENV"
fi

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
