variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "region_name" {
  type = string
  default = "eu-central-1"
}

variable "public_key" {
  type = string
  default = ""
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "ssh_key_file" {
  default = ""
}

variable "ssh_user" {
  default = "ubuntu"
}
