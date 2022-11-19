module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.17.0"

  cluster_name    = local.name
  cluster_version = "1.24"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  map_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Admin"
      username = "Admin"
      groups   = ["system:masters"]
    }
  ]

  managed_node_groups = local.managed_node_groups

  tags = local.tags
}

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.17.0"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  # EKS Managed Add-ons
  enable_amazon_eks_vpc_cni                      = true
  enable_amazon_eks_kube_proxy                   = true
  enable_amazon_eks_aws_ebs_csi_driver           = false
  enable_amazon_eks_coredns                      = true
  enable_coredns_cluster_proportional_autoscaler = false

  # Add-ons
  enable_cluster_autoscaler           = true
  enable_reloader                     = false
  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true
  enable_aws_cloudwatch_metrics       = false
  enable_prometheus                   = false

  enable_argocd         = false
  argocd_manage_add_ons = false
  argocd_helm_config    = local.argocd_helm_config

  enable_crossplane       = false
  crossplane_helm_config  = local.crossplane_helm_config
  crossplane_aws_provider = local.crossplane_aws_provider_config

  tags = local.tags
}

module "eks_blueprints_ack_addons" {
  source = "aws-ia/eks-ack-addons/aws"

  cluster_id = module.eks_blueprints.eks_cluster_id
  # Wait for data plane to be ready
  data_plane_wait_arn = module.eks_blueprints.managed_node_group_arn[0]

  enable_api_gatewayv2 = false
  enable_dynamodb      = false
  enable_s3            = false
  enable_rds           = false
  enable_amp           = false

  tags = local.tags
}
