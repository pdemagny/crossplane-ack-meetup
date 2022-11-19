locals {
  name   = basename(path.cwd)
  region = "eu-west-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  managed_node_groups = {
    spot_t3 = {
      node_group_name = "spot-od-t3-medium"
      instance_types  = ["t3.medium"]
      capacity_type   = "SPOT"
      desired_size    = 2
      max_size        = 3
      min_size        = 1
      subnet_ids      = module.vpc.private_subnets
    }
  }

  tags = {
    blueprint  = local.name
    repository = "github.com/pdemagny/crossplane-ack-meetup"
  }

  argocd_helm_config = {
    values = [templatefile("${path.root}/files/argocd/argocd-values.yaml", {})]
  }

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
}
