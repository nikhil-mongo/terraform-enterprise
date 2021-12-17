# Creates MongoDB Project
resource "mongodbatlas_project" "mongo_project" {
  name   = "${var.acc_short_alias}-${var.str_platform}-${var.str_application}"
  org_id = var.mongodb_org_id

  lifecycle {
    ignore_changes = [
      teams # teams access is managed manually through Atlas console
    ]
  }
}

# Creates IP Access List Entries for DBAs
/*resource "mongodbatlas_project_ip_access_list" "progressive_1" {
  project_id = mongodbatlas_project.mongo_project.id
  cidr_block = ""
  comment    = ""
}

# Creates IP Access List Entries for DBAs
resource "mongodbatlas_project_ip_access_list" "progressive_2" {
  project_id = mongodbatlas_project.mongo_project.id
  cidr_block = ""
  comment    = ""
}*/

# Enables Database Auditing per Security Standards
# resource "mongodbatlas_auditing" "auditing" {
#   project_id                  = mongodbatlas_project.mongo_project.id
#   audit_filter                = "{ '$or': [ { '$and': [ { 'users.user': { '$not': { '$regex': '^arn.*', '$options': 'i' } }, '$or': [ { '$and': [ { 'param.command': { '$nin': [ 'isMaster', 'getMore' ] } }, { 'param.mechanism': { '$nin': [ 'SCRAM-SHA-1', 'MONGODB-X509' ] } }, { 'param.ns': { '$nin': [ 'local.oplog.rs', 'local.system.replset', 'local.clustermanager', 'config.system.sessions', 'config.settings' ] } }, { '$and': [ { 'param.command': { '$ne': 'find' } }, { 'param.ns': { '$ne': 'admin.system.roles' } } ] }, { 'users': { '$elemMatch': { '$or': [ { 'db': 'admin' }, { 'db': '$external' }, { 'db': 'local' } ] } } } ] }, { 'roles': { '$elemMatch': { '$or': [ { 'db': 'admin' } ] } } } ] }, { '$or': [ { 'atype': 'authCheck', 'param.command': { '$in': [ 'aggregate', 'count', 'distinct', 'group', 'mapReduce', 'geoNear', 'geoSearch', 'eval', 'find', 'getLastError', 'getMore', 'getPrevError', 'parallelCollectionScan', 'delete', 'findAndModify', 'insert', 'update', 'resetError' ] } }, { 'atype': { '$in': [ 'authenticate', 'createCollection', 'createDatabase', 'createIndex', 'renameCollection', 'dropCollection', 'dropDatabase', 'dropIndex', 'createUser', 'dropUser', 'dropAllUsersFromDatabase', 'updateUser', 'grantRolesToUser', 'revokeRolesFromUser', 'createRole', 'updateRole', 'dropRole', 'dropAllRolesFromDatabase', 'grantRolesToRole', 'revokeRolesFromRole', 'grantPrivilegesToRole', 'revokePrivilegesFromRole', 'replSetReconfig', 'enableSharding', 'shardCollection', 'addShard', 'refineCollectionShardKey', 'removeShard', 'shutdown', 'applicationMessage' ] } } ] } ] } ] }"
#   audit_authorization_success = true
#   enabled                     = true
# }

# Sets Cluster Maintenance Window
resource "mongodbatlas_maintenance_window" "maintWindow" {
  project_id  = mongodbatlas_project.mongo_project.id
  day_of_week = var.map_maint_window.day_of_week /// App needs to name their var day_of_week?
  hour_of_day = var.map_maint_window.hour_of_day
}

####
# AWS VPC Endpoint
resource "aws_vpc_endpoint" "vpce" {
  # count              = "${var.using_aws_openshift == false ? 1 : 0}"
  # vpc_id             = data.aws_vpc.mongodb_aws_vpc.id
  vpc_id            = "vpc-233b135a"
  service_name      = mongodbatlas_privatelink_endpoint.privatelink_endpoint.endpoint_service_name
  vpc_endpoint_type = "Interface"
  #   subnet_ids         = data.aws_subnet_ids.private_mongodb_subnet_ids.ids
  # subnet_ids         = var.subnet_ids
  subnet_ids         = ["subnet-3d5e0f11", "subnet-dbfaee93", "subnet-7dc40f19", "subnet-1d9bd511", "subnet-6782c93d", "subnet-4435dd7b"]
  security_group_ids = [aws_security_group.mongodb_vpce_sg.id]
}

# Security Group for AWS VPC Endpoint
resource "aws_security_group" "mongodb_vpce_sg" {
  # count       = "${var.using_aws_openshift == false ? 1 : 0}"
  name        = "mongo_vpce_sg_andrew"
  description = "MongoDB VPCE SG"
  #   vpc_id      = data.aws_vpc.mongodb_aws_vpc.id
  vpc_id = var.vpc_id

  ingress {
    description = "Custom TCP"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_block
  }

  egress {
    from_port   = 1024
    to_port     = 1074
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.map_tags
}

# Creates Atlas Endpoint
resource "mongodbatlas_privatelink_endpoint" "privatelink_endpoint" {
  project_id    = mongodbatlas_project.mongo_project.id
  provider_name = var.provider_name
  region        = var.privatelink_endpoint_region # "us-east-1"
}

# Establishes connection between AWS & Atlas
resource "mongodbatlas_privatelink_endpoint_service" "mongo_private_link" {
  # count               = var.using_aws_openshift == false ? 1 : 0
  project_id          = mongodbatlas_project.mongo_project.id
  private_link_id     = mongodbatlas_privatelink_endpoint.privatelink_endpoint.private_link_id
  endpoint_service_id = aws_vpc_endpoint.vpce.id
  # endpoint_service_id = aws_vpc_endpoint.vpce.*.id[count.index]
  provider_name = var.provider_name
}

# Establishes connection between AWS OpenShift & Atlas
# resource "mongodbatlas_privatelink_endpoint_service" "mongo_private_link_aws_container" {
#   count               = var.vpce_id == "" && var.using_aws_openshift == true ? 1 : 0
#   project_id          = mongodbatlas_project.mongo_project.id
#   private_link_id     = mongodbatlas_privatelink_endpoint.privatelink_endpoint.private_link_id
#   endpoint_service_id = var.vpce_id # aws_vpc_endpoint.vpce.id
#   provider_name       = var.provider_name
# }

# Enables Cloud Provider Access for Atlas - required for Encryption
resource "mongodbatlas_cloud_provider_access_setup" "mongo_cpa_setup" {
  project_id    = mongodbatlas_project.mongo_project.id
  provider_name = var.provider_name
}

resource "mongodbatlas_cloud_provider_access_authorization" "auth_role" {
  project_id = mongodbatlas_cloud_provider_access_setup.mongo_cpa_setup.project_id
  role_id    = mongodbatlas_cloud_provider_access_setup.mongo_cpa_setup.role_id

  aws {
    iam_assumed_role_arn = aws_iam_role.mongo_encryption_role.arn
  }
}

# resource "mongodbatlas_cloud_provider_access_authorization" "auth_role" {
#   project_id = mongodbatlas_cloud_provider_access_setup.mongo_cpa_setup.project_id
#   role_id    = mongodbatlas_cloud_provider_access_setup.mongo_cpa_setup.role_id
#   aws {
#     iam_assumed_role_arn = aws_iam_role.mongo_encryption_role.arn
#   }
# }

# Creates IAM Role for Encryption
resource "aws_iam_role" "mongo_encryption_role" {
  name = "pgr-${var.acc_short_alias}-mongodb-encryption-role-andrew"
  tags = var.map_tags
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : mongodbatlas_cloud_provider_access_setup.mongo_cpa_setup.aws.atlas_aws_account_arn
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "sts:ExternalId" : mongodbatlas_cloud_provider_access_setup.mongo_cpa_setup.aws.atlas_assumed_role_external_id
          }
        }
      }
    ]
  })
}

# Creates IAM Role Policy for Encryption
resource "aws_iam_role_policy" "mongo_encryption_role_policy" {
  name = "pgr-${var.acc_short_alias}-mongodb-encryption-role-policy-andrew"
  role = aws_iam_role.mongo_encryption_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey"
        ],
        "Resource" : "arn:aws:kms:us-east-1:208629369896:key/ca67546c-6e40-41ee-99aa-d44a07610eb7"
      }
    ]
  })
}

resource "mongodbatlas_encryption_at_rest" "mongo_encryption" {
  project_id = mongodbatlas_project.mongo_project.id
  aws_kms_config {
    enabled                = true
    role_id                = mongodbatlas_cloud_provider_access_authorization.auth_role.role_id
    customer_master_key_id = "ca67546c-6e40-41ee-99aa-d44a07610eb7"
    region                 = var.encryption_region
  }
}

# resource "mongodbatlas_encryption_at_rest" "mongo_encryption" {
#   project_id = mongodbatlas_project.mongo_project.id

#   aws_kms_config {
#     enabled                = true
#     role_id                = mongodbatlas_cloud_provider_access_authorization.auth_role.role_id
#     customer_master_key_id = var.key_arn
#     region                 = var.encryption_region
#   }
# }
