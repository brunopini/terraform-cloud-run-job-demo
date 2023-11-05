#!/bin/bash

cmd="$DOCKER_CMD"
path="$IMAGE_PATH"
name="$IMAGE_NAME"
label="${IMAGE_LABEL:-latest}"
push=false
quiet=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -docker|--docker) cmd="$2"; shift 2;;
        -image-path|--image-path) path="$2"; shift 2;;
        -image|--image-name) name="$2"; shift 2;;
        -label|--label) label="$2"; shift 2;;
        -push|--push) push=true; shift 2;;
        -quiet|--quiet) quiet="--quiet"; shift 2;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

if [ -z "$cmd" ]; then
    echo "Missing --docker command"
    exit 1
fi

if [ -z "$path" ]; then
    echo "Missing --image-path"
    exit 1
fi

case "$cmd" in
    build)
        flag="-t"
        log="Building"
        ;;
    rmi)
        flag="-f"
        log="Removing"
        ;;
    *) echo "Unsupported command: $cmd"; exit 1 ;;
esac

cd "$ROOT_DIR/docker/${path}" || { echo "Cannot cd into $ROOT_DIR/docker/${path}"; exit 1; }
export IMAGE_URL="$REGISTRY_BASE_URL/$PROJECT_ID/$REPOSITORY_ID/$name:$label"
if [ -n "$GITHUB_ENV" ]; then
    echo "image_url=$IMAGE_URL" >> "$GITHUB_ENV"
fi

echo "***** $log docker image from [$ROOT_DIR/docker/$path]"
echo "with name [$name], label [$label], and tag [$IMAGE_URL]"
docker "$cmd" $flag "$IMAGE_URL" . || { echo "Docker command failed"; exit 1; }

if [ "$push" == true ]; then
    echo "***** Authenticating remote docker repository and pushing [$IMAGE_URL]"
    gcloud auth configure-docker "$REGISTRY_BASE_URL" $quiet
    docker push "$IMAGE_URL"
fi
