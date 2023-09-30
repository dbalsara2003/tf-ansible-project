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
  default     = "10.0.0.0/16"
}

resource "aws_vpc" "main" {
  cidr_block       = var.base_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "acit-4640-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "acit-4640-pub-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false
  tags = {
    Name = "acit-4640-rds-sub1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = false
  tags = {
    Name = "acit-4640-rds-sub2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "acit-4640-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "acit-4640-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "ec2_sg" {
  name        = "acit-4640-sg-ec2"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "acit-4640-sg-rds"
  description = "Allow SQL traffic within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "db_subnet" {
  name        = "acit-4640-rds-subnet"
  description = "Subnets for RDS"
  subnet_ids  = [aws_subnet.private.id, aws_subnet.private2.id]
}

resource "aws_key_pair" "main" {
  key_name   = "acit-4640"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsp6uUD0/ksWblkOdMYNMWasYPTh8XIayEk4oWp2i1O daryush@ligma"
}

resource "aws_instance" "ec2" {
  ami                    = "ami-0735c191cf914754d"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  tags = {
    Name = "acit-4640-ec2"
  }
}

resource "aws_db_instance" "rds-db" {
  identifier             = "acit-4640-rds"
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  multi_az               = false
  username               = "root"
  password               = "password"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  publicly_accessible    = false
  skip_final_snapshot    = true
  apply_immediately      = true
  availability_zone      = "us-west-2a"

  tags = {
    Name = "acit-4640-rds"
  }
}

output "ec2_public_ip" {
  value = aws_instance.ec2.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.rds-db.endpoint
}

output "rds_username" {
  value     = aws_db_instance.rds-db.username
  sensitive = true
}

output "rds_password" {
  value     = aws_db_instance.rds-db.password
  sensitive = true
}
