# Cloud Run Job with Direct VPC Egress provisioning on Google Cloud

Provision of a Cloud Run Job pulling from a Docker image hosted in Artifact Registry with the new Direct VPC Egress mode in Google Cloud Platform.

You must have a Google Cloud project ready, with an active billing account linked, the Service Usage API enabled, and a service account with the Owner role (and its valid credentials.json file in hands).

This repo follows the cloud naming conventions described at [stepan.wtf](https://stepan.wtf/cloud-naming-convention/#:~:text=The%20rule%20of%20thumb%20is,or%20within%20a%20given%20scope.), but all can be customized.

For illustration purposes, a demo Python script is dockerized and pushed to the GCP project. Its sole purpose is to create a GET request to [https://httpbin.org/get](https://httpbin.org/get) and print the response.

All building and provisioning are handled in the `build.sh` script.

This took a little effort to find the right documentations (and sometimes infer by trial and error the correct IAC setup) of both the new `google_cloud_run_v2_job` resource and the Direct VPC Egress (new recommended practice replacing prior VPC Access Connector) - hopefully someone can find this usefull!

The complete build process is separated into 3 steps:

- **Bootstrap infrastructure**:
  - Enables all (but one) API services needed in the project.
    - One extra necessary API service for the boostrapping (Cloud Resource Manager) is enabled prior to the Terraform init, in the `build.sh` script.
  - Creates the Cloud Storage bucket to serve as the Terraform backend.
  - Creates the Artifact Registry repository that will host the Docker image.
  - All Terraform code is kept in the dedicated `terraform/environments/staging/bootstrap` directory.
- **Docker image build and push**:
  - Builds and tags a local image from `code/demo-image`.
    - The image name inherits the working directory name (as is: `demo-image`).
  - Pushes to newly created Artifact Registry.
- **Main infrastructure**:
  - Connects to the newly created backend and provisions all other resources, including:
    - Networking, including Firewall Rules and a NAT Router.
    - Cloud Run Job and Scheduler.
    - Service Accounts and assigns IAM Roles.

## Tree

``` @bash
.
├── .secrets
│   └── dem-prj-s-gsa-g-terraform.json
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
3. Setup both Terraform repositories in `terraform/environments/staging/`, using all four `variables.tf` and `terraform.tfvars` files (naming conventions are constructed directly in the `main.tf` files).
4. Make sure you understand the `build.sh` script before executing. No extra changes are needed there, except for assuring executable permissions (use `chmod +x build.sh`).

## Building

Execute `./build.sh` from `terraform/environments/staging` and wait for the logs to complete.

## Destroying

Similarly to `build.sh`, `destroy.sh` handles the destruction of all provisioned infrastructure, including the locally built Docker image.

The Terraform code sets all dependencies provisioned by this repo so that destruction runs smoothly, but be careful of external dependencies that might arrise from expanding the infrastructure. The destruction of the VPC and Subnet is the most susceptible to raise errors, in which case you will need to find any resources using it and manually delete them.

After the destruction is complete, you will still need to delete the original Cloud Storage Terraform State Bucket and diable the Service Usage API manually.

> If destruction fails at any point (and bootstrap infrastructure is destroyed sucessfully), you will need to re-build all infrastructure before attemplting to retry destruction, because APIs needed might have been successfully disabled.

## What's next

- [x] Adding a `destroy.sh` process.
- [ ] Improving `destroy.sh` process.
- [ ] Adding a Secrets Manager environment to the Cloud Run container.
- [ ] Adding a Cloud Storage connection.
- [ ] Adding VPC Peering functionality.
- [ ] Tagging across all resources created.
- [ ] Separate terraform resources into modules.
- [ ] Create GitHub Workflows for CI/CD.
- [ ] Equivalent structure with AWS ECS.

Feel free to create issues for more improvement ideas!
