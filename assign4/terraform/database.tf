terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# create security group for the database
resource "aws_security_group" "database_security_group" {
  name        = "database security group"
  description = "enable mysql/aurora access on port 3306"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "mysql/aurora access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.main.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_security_group"
  }
}

# create the subnet group for the rds instance
resource "aws_db_subnet_group" "database_subnet_group" {
  name        = "rds_subnet_group"
  subnet_ids  = [aws_subnet.rds-sn1.id, aws_subnet.rds-sn2.id]
  description = "Subnet group for RDS database"

  tags = {
    Name = "database_subnet_group"
  }
}

# create the rds instance
resource "aws_db_instance" "db_instance" {
  engine                 = "mysql"
  engine_version         = "8.0.31"
  multi_az               = false
  identifier             = "rds-database-instance"
  username               = "fortysix"
  password               = "password"
  instance_class         = "db.t2.micro"
  allocated_storage      = 200
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  availability_zone      = "us-west-2a"
  db_name                = "fortysix"
  skip_final_snapshot    = true
}

#this is the database creation I put this here because it can create the database

