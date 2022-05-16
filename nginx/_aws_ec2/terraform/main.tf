terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region_name
  shared_credentials_file = "/root/.aws/credentiais"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "nginx"
  }
}

resource "aws_subnet" "default" {
  vpc_id = aws_vpc.default.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "nginx"
  }
}

resource "aws_network_interface" "nginx-network_interface" {
  subnet_id = aws_subnet.default.id
  security_groups = [aws_security_group.nginx-security-group.id]
  tags = {
    Name = "nginx"
  }
}

resource "aws_security_group" "nginx-security-group" {
  name = "nginx-security-group"
  description = "nginx-security-group"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "nginx" {
  key_name = "nginx"
  public_key = var.public_key
}

resource "aws_instance" "nginx-app" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = "nginx"

  network_interface {
    network_interface_id = aws_network_interface.nginx-network_interface.id
    device_index = 0
  }

  provisioner "remote-exec" {
    connection {
      host = aws_instance.nginx-app.public_ip
      type = "ssh"
      user = var.ssh_user
      private_key = file(var.ssh_key_file)
    }
    inline = [
      <<EOF
      sudo apt-get -y update
      sudo apt-get -y install nginx
      sudo service nginx start
      sudo chown -R $USER:$USER /var/www /usr/share/nginx
      tee /var/www/html/index.html /usr/share/nginx/html/index.html <<-EOF >/dev/null
        <!doctype html>
        <html lang ="en">
        <head>
          <title>Hello World!</title>
        </head>
        <body>
          <h1>Sample web page</h1>
          <p>With little content ;)</p>
        </body>
        </html>
      EOF
    ]
  }
}
