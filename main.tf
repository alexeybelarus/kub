# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket         = "jancker84"
    key            = "d.tfstate"
    region         = "us-east-1"
    dynamodb_table = "stax"
  }
}


data "aws_availability_zones" "available" {}

locals {
  cluster_name = "a-khursevich-eks"

}



resource "aws_ecr_repository" "aecr" {
  name = "repo/aecr"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20"

  cluster_name    = local.cluster_name
  cluster_version = "1.30"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "khursevich-node-group"

      instance_types = ["t2.small"]

      min_size     = 2
      max_size     = 2
      desired_size = 2
    }
  }
}


# # https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
# data "aws_iam_policy" "ebs_csi_policy" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }

# module "irsa-ebs-csi" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version = "4.7.0"

#   create_role                   = true
#   role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
#   provider_url                  = module.eks.oidc_provider
#   role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
# }

# resource "aws_eks_addon" "ebs-csi" {
#   cluster_name             = module.eks.cluster_name
#   addon_name               = "aws-ebs-csi-driver"
#   addon_version            = "v1.20.0-eksbuild.1"
#   service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
#   tags = {
#     "eks_addon" = "ebs-csi"
#     "terraform" = "true"
#   }
# }
