# Cloud Run Job with Direct VPC Egress provisioning on Google Cloud

## Proof of Concept

This repo was created to serve as a minimal Terraform, Docker and CI/CD boilerplate / template to your serverless cloud solution. After the past year struggling to learn all tools and languages involved, I felt like sharing in case anyone sees value.

Template consists of:

- An [automatic deployment and destruction module](./bin) called from `./terraform/environments/staging/build.sh` and `./terraform/environments/staging/destroy.sh`.
- A [Terraform module](./terraform/) with a directory approach to environments, and two stages of provisioning: bootstrap and main infrastructure.
  - Uses the new `google_cloud_run_v2_job` resource, and the Direct VPC Egress (new recommended practice replacing prior VPC Access Connector)
  - Uses cloud naming conventions described by [stepan.wtf](https://stepan.wtf/cloud-naming-convention/#:~:text=The%20rule%20of%20thumb%20is,or%20within%20a%20given%20scope.), but all can be customized.
- A [code module](./code/) with a [demo Python script](./code/demo-image/) ready to be dockerized. This script once deployed serves the proof of success of deployment.
  - It pulls from a docker image deployed to Artifact Registry, asserting the success of the Docker build and push; and of the deployment of Google's image repository;
  - It then requests from [https://httpbin.org/get](https://httpbin.org/get) and prints the response, asserting the success of the VPC and Direct VPC Egress deployment;
  - And fetches a JSON key from a Service Account created during deployment, via Google Secrets Manager, asserting the success of these services.
  - Finally, it's successful scheduling and consistent execution asserts the success of the Cloud Run Job, Scheduler and Service Accounts involved.

All building and provisioning are handled in the `build.sh` script, which consists of three main steps:

- **Bootstrap infrastructure**:
  - Enables all (but one) API services needed in the project.
    - One extra necessary API service for the boostrapping (Cloud Resource Manager) is enabled prior to the Terraform init, in one of scripts balled by the `build.sh` script.
  - Creates the Cloud Storage bucket to serve as the Terraform backend.
  - Creates the Artifact Registry repository that will host the Docker image.
  - All Terraform code is kept in the dedicated `terraform/environments/staging/bootstrap` directory.
- **Docker image build and push**:
  - Builds and tags a local image from `code/demo-image`..
  - Pushes to newly created Artifact Registry.
- **Main infrastructure**:
  - Connects to the newly created backend and provisions all other resources, including:
    - Networking, including Firewall Rules and a NAT Router.
    - Cloud Run Job with Direct VPC Egress and a Scheduler configured to execute every 2 minutes.
      - You should destroy once validaded, or change Scheduler frequency to avoid getting charged for the tests.
    - Internal Service Accounts with assigned IAM Roles.
    - An external Service Account and a private JSON key file.
    - A Secrets Manager secret with the above JSON key passed to the Cloud Run Job as a container environment variable.

## Tree

``` @bash
.
├── .secrets
│   └── dem-prj-s-gsa-g-terraform.json
├── bin
│   ├── build_docker_image.sh
│   ├── disable_gcloud_cli.sh
│   ├── docker_image.sh
│   ├── enable_gcloud_cli.sh
│   ├── set_bootstrap_variables.sh
│   ├── set_env.sh
│   ├── set_service_account_credentials.sh
│   ├── terraform_bootstrap.sh
│   └── terraform_main.sh
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
            ├── destroy.sh
            ├── locals.tf
            ├── main.tf
            ├── providers.tf
            ├── terraform.tfvars
            ├── variables.tf
            └── vpc.tf
```

## Requirements

- gcloud
- Docker
- Terraform

## Config

1. You must place your service account credentials file in the `.serets` directory - name it something better than the default file.
2. In the `build.sh` script, follow commented instructions.
3. Setup both Terraform repositories in `terraform/environments/staging/`, using all four `variables.tf` and `terraform.tfvars` files (naming conventions are constructed directly in the `main.tf` and `vpc.tf` files).
4. Make sure you understand both `build.sh` and `destroy.sh` scripts before executing. Not a lot of changes are needed there, except for asserting executable permissions (`chmod +x [script]`).

## Building

Execute `./build.sh` from `terraform/environments/staging` and wait for the logs to complete.

## Destroying

Similarly to `build.sh`, `destroy.sh` handles the destruction of all provisioned infrastructure, including the locally built Docker image.

The Terraform code sets all dependencies provisioned by this repo so that destruction runs smoothly, but be careful of external dependencies that might arrise from expanding the infrastructure. The destruction of the VPC and Subnet is the most susceptible to raise errors, in which case you will need to find any resources using it and manually delete them, be on the lookout for possible errors.

After the destruction is complete, you will still need to delete the original Cloud Storage Terraform State Bucket and diable the Service Usage API manually - you will likely see an error.

> If destruction fails at any point (and bootstrap infrastructure is destroyed, regardless of the success level), you might need to re-build all infrastructure before attemplting to retry destruction, because APIs needed might have been successfully disabled. This should no longer happen as frequently after improvements made.

## What's next

- [x] Adding a `destroy.sh` process.
- [x] Improving `build.sh` and `destroy.sh` processes.
- [x] Adding a Secrets Manager environment to the Cloud Run container.
- [x] Creating Github Workflows for CI/CD.
- [ ] Expand and modularize Github Worflows.
- [ ] Adding a Cloud Storage connection.
- [ ] Adding a Cloud Run Service with a public IP.
- [ ] Adding VPC Peering functionality.
- [ ] Tagging across all resources created.
- [ ] Separating terraform resources into modules.
- [ ] Equivalent structure with AWS ECS.

Feel free to collaborate!
