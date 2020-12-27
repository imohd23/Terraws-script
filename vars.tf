variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default     = "10.1.0.0/24"
}
variable "availability_zone" {
  description = "availability zone to create subnet"
  default     = "eu-west-1a"
}
variable "public_key_path" {
  description = "Public key path"
  default     = "./id_rsa.pub"
}
variable "public_key_name" {
  description = "Public key name"
  default     = "id_rsa.pub"
}
variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  default     = "ami-0c3e74fa87d2a4227"
}
variable "instance_type" {
  description = "type for aws EC2 instance"
  default     = "t2.micro"
}
variable "environment_tag" {
  description = "Environment tag"
  default     = "Development"
}
variable "vpc_name" {
  description = "the prefix of the vpc name"
  default     = "Terraform_test_"
}
variable "instance_count" {
  description = "The number of instances to be launched"
  default     = 1
}
