
provider "aws" {
  region  = var.region

  assume_role {
    role_arn = var.dz_admin_role
  }
}

provider "aws" {
  alias   = "dz"
  region  = var.region

  assume_role {
    role_arn = var.dz_admin_role
  }
}

provider "aws" {
  alias = "peered_acct"
  region  = var.region

  assume_role {
    role_arn = var.peered_admin_role
  }
}

resource "aws_vpc" "dz_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.dz_vpc.id
}

module "cloudwright-internet-subnets" {
  source  = "CloudWright/cloudwright-internet-subnets/aws"
  version = ">= 0.1.1"
  vpc_id = aws_vpc.dz_vpc.id
  region = var.region
  availability_zone = var.availability_zone
  public_cidr_block = var.public_cidr
  private_cidr_block = var.private_cidr
  igw_id = aws_internet_gateway.gw.id

  providers = {
    aws = aws.dz
  }
}

data "aws_caller_identity" "peer" {
  provider = aws.peered_acct
}

data "aws_region" "peer" {
  provider = aws.peered_acct
}

resource "aws_vpc_peering_connection" "default" {
  peer_owner_id = data.aws_caller_identity.peer.account_id
  vpc_id        = aws_vpc.dz_vpc.id
  peer_vpc_id   = var.peer_vpc_id
  auto_accept   = false

  tags = {
    Name = "CloudWright_Peer"
  }

}

data "aws_vpc" "acceptor" {
  provider = aws.peered_acct
  id       = var.peer_vpc_id
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.peered_acct
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id
  auto_accept               = true
}

resource "aws_vpc_peering_connection_options" "requester" {
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [aws_vpc_peering_connection_accepter.peer]
}


resource "aws_vpc_peering_connection_options" "accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  provider = aws.peered_acct

  depends_on = [aws_vpc_peering_connection_accepter.peer]
}

data "aws_subnet_ids" "acceptor" {
  provider = aws.peered_acct
  vpc_id   = data.aws_vpc.acceptor.id
}

data "aws_route_table" "acceptor" {
  provider = aws.peered_acct
  count    = length(distinct(sort(data.aws_subnet_ids.acceptor.ids)))

  subnet_id = element(
    distinct(sort(data.aws_subnet_ids.acceptor.ids)),
    count.index
  )
}

resource "aws_route" "requestor" {

  count = length(data.aws_vpc.acceptor.cidr_block_associations)

  route_table_id = module.cloudwright-internet-subnets.private_route_table_id

  destination_cidr_block    = data.aws_vpc.acceptor.cidr_block_associations[count.index]["cidr_block"]
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id
  depends_on = [
    aws_vpc_peering_connection.default,
  ]
}

resource "aws_route" "acceptor" {
  provider = aws.peered_acct

  count = length(
    distinct(sort(data.aws_route_table.acceptor.*.route_table_id))
  )

  route_table_id = element(
    distinct(sort(data.aws_route_table.acceptor.*.route_table_id)),
    count.index
  )

  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id
  depends_on = [
    data.aws_route_table.acceptor,
    aws_vpc_peering_connection.default,
  ]
}
