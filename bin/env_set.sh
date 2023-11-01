#!/bin/bash

env=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -environment|--environment) env="$2"; shift 2;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

# ./_root_dir.sh

echo "***** Exporting ENV_PATH as [$env]"
export ENV_PATH="${env}"

echo ""
