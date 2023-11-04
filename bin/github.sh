#!/bin/bash

# Temporarily save the service account key to a file
echo -n "$SERVICE_ACCOUNT_KEY_FILE" > .secrets/temp_key_file.json

# Use the GitHub CLI to set the secret in your repository
gh secret set GCP_SA_KEY < ./temp_key_file.json --repo "$REPO"

# Remove the temporary key file
rm ./temp_key_file.json
