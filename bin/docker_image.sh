#!/bin/bash

cmd=""
path=""
name=""
label="latest"
push=0
quiet=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -docker|--docker) cmd="$2"; shift 2;;
        -image-path|--image-path) path="$2"; shift 2;;
        -image|--image-name) name="$2"; shift 2;;
        -label|--label) label="$2"; shift 2;;
        -push|--push) push=1; shift 2;;
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

echo "***** Exporting IMAGE_URL"
cd "${ROOT_DIR}/${path}" || { echo "Cannot cd into ${ROOT_DIR}/${path}"; exit 1; }
export IMAGE_URL="$REPOSITORY_BASE_URL/$PROJECT_ID/$REPOSITORY_ID/$name:$label"

echo "***** $log docker image from[$ROOT_DIR/$path]"
echo "with name [$name], label [$label], and tag [$IMAGE_URL]"
docker "$cmd" $flag "$IMAGE_URL" . || { echo "Docker command failed"; exit 1; }

if [ "$push" == 1 ]; then
    echo "***** Authenticating remote docker repository and pushing [$IMAGE_URL]"
    gcloud auth configure-docker "$REPOSITORY_BASE_URL" $quiet
    docker push "$IMAGE_URL"
fi

echo ""
