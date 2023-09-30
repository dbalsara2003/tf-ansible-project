terraform {
  cloud {
    organization = "t3st"

    workspaces {
      name = "4640"
    }
  }

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
  default     = "192.168.0.0/24"
}

resource "aws_vpc" "main" {
  cidr_block       = var.base_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "exam_q03"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.1.0/24"
    availability_zone       = "us-west-2a"
    map_public_ip_on_launch = true
    tags = {
      Name = "exam_q03_load_balancer"
    }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.2.0/24"
    availability_zone       = "us-west-2a"
    map_public_ip_on_launch = false
    tags = {
      Name = "exam_q03_app"
    }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "exam_q03_igw"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "192.168.0.0/24"
    gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "exam_q03_public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "exam_q03_private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "load_balancer" {
  name_prefix = "exam_q03_load_balancer"
}

resource "aws_security_group_rule" "load_balancer-allow-ssh-from-internet" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["142.232.0.0/16"]
  security_group_id = aws_security_group.load_balancer.id
  depends_on = [aws_security_group.load_balancer]
}

resource "aws_security_group_rule" "load_balancer-allow-https-from-internet" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.load_balancer.id
  depends_on = [aws_security_group.load_balancer]
}

resource "aws_security_group_rule" "load_balancer-allow-all-from-app" {
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.load_balancer.id
  source_security_group_id = aws_security_group.application.id
  depends_on = [aws_security_group.load_balancer, aws_security_group.application]
}

resource "aws_security_group_rule" "load_balancer-allow-all-to-app" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.load_balancer.id
  source_security_group_id = aws_security_group.application.id
  depends_on = [aws_security_group.load_balancer, aws_security_group.application]
}

resource "aws_security_group" "application" {
  name_prefix = "exam_q03_app"
}

resource "aws_security_group_rule" "application-allow-ssh-from-load-balancer" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["142.232.0.0/16"]
  security_group_id = aws_security_group.application.id
  depends_on = [aws_security_group.application]
}

resource "aws_security_group_rule" "application-allow-all-from-load-balancer" {
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.application.id
  source_security_group_id = aws_security_group.load_balancer.id
  depends_on = [aws_security_group.application, aws_security_group.load_balancer]
}

resource "aws_security_group_rule" "application-allow-all-to-load-balancer" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.application.id
  source_security_group_id = aws_security_group.load_balancer.id
  depends_on = [aws_security_group.application, aws_security_group.load_balancer]
}



resource "aws_instance" "public" {
  ami           = "ami-07508687309ac4ba5"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.load_balancer.id]
  key_name = "acit4640"
  tags = {
    Name = "load_balancer"
  }
}

resource "aws_instance" "private" {
  ami           = "ami-07508687309ac4ba5"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.application.id]
  key_name = "acit4640"
  tags = {
    Name = "application1"
  }
}

resource "aws_instance" "private2" {
  ami           = "ami-07508687309ac4ba5"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.application.id]
  key_name = "acit4640"
  tags = {
    Name = "application2"
  }
}


