
# Peered AWS VPC Connector

This Terraform module provisions an AWS VPC network + subnets in a standalone AWS account, and peers this new VPC to an existing VPC network in a different account.  The provisioned subnets will be used as the network attachment for a CloudWright Deployment Zone.

While more complex, there are a couple of advantages to this architecture over a single-account, single-network model:

- All CloudWright infrastructure will be deployed into a standalone account, simplifying access controls and billing
- Firewall rules are easier to structure between separate VPC networks
- This model allows CloudWright applications to access the internet without creating an Internet Gateway in your existing VPC network (useful if the existing VPC network should not be internet-connected).

## Overview

This Terraform module:

- Provisions a new VPC network and Internet Gateway

- Configure subnets in new VPC network to allow Lambdas to connect to the public internet (delegating to the [cloudwright-internet-subnets](https://github.com/CloudWright/terraform-aws-cloudwright-internet-subnets) module)

- Peers the new VPC with the existing cross-account VPC

- Configures routes between the two networks

While this Terraform module is designed to work out-of-the-box on standard AWS VPC networks, your network architecture and restrictions may vary, or you may need to make changes to adapt it into your existing Terraform infrastructure.  Please either leave an issue or [contact CloudWright](mailto:contact@cloudwright.io) for help using this module in custom infrastructure.

## Prerequisites

This module provisions network infrastructure, but does not handle account, role or user provisioning.  To use this module, first provision (either manually or in your own Terraform):

- an AWS account in which to provision infrastructure (here, `XXXXX`)

- a user in account `XXXXX` with permission to assume Roles (here, `terraform_provisioner`), which can be granted via a custom Policy: 

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "*"
        }
    ]
}
```

  Generate an Access Key and Secret Access Key for this user; these will be used by Terraform. 

- within account XXXXX, a Role with permission to provision VPC infrastructure (here, `cross-account-vpc-peering-role`).  The `AmazonVPCFullAccess` and `AmazonVPCCrossAccountNetworkInterfaceOperations` managed policies can provide the necessary permissions.  The `terraform_provisioner` user will assume this Role, so it will need the following Trust Relationship:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::XXXXX:user/terraform_provisioner"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

The VPC we are peering will be referred to as `vpc-YYYYY`, within the AWS account `YYYYY`.  Within account `YYYYY`, provision a Role `cross-account-vpc-peering-role`, again with the `AmazonVPCFullAccess` and `AmazonVPCCrossAccountNetworkInterfaceOperations` managed policies, and the Trust Relationship used for the previous Role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::337460175662:user/terraform_provisioner"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

This Role will only be used to (1) accept a peering request, and (2) configure existing Route Tables to route traffic into the new VPC. 

## Using this module

### Variables

- **region**: the region in which to provision infrastructure (ex, `us-east-1`)
- **availability_zone**: the AZ in which to provision infrastructure (ex, `availability_zone`)
- **vpc_cidr**: the CIDR of the VPC to provision.  Important: this CIDR **cannot overlap** with the CIDR of the existing peered VPC 
- **public_cidr**: a CIDR within the above *vpc_cidr*.  See [cloudwright-internet-subnets](https://github.com/CloudWright/terraform-aws-cloudwright-internet-subnets) for more details 
- **private_cidr**: a CIDR within the above *vpc_cidr*.  See [cloudwright-internet-subnets](https://github.com/CloudWright/terraform-aws-cloudwright-internet-subnets) for more details 
- **peer_vpc_id**: the existing VPC with which to peer (`vpc-YYYYY`)
- **peer_owner_id**: the AWS account of the existing VPC (`YYYYY`)
- **dz_admin_role**: the ARN of the first Role defined above (`arn:aws:iam::XXXXX:role/cross-account-vpc-peering`)
- **peered_admin_role**: the ARN of the second Role defined above (`arn:aws:iam::YYYYY:role/cross-account-vpc-peering-role`)

### Standalone execution

If desired, this module can be applied directly via Terraform.  Use the `terraform_provisioner` user to allow Terraform to assume the two Roles defined above.  Configure your aws credential path (usually `~/.aws/credentials`) with a profile corresponding to this user:

```
[peered-dz]
aws_access_key_id=<secret>
aws_secret_access_key=<secret>
```

Export this profile to the `AWS_PROFILE` variable, and invoke Terraform directly:

```bash
export AWS_PROFILE=peered-dz

terraform apply -var 'region=us-east-1' -var 'availability_zone=us-east-1a' -var "vpc_cidr=172.32.80.0/20" -var "public_cidr=172.32.82.0/24" -var "private_cidr=172.32.83.0/24" -var "peer_vpc_id=vpc-YYYYY" -var "peer_owner_id=YYYYY" -var "dz_admin_role=arn:aws:iam::XXXXX:role/cross-account-vpc-peering-role" -var "peered_admin_role=arn:aws:iam::YYYYY:role/cross-account-vpc-peering-role"
```

### As a module

This module can also be included as a public Terraform module:

```

module "cloudwright-vpc-peering" {
    source  = "CloudWright/cloudwright-vpc-peering/aws"
    version = ">= 0.1.0"
    region = "us-east-1"
    availability_zone = "us-east-1a"
    vpc_cidr = "172.32.80.0/20"
    public_cidr = "172.32.82.0/24"
    private_cidr = "172.32.83.0/24"
    peer_vpc_id = "vpc-YYYYY"
    peer_owner_id = "YYYYY"
    dz_admin_role = "arn:aws:iam::XXXXX:role/cross-account-vpc-peering-role"
    peered_admin_role = "arn:aws:iam::YYYYY:role/cross-account-vpc-peering-role"
}
```