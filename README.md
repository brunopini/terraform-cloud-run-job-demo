# Cloud Run Job with Direct VPC Egress provisioning on Google Cloud

## Proof of Concept

This repo was created to serve as a minimal CI/CD boilerplate for your serverless Docker script provision on Google Cloud using Terraform, shell scripts and Github Workflows. After the past year struggling to learn all tools and languages involved, I felt like sharing in case anyone sees value.

Template consists of:

- An [automatic deployment and destruction module](./bin) called from `./terraform/environments/staging/build.sh` and `./terraform/environments/staging/destroy.sh`.
- A [Terraform module](./terraform/) with a directory approach to environments, and two stages of provisioning: [base](./terraform/environments/staging/base/) and [main](./terraform/environments/staging/) infrastructures.
  - Uses the new `google_cloud_run_v2_job` resource, and the Direct VPC Egress (new recommended practice replacing prior VPC Access Connector).
  - Uses cloud naming conventions described by [stepan.wtf](https://stepan.wtf/cloud-naming-convention/#:~:text=The%20rule%20of%20thumb%20is,or%20within%20a%20given%20scope.), but all can be customized.
  - On first local build, sets up Github Actions environment, accessing Actions Secrets via a custom [Terraform module](./terraform/modules/github/) and passing values from a dedicated Google Service Account.
- A [Docker module](./docker) with a [demo Python script](./docker/demo-image/) ready to be dockerized. This script once deployed serves as the proof of success of correct deployment.
  - It pulls from a docker image deployed to Artifact Registry, asserting the success of the Docker build and push; and of the provisioning of Google's Docker repository;
  - It then requests from [https://httpbin.org/get](https://httpbin.org/get) and prints the response, asserting the success of the VPC and Direct VPC Egress provison;
  - And fetches a JSON key from a Service Account created during deployment, via Google Secrets Manager, asserting the success of these services.
  - Finally, its successful scheduling and consistent execution asserts the success of the Cloud Run Job, Scheduler and Service Accounts involved.

## Tree

``` @bash
.
├── .secrets
│   ├── dem-prj-s-gsa-g-terraform.json
│   └── github.env
├── LICENSE
├── README.md
├── bin
│   ├── _gcloud.sh
│   ├── _github_env.sh
│   ├── _read_project_id.sh
│   ├── docker.sh
│   ├── tf_base.sh
│   └── tf_main.sh
├── docker
│   └── demo-image
│       ├── Dockerfile
│       ├── demo.py
│       └── requirements.txt
└── terraform
    ├── environments
    │   └── staging
    │       ├── base
    │       │   ├── apis.tf
    │       │   ├── locals.tf
    │       │   ├── main.tf
    │       │   ├── outputs.tf
    │       │   ├── providers.tf
    │       │   ├── terraform.tfstate
    │       │   ├── terraform.tfvars
    │       │   └── variables.tf
    │       ├── build.sh
    │       ├── destroy.sh
    │       ├── github.tf
    │       ├── locals.tf
    │       ├── main.tf
    │       ├── outputs.tf
    │       ├── providers.tf
    │       ├── terraform.tfvars
    │       ├── variables.tf
    │       └── vpc.tf
    └── modules
        └── github
            ├── actions.tf
            ├── providers.tf
            └── variables.tf
```

## Requirements

- A new Google Cloud Project ID created from this demo.
- A Google Cloud Service Account with Owner Role and its Json file downloaded.
- Gcloud.
- Docker.
- Terraform.
- Github Personal Access Token (optional, for Github Actions setup).

## Config

- You must keep your secrets in the `.secrets` directory.
  - A google service account credentials file is required.
  - A Github Private Access Token is optional (export it as $GITHUB_TOKEN from a `github.env` file):
    - `export GITHUB_TOKEN=github_pat_***`
- In the `build.sh` and `destroy` scripts, fill in the default paths to your Google and Github secrets:
  - `gcreds="${GOOGLE_CREDENTIALS_PATH:-$ROOT_DIR/.secrets/dem-prj-s-gsa-g-terraform.json}"
ghcreds="${GITHUB_CREDENTIALS_PATH:-$ROOT_DIR/.secrets/github.env}"`
- Fill in all variables in both the base and main `terraform.tfvars` files.
  - Resource naming is handled directly in `.tf` files.
- Make sure you understand both `build.sh` and `destroy.sh` scripts before executing. The default variables definition on top can be carefully used to tweak the script's default befaviour. Before reunning, assert and set executable permissions (`chmod +x [script]`).

## Build

All building and provisioning are handled in the `build.sh` script, which consists of three main steps:

- **Base infrastructure**:
  - Enables all (but one) API services needed in the project.
    - One extra necessary API service for the boostrapping (Cloud Resource Manager) is enabled prior to the Terraform init, in one of scripts called by the `build.sh` script.
  - Creates the Cloud Storage bucket to serve as the Terraform backend.
  - Creates the Artifact Registry repository that will host the Docker image.
  - All Terraform code is kept in the dedicated `terraform/environments/staging/base` directory.
  - This stage is intended to only be ran during the first build.
    - Once built, the Artifact Registry repository will be imported into the `main` infrastructure code.
    - Its only remaining responsability after first build is to serve as the Terraform dedicated bucket state local repository - if destroyed, bucket and main state will be destroyed.
- **Docker image build and push**:
  - Builds and tags a local image from `docker/demo-image`.
  - Pushes to the newly created Artifact Registry.
- **Main infrastructure**:
  - Connects to the newly created backend and provisions all other resources, including:
    - Importing the Google Artifact repository from the `base` infrastructure.
    - Networking, including a private subnet, Firewall Rules and a NAT Router for egress.
    - Cloud Run Job with Direct VPC Egress and a Scheduler configured to execute every 10 minutes.
      - You should destroy once validaded, or change Scheduler frequency to avoid getting charged for the demo runs.
    - Internal Service Accounts with correctly assigned IAM Roles:
      - Cloud Run
      - Cloud Scheduler
      - Github Actions
      - Demo external account
    - Both the Github Actions and external account will have a private JSON key file generated.
      - One will be passed to a Google Secret, to be accessed by the demo Docker job, and the other to a Github Actions Secret, which will be used by Github Actions authentication.

### First Build (local)

#### With Github Actions Setup

``` @bash
./terraform/environments/staging/build.sh --from-base --github-actions
```

#### Without Github Actions

``` @bash
./terraform/environments/staging/build.sh --from-base
```

___

### Following Builds

Backend bucket must be passed either via `--assets-bucket [name]` or by exporting `ASSETS_BUCKET`.

> Keep `--github-actions` flag or Github Actions resources will be destroyed.

``` @bash
export ASSETS_BUCKET=[]
./terraform/environments/staging/build.sh [--github-actions]
```

or

``` @bash
./terraform/environments/staging/build.sh --assets-bucket [name] [--github-actions]
```

#### Docker Push

To avoid any Terraform provision.

``` @bash
./terraform/environments/staging/build.sh --docker-only
```

#### Skip Docker

To avoid building and pushing Docker image.

``` @bash
./terraform/environments/staging/build.sh --assets-bucket [name] --skip-docker [--github-actions]
```

___

## Destroy

Similarly to `build.sh`, `destroy.sh` handles the destruction of all provisioned infrastructure, including the locally built Docker image. A `--keep-base` and a `--keep-docker` flag are available for more control on destruction.

Backend bucket must, like with `build.sg`, be passed either via `--assets-bucket [name]` or by exporting `ASSETS_BUCKET`.

### Keeping Base

The `base` Terraform module holds the Terraform state bucket state files. If destroyed, this demo will delete the bucket and all of its content based on the `force_destroy = true` argument passed to the bucket resource. To avoid this destruction, edit the Terraform resource by removing the `forece_destroy` argument or pass the `--keep-base` flag to `destroy.sh`:

``` @bash
./terraform/environments/staging/destroy.sh --assets-bucket [name] --keep-base
```

### Keeping Local Docker Images

By default, the this demo will destroy everything it once provisioned - this includes the locally built Docker image. To avoid removing the images during destruction, pass the `--keep-docker` flag to `destroy.sh`.

``` @bash
./terraform/environments/staging/destroy.sh--assets-bucket [name] --keep-docker
```

These two flags can be combined:

``` @bash
./terraform/environments/staging/destroy.sh --assets-bucket [name] --keep-docker --keep-base
```

After destruction is complete, you will still need to delete the Google Service Account you created for this demo, and diable the Service Usage API manually.

## Github Actions

Three Github Actions workflows are created:

- `all.yml` - [Build and deploy all](.github/workflows/all.yml)
  - Triggered only manually via actions console.
- `docker.yml` - [Build and deploy Docker](.github/workflows/docker.yml)
  - Triggered by pushes to `main` branch on `docker/` paths.
- `gcloud.yml` - [Build and deploy Google Cloud](.github/workflows/gcloud.yml)
  - Triggered by pushes to `main` branch on `terraform/` paths, except for `base/` files (since base state is handled locally).

## What's next

- [x] Adding a `destroy.sh` process.
- [x] Improving `build.sh` and `destroy.sh` processes.
- [x] Adding a Secrets Manager environment to the Cloud Run container.
- [x] Creating Github Workflows for CI/CD.
- [x] Expand and modularize Github Worflows.
- [ ] Adding unit tests and other validations.
- [ ] Adding a Cloud Storage connection.
- [ ] Adding a Cloud Run Service with a public IP.
- [ ] Adding VPC Peering functionality.
- [ ] Tagging across all resources created.
- [ ] Separating terraform resources into modules.
- [ ] Equivalent structure with AWS ECS.

Feel free to collaborate!
