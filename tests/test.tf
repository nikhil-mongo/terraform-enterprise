provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

/*module "vaultprovider" {
  source          = "clo-tfe-prod.prci.com/eds/vaultprovider/aws"
  version         = "~> 2.0"
  acc_id_vault    = var.acc_id_vault
  acc_short_alias = var.acc_short_alias
}*/

provider "mongodbatlas" {
  public_key  = var.mongo_public_key
  private_key = var.mongo_private_key
}

locals {
  map_tags = {
    "application"    = "mongodb-module-test"
    "environment"    = "dev"
    "region"         = "us-east-1"
    "business_group" = "eds"
    "platform"       = "eds"
    "domain"         = "eds"
    "cost_center"    = "12345"
    "iac_tool"       = "terraform"
    "compliance"     = "standard"
  }
}

module "testMongoDBModule" {
  source                        = "../"
  acc_short_alias               = "aws82l"
  str_platform                  = "eds"
  str_application               = "andrew"
  mongodb_org_id                = "5c98a80fc56c98ef210b8633"
  map_maint_window              = {
    day_of_week = 1
    hour_of_day = 0
  }
  vpc_id                        = ""
  vpc_cidr_block                = []
  subnet_ids                    = []
  # provider_name               = "AWS"
  # privatelink_endpoint_region = "us-east-1"
  # vpce_id                     = ""
  # using_aws_openshift         = false
  key_arn                       = ""
  map_tags                      = local.map_tags
  # mongo_public_key            = var.mongo_public_key
  # mongo_private_key           = var.mongo_private_key
  # encryption_region             = "US_EAST_1"
}

resource "mongodbatlas_cluster" "cluster-test" {
  project_id   = module.testMongoDBModule.project_id
  name         = "aws-mongo"
  cluster_type = "REPLICASET"
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = "US_EAST_1"
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }
  provider_backup_enabled      = true
#   cloud_backup = true
  auto_scaling_disk_gb_enabled = true
  mongo_db_major_version       = "4.4"
  encryption_at_rest_provider = "AWS"

  //Provider Settings "block"
  provider_name               = "AWS"
  disk_size_gb                = 10
  provider_instance_size_name = "M10"
  depends_on                  = [module.testMongoDBModule]
}