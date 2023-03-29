# --------------------------------------------------------------------------
#
# Copyright 2023-Present Sonatype Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# --------------------------------------------------------------------------

################################################################################
# Load Vendor Corp Shared Infra
################################################################################
module "shared" {
  source                   = "git::ssh://git@github.com/vendorcorp/terraform-shared-infrastructure.git?ref=v0.3.2"
  environment              = var.environment
  default_eks_cluster_name = "vendorcorp-us-east-2-63pl3dng"
}

################################################################################
# PostgreSQL Provider
################################################################################
provider "postgresql" {
  scheme          = "awspostgres"
  host            = module.shared.pgsql_cluster_endpoint_write
  port            = module.shared.pgsql_cluster_port
  database        = "postgres"
  username        = module.shared.pgsql_cluster_master_username
  password        = var.pgsql_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}

################################################################################
# Connect to our k8s Cluster
################################################################################
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = module.shared.eks_cluster_arn
}

################################################################################
# Create NXIQ HA Cluster
################################################################################
module "nxiq_ha_cluster" {
  source = "git::ssh://git@github.com/vendorcorp/terraform-aws-eks-nxiq.git?ref=v0.1.0"

  default_resource_tags = var.default_resource_tags
  nxiq_name             = terraform.workspace
  nxiq_license_file     = "${path.module}/sonatype-license.lic"
  nxiq_version          = "1.158.0"
  pg_hostname           = module.shared.pgsql_cluster_endpoint_write
  pg_port               = module.shared.pgsql_cluster_port
  pg_admin_username     = module.shared.pgsql_cluster_master_username
  pg_admin_password     = var.pgsql_password
  replica_count         = 2
}

################################################################################
# Create Ingress for NXIQ
################################################################################
resource "kubernetes_ingress_v1" "nxiq-ha" {
  metadata {
    name      = "nxiq-ha-ingress"
    namespace = module.nxiq_ha_cluster.nxiq_ha_k8s_namespace
    labels = {
      app = "nxiq-ha"
    }
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/group.name"      = "vencorcorp-shared-core"
      "alb.ingress.kubernetes.io/scheme"          = "internal"
      "alb.ingress.kubernetes.io/certificate-arn" = module.shared.vendorcorp_net_cert_arn
    }
  }

  spec {
    rule {
      host = "iq-${terraform.workspace}.corp.${module.shared.dns_zone_public_name}"
      http {
        path {
          path = "/*"
          backend {
            service {
              name = module.nxiq_ha_cluster.nxiq_ha_k8s_service_name
              port {
                number = 8070
              }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true
}

resource "kubernetes_ingress_v1" "nxiq-ha-admin" {
  metadata {
    name      = "nxiq-ha-admin-ingress"
    namespace = module.nxiq_ha_cluster.nxiq_ha_k8s_namespace
    labels = {
      app = "nxiq-ha"
    }
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/group.name"      = "vencorcorp-shared-core"
      "alb.ingress.kubernetes.io/scheme"          = "internal"
      "alb.ingress.kubernetes.io/certificate-arn" = module.shared.vendorcorp_net_cert_arn
    }
  }

  spec {
    rule {
      host = "iq-admin-${terraform.workspace}.corp.${module.shared.dns_zone_public_name}"
      http {
        path {
          path = "/*"
          backend {
            service {
              name = module.nxiq_ha_cluster.nxiq_ha_k8s_admin_service_name
              port {
                number = 8071
              }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true
}

################################################################################
# Add/Update DNS for Load Balancer Ingress
################################################################################
resource "aws_route53_record" "nxiq_dns" {
  zone_id = module.shared.dns_zone_public_id
  name    = "iq-${terraform.workspace}.corp"
  type    = "CNAME"
  ttl     = "300"
  records = [
    kubernetes_ingress_v1.nxiq-ha.status.0.load_balancer.0.ingress.0.hostname
  ]
}

resource "aws_route53_record" "nxiq_admin_dns" {
  zone_id = module.shared.dns_zone_public_id
  name    = "iq-admin-${terraform.workspace}.corp"
  type    = "CNAME"
  ttl     = "300"
  records = [
    kubernetes_ingress_v1.nxiq-ha-admin.status.0.load_balancer.0.ingress.0.hostname
  ]
}
