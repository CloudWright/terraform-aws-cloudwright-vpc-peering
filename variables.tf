
variable "region" {
  type = string
  description = "TODO"
}

variable "availability_zone" {
  type = string
  description = "TODO"
}

variable "vpc_cidr" {
  type = string
  description = "cidr for vpc"
}

variable "public_cidr" {
  type = string
  description = "Public Subnet CIDR block (should be within 'vpc-cidr')"
}

variable "private_cidr" {
  type = string
  description = "Private Subnet CIDR block (should be within 'vpc-cidr')"
}

variable "peer_vpc_id" {
  type = string
  description = "vpc id to peer with"
}

variable "peer_owner_id" {
  type = string
  description = "account of target vpc"
}

variable "dz_admin_role" {
  type = string
  description = "Role <TODO>"
}

variable "peered_admin_role" {
  type = string
  description = "role TODO"
}