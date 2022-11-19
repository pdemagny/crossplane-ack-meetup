# crossplane-ack-meetup

## disclaimer

This repository is a testing playground I created for my demonstration for [this meetup event](https://www.meetup.com/fr-FR/latoulboxducloudnatif/events/289395782/).  
**You should not be using it for any kind of production related work.**

This is still a work in progress !

This playground stands on the shoulders of these giants:

- [terraform-aws-eks-blueprints](https://github.com/aws-ia/terraform-aws-eks-blueprints)
- [terraform-aws-eks-ack-addons](https://github.com/aws-ia/terraform-aws-eks-ack-addons)
- [crossplane-on-eks](https://github.com/awslabs/crossplane-on-eks) (formally known as `crossplane-aws-blueprints`).
- [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
- And so much more ...

## prerequisites

- An AWS account and an [IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html), with an [Access Key & Secret Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html), that has enough permissions (i.e. using the [`AdministratorAccess`](https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn:aws:iam::aws:policy/AdministratorAccess$jsonEditor) policy).
- [A working installation of the AWSCLI](https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/getting-started-install.html) with the Access Key & Secret Key configured (i.e with [`aws configure`](https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/getting-started-quickstart.html)).
- An account on [Terraform Cloud](https://app.terraform.io/app) (or just a workspace if you already have an account, or do whatever modifications are required to work with your specific setup if you don't use Terraform Cloud).  
  I would recommend setting the Execution mode to "local" in your workspace.  
  This way you get a remote state backend for free without the hassle of creating and maintaining a bootstrap bucket, and you still preserve the original Terraform oss cli workflow.  
- A [Docker Hub](https://hub.docker.com/) account, if you plan on testing Crossplane's Packaging capabilities.
- If you are using [`asdf-vm`](https://asdf-vm.com/), just run `asdf install`.  
  If you are not, then:
  - You should definitely consider using it ;)
  - Install the tools & versions listed in `.tool-versions` on your own.

/!\ **NOTE**: use terraform 1.3.3 to avoid [this issue when using 1.3.4+](https://github.com/aws-ia/terraform-aws-eks-blueprints/issues/1161).

## setup

- Create a new file called `tfc.tf` containing the following (make sure to replace placeholders):

  ```hcl
  terraform {
    cloud {
      organization = "<YOUR_TERRAFORM_CLOUD_ORGANIZATION>"
      workspaces {
        name = "<YOUR_TERRAFORM_CLOUD_WORKSPACE>"
      }
    }
  }
  ```

- Then provision this playground:

  ```bash
  # Init
  ❯ terraform init
  # Plan
  ❯ terraform plan -out=plans/out.plan
  # Apply
  ❯ terraform apply plans/out.plan

  # If you have other clusters in your kube config, run
  ❯ $(terraform output --raw configure_kubectl)
  # Or if you don't have any other clusters in your kube config, run:
  ❯ sed -i 's/: null/: []/g' ~/.kube/config && $(terraform output --raw configure_kubectl)

  # You should be able to see all pods with:
  ❯ kubectl get pods -A
  ```

## usage

### AWS Controllers for Kubernetes

#### Controllers

- Enable the controllers you'd like from the list of controllers supported by the [terraform-aws-eks-ack-addons](https://github.com/aws-ia/terraform-aws-eks-ack-addons) project in the `main.tf` file, for example:

  ```hcl
  module "eks_blueprints_ack_addons" {
    source = "aws-ia/eks-ack-addons/aws"

    cluster_id = module.eks_blueprints.eks_cluster_id
    # Wait for data plane to be ready
    data_plane_wait_arn = module.eks_blueprints.managed_node_group_arn[0]

    enable_api_gatewayv2 = false
    enable_dynamodb      = false
    enable_s3            = true
    enable_rds           = true
    enable_amp           = true

    tags = local.tags
  }
  ```

- Then Plan/Apply those changes, if any:

  ```bash
  # Plan
  ❯ terraform plan -out=plans/out.plan
  # Apply
  ❯ terraform apply plans/out.plan
  ```

#### Resources

See examples of managing cloud resources with ACK in the [`examples/ack/`](examples/ack/) directory.

### Crossplane

#### Configure iRSA

- Adjust versions and Policies in the `locals.tf` file, for example:

  ```hcl
    crossplane_helm_config = {
      name       = "crossplane"
      chart      = "crossplane"
      repository = "https://charts.crossplane.io/stable/"
      version    = "1.10.1"
      namespace  = "crossplane-system"
    }
    crossplane_aws_provider_config = {
      enable                   = true
      provider_aws_version     = "v0.33.0"
      additional_irsa_policies = ["arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AmazonSQSFullAccess", "arn:aws:iam::aws:policy/AmazonRDSFullAccess", "arn:aws:iam::aws:policy/AmazonVPCFullAccess"]
    }
  ```

- Set the `enable_crossplane` to `true` in the `main.tf` file.

- Then Plan/Apply those changes, if any:

  ```bash
  # Plan
  ❯ terraform plan -out=plans/out.plan
  # Apply
  ❯ terraform apply plans/out.plan
  ```

#### Managed Resources

See examples of managing Cloud Resources with Crossplane in the [`examples/crossplane/1-resources/`](examples/crossplane/1-resources/) directory.

#### Compositions

See examples of managing Composed Cloud Resources with Crossplane in the [`examples/crossplane/2-compositions/`](examples/crossplane/2-compositions/) directory.

#### Packages

See examples of creating and distributing Packaged Compositions of Cloud Resources with Crossplane in the [`examples/crossplane/3-packages/`](examples/crossplane/3-packages/) directory.

### ArgoCD

#### Installation

- If its not already enabled, enable the ArgoCD add-on from the EKS Blueprint

  ```hcl
  module "eks_blueprints_kubernetes_addons" {
    source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.17.0"
    ...
    enable_argocd         = true
    ...
  }
  ```

- Then Plan/Apply those changes, if any:

  ```bash
  # Plan
  ❯ terraform plan -out=plans/out.plan
  # Apply
  ❯ terraform apply plans/out.plan
  ```

- Once ArgoCD is installed, get the default ArgoCD admin password

  ```bash
  ❯ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

- Use k9s to create a port-forward to access the ArgoCD UI (recommended), or create a port-forward with kubectl

  ```bash
  ❯ ARGOCD_SERVER_POD=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server --no-headers -o jsonpath="{.items[].metadata.name}")
  ❯ kubectl port-forward -n argocd "pods/${ARGOCD_SERVER_POD}" 8080:8080 &
  ```

- Login with the CLI

  ```bash
  ❯ argocd login localhost:8080 --insecure
  ```

#### Usage

See examples of declaratively deploy everything in the [`examples/argocd/`](examples/argocd/) directory.

## destroy

To destroy this playground:

```bash
# First of all, delete all ArgoCD apps deployed either from the ArgoCD CLI or UI
❯ argocd app delete argocd/crossplane-ack-meetup
# Then, delete all infrastructure
❯ terraform destroy -target="module.eks_blueprints_ack_addons" -auto-approve
❯ terraform destroy -target="module.eks_blueprints_kubernetes_addons" -auto-approve
❯ terraform destroy -target="module.eks_blueprints" -auto-approve
❯ terraform destroy -auto-approve
```
