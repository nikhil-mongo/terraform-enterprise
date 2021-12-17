variable "acc_short_alias" {
  default = "mongo"
}
variable "str_platform" {
  default = "nikhil"
}
variable "str_application" {
  default = "terraform"
}
variable "mongodb_org_id" {
  default = "5c98a80fc56c98ef210b8633"
}
variable "map_maint_window" {
  type = map(any)
}
variable "provider_name" {
  default = "AWS"
}
variable "privatelink_endpoint_region" {
  default = "us-east-1"
}
# variable "vpce_id" {}
variable "key_arn" {
  default = "arn:aws:kms:us-east-1:208629369896:key/ca67546c-6e40-41ee-99aa-d44a07610eb7"
}
# variable mongo_public_key {}
# variable mongo_private_key {}
# variable "using_aws_openshift" {}
variable "map_tags" {
  default = "mongod-terraform"
}
variable "subnet_ids" {
  default = ["subnet-3d5e0f11", "subnet-dbfaee93", "subnet-7dc40f19", "subnet-1d9bd511", "subnet-6782c93d", "subnet-4435dd7b"]
}
variable "vpc_id" {
  default = "vpc-233b135a"
}
variable "encryption_region" {
  default = "US_EAST_1"
}
variable "vpc_cidr_block" {
  default = "172.31.0.0/16"
}