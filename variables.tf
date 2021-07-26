
variable "region" {
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "10.10.0.0/16"
  type    = string
}
variable "tenancy" {
  default = "default"
}
variable "var_tags" {
  type = map(string)
  default = {
    Name    = "Main"
    Project = "mini-project"
  }
}
variable "nat_amis" {
  type = map(string)
  default = {
    ap-south-1 = "ami-00999044593c895de"
    us-east-1  = "ami-00999044593c895de"
  }
}