# Cloud Run Job with Direct VPC Egress provisioning on Google Cloud

Provision of a Cloud Run Job pulling from a Docker image hosted in Artifact Registry with the new Direct VPC Egress mode in Google Cloud Platform.

You must have a Google Cloud project ready, with an active billing account linked, the Service Usage API enabled, and a service account with the Owner role (and its valid credentials.json file in hands).

This repo follows the cloud naming conventions described at [stepan.wtf](https://stepan.wtf/cloud-naming-convention/#:~:text=The%20rule%20of%20thumb%20is,or%20within%20a%20given%20scope.), but all can be customized.

For illustration purposes, a demo Python script is dockerized and pushed to the GCP project. Its sole purpose is to create a GET request to [https://httpbin.org/get](https://httpbin.org/get) and print the response.

All building and provisioning are handled in the `build.sh` script.

This took a little effort to find the right documentations (and sometimes infer by trial and error the correct IAC setup) of both the new `google_cloud_run_v2_job` resource and the Direct VPC Egress (new recommended practice replacing prior VPC Access Connector) - hopefully someone can find this usefull!

The complete build process is separated into 2 steps:

- Bootstrap infrastructure:
  - Enables all (but one) API services needed in the project.
    - One extra necessary API service for the boostrapping (Cloud Resource Manager) is enabled prior to the terraform init, in the `build.sh` script.
  - Creates the Cloud Storage bucket to serve as the terraform backend.
  - Creates the Artifact Registry repository that will host the Docker image.
  - All terrafom code is kept in the dedicated `terraform/environments/staging/bootstrap` directory.
- Main infrastructure:
  - Connects to the newly created backend and provisions all other resources, including:
    - Networking, including Firewall Rules and a NAT Router.
    - Cloud Run Job and Scheduler.
    - Service Accounts and assigns IAM Roles.
   
## Tree

```
.
├── .secrets
│   └── dem-prj-s-gsa-g-terraform.json
├── LICENSE
├── README.md
├── code
│   └── demo-image
│       ├── Dockerfile
│       ├── demo.py
│       └── requirements.txt
└── terraform
    └── environments
        └── staging
            ├── bootstrap
            │   ├── apis.tf
            │   ├── main.tf
            │   ├── outputs.tf
            │   ├── providers.tf
            │   ├── terraform.tfvars
            │   └── variables.tf
            ├── build.sh
            ├── main.tf
            ├── providers.tf
            ├── terraform.tfvars
            └── variables.tf
```
   
## Requirements
- gcloud
- Docker
- Terraform

## Config

1. You must place your service account credentials file in the `.serets` directory - name it something better than the default file.
2. In the `build.sh` script, replace the placeholder name of with your file name: `GOOGLE_APPLICATION_CREDENTIALS=".secrets/dem-prj-s-gsa-g-terraform.json"`
3. Setup both terraform repositories in `terraform/environments/staging/`, using all four `variables.tf` and `terraform.tfvars` files (naming conventions are constructed directly in the `main.tf` files).
4. Make sure you understand the `build.sh` script before executing. No extra changes are needed there, except for assuring executable permissions (use `chmod +x build.sh`).
5. Execute `./build.sh` from `terraform/environments/staging` and wait for the logs to complete.

## What's next

- Adding a Secrets Manager environment to the Cloud Run container.
- Adding VPC Peering functionality.
- Tagging accross all resources created.
- Separate terraform resources into modules.
- Create GitHub Workflows for CI/CD.

Feel free to create issues for more improvement ideas!
