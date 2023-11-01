#!/bin/bash

tf=""
auto=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -tf|--terraform) tf="$2"; shift 2;;
        -auto|--auto-approve) auto="--auto-approve"; shift 1;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

cd "${ROOT_DIR}/terraform/environments/${ENV_PATH}/bootstrap" || { echo "Cannot cd into ${ROOT_DIR}/${path}"; exit 1; }

echo "***** Building ${ENV_PATH} boostrap infrastructure"
terraform "$tf" $auto

echo ""
