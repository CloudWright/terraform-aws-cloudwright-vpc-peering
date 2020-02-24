
variable "region" {
  type = string
  description = "The region in which to provision infrastructure (ex, `us-east-1`)"
}

variable "availability_zone" {
  type = string
  description = "The AZ in which to provision infrastructure (ex, `availability_zone`)"
}

variable "vpc_cidr" {
  type = string
  description = "The CIDR of the VPC to provision.  Important: this CIDR **cannot overlap** with the CIDR of the existing peered VPC"
}

variable "public_cidr" {
  type = string
  description = "A CIDR within the above *vpc_cidr*.  See [cloudwright-internet-subnets](https://github.com/CloudWright/terraform-aws-cloudwright-internet-subnets) for more details"
}

variable "private_cidr" {
  type = string
  description = "A CIDR within the above *vpc_cidr*.  See [cloudwright-internet-subnets](https://github.com/CloudWright/terraform-aws-cloudwright-internet-subnets) for more details "
}

variable "peer_vpc_id" {
  type = string
  description = "The existing VPC with which to peer (`vpc-YYYYY`)"
}

variable "peer_owner_id" {
  type = string
  description = "The AWS account of the existing VPC (`YYYYY`)"
}

variable "dz_admin_role" {
  type = string
  description = "The ARN of the first Role defined above (`arn:aws:iam::XXXXX:role/cross-account-vpc-peering`)"
}

variable "peered_admin_role" {
  type = string
  description = "The ARN of the second Role defined above (`arn:aws:iam::YYYYY:role/cross-account-vpc-peering-role`)"
}