#!/bin/bash

tf=""
gcreds=$GOOGLE_CREDENTIALS_PATH
env=$ENV_PATH
github=$GITHUB_RESOURCES
ghcreds=$GITHUB_CREDENTIALS_PATH
assets=$ASSETS_BUCKET
frombase=""
auto=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -tf|--terraform) tf="$2"; shift 2;;
        -gcreds|--google-credentials) gcreds="$2"; shift 2;;
        -env|--environment) env="$2"; shift 2;;
        -ghcreds|--github-credentials) ghcreds="$2"; shift 2;;
        -assets|--assets-bucket) assets="$2"; shift 2;;
        -frombase|--from-base) frombase="--from-base"; shift 1;;
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
if [ -z "$ASSETS_BUCKET" ] && [ -n "$assets" ]; then
    ASSETS_BUCKET="$assets"
fi
if [ -z "$GITHUB_RESOURCES" ]; then
    github=false
fi
if [ -z "$GITHUB_CREDENTIALS_PATH" ] && [ -n "$ghcreds" ]; then
    GITHUB_CREDENTIALS_PATH="$ghcreds"
fi
if [ -n "$GITHUB_TOKEN" ]; then
    github=true
fi
if [ "$github" == true ] && [ -n "$ghcreds" ] && [ -z "$GITHUB_TOKEN" ]; then
    # shellcheck disable=SC1090
    source "${ghcreds}"
fi

export TF_VAR_google_credentials_path="$GOOGLE_CREDENTIALS_PATH"
export TF_VAR_assets_buckes="$ASSETS_BUCKET"

if [ -z "$PROJECT_ID" ] ||
    [ -z "$REGISTRY_BASE_URL" ] ||
    [ -z "$REGISTRY_ID" ] ||
    [ -z "$REPOSITORY_ID" ] ||
    [ -z "$IMAGE_URL" ]; then
        terraform init \
            -migrate-state \
            -backend-config="bucket=$ASSETS_BUCKET" \
            -backend-config="credentials=$GOOGLE_CREDENTIALS_PATH"
        init=true
        if [ -z "$PROJECT_ID" ]; then
            PROJECT_ID=$(terraform output -raw project_id);
        fi
        if [ -z "$REGISTRY_BASE_URL" ]; then
            REGISTRY_BASE_URL=$(terraform output -raw registry_base_url)
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
        if [ -z "$GITHUB_REPOSITORY" ]; then
            GITHUB_REPOSITORY=$(terraform output -raw github_repository)
        fi
fi

export PROJECT_ID=$PROJECT_ID
export ASSETS_BUCKET=$ASSETS_BUCKET
export REGISTRY_ID=$REGISTRY_ID
export REGISTRY_BASE_URL=$REGISTRY_BASE_URL
export REPOSITORY_ID=$REPOSITORY_ID
export IMAGE_URL=$IMAGE_URL
export GITHUB_REPOSITORY=$GITHUB_REPOSITORY
export GITHUB_RESOURCES=$github

export TF_VAR_assets_bucket=$ASSETS_BUCKET
export TF_VAR_docker_repository_id=$REPOSITORY_ID
export TF_VAR_image_url=$IMAGE_URL
export TF_VAR_create_github_resources=$GITHUB_RESOURCES
export TF_VAR_github_repository=$GITHUB_REPOSITORY

source "${ROOT_DIR}/bin/_github_env.sh"

source "${ROOT_DIR}/bin/_gcloud.sh" --enable

if [ "$init" != true ]; then
    terraform init \
        -migrate-state \
        -backend-config="bucket=$ASSETS_BUCKET" \
        -backend-config="credentials=$GOOGLE_CREDENTIALS_PATH"
fi

if [ -n "$frombase" ] && [ "$frombase" == "--from-base" ]; then
    terraform import google_artifact_registry_repository.docker "$REGISTRY_ID"
fi

if [ "$tf" == "apply" ] || [ "$tf" == "destroy" ]; then
    terraform "$tf" $auto
fi
