#configuring the provider
provider "aws" {
  region = var.region
}
# create a s3 backend for Remote state 
terraform {
  backend "s3" {
    bucket = "miniprojs3"
    key    = "terraform.tfstate"
    region = "ap-south-1"
    # create a dynamodb table for state lock 
    dynamodb_table = "mini-proj-table"
  }
}
# create a vpc
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = var.tenancy
  tags             = local.tags
}
# Declare the data source
data "aws_availability_zones" "azs" {
  state = "available"
}
# create a public subnet
resource "aws_subnet" "public" {
  count             = length(local.az_name)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = local.az_name[count.index]
  tags              = local.tags
}
# cretae Internet gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-igw-${terraform.workspace}"
  }
}
# create a public Route table add IGW routes
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public-rt-${terraform.workspace}"
  }
}
# Attach a public route table to public subnet 
resource "aws_route_table_association" "a" {
  count = local.az_count
  subnet_id      = local.pub_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}
# create a private subnet
resource "aws_subnet" "private" {
  count             = length(local.az_name)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(local.az_name))
  availability_zone = local.az_name[count.index]
  tags = {
    Name = "PrivateSubnet-${terraform.workspace}"
  }
}
# create a NAT instance 
resource "aws_instance" "nat" {
  ami                         = lookup(var.nat_amis, var.region)
  instance_type               = "t2.micro"
  subnet_id                   = local.pub_subnet_ids[0]
  associate_public_ip_address = true
  source_dest_check           = false
  tags = {
    Name = "NAT-instance-${terraform.workspace}"
  }
}
# create a private Route table add NAT routes
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.nat.id
  }
  tags = {
    Name = "Private-rt-${terraform.workspace}"
  }
}
# Attach a private route table to private subnet 
resource "aws_route_table_association" "b" {
  count          = local.az_count
  subnet_id      = local.pri_subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}
