terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

variable "base_cidr_block" {
  description = "default cidr block for vpc"
  default     = "10.0.0.0/16"
}

resource "aws_vpc" "main" {
  cidr_block       = var.base_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "main"
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-ipg"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-route"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# security group for instances
resource "aws_security_group" "main" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.main.id

  # http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # mysql
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # open to all 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main"
  }
}

# get the most recent ami for Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# key pair from local key
resource "aws_key_pair" "local_key" {
  key_name   = "AWS_Key"
  public_key = file("~/.ssh/exam_key.pub")
}

# ec2 instances create 2 instances with different tags using for_each
resource "aws_instance" "ubuntu" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu.id
  for_each      = toset(["web", "db"])

  tags = {
    Name   = "ubuntu-${each.value}"
    Server = "${each.key}-server"
  }

  key_name               = aws_key_pair.local_key.id
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = aws_subnet.main.id

  root_block_device {
    volume_size = 10
  }
}

# output public ip address of the 2 instances
output "instance_public_ips" {
  value = { for i in aws_instance.ubuntu : i.tags.Name => i.public_ip }
}
