#!/bin/bash

tfvars_file="${ROOT_DIR}/terraform/environments/${ENV_PATH}/base/terraform.tfvars"

project_id=""

# Read each line of the .tfvars file
while IFS=' =' read -r key value
do
  if [ "$key" = "project_id" ]; then
    # Trim quotes and remove any potential trailing characters
    project_id=$(echo "$value" | tr -d '"' | tr -d '\r')
    break # Once the key is found, no need to continue the loop
  fi
done < "$tfvars_file"

export PROJECT_ID=$project_id
