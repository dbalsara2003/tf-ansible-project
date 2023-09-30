terraform {
 
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
  public_key = file("~/.ssh/as4_key.pub")
}


# ec2 instances create 2 instances with different tags using for_each
resource "aws_instance" "ubuntu" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu.id
  for_each = toset(["web", "app"])
  
  tags = {
    Name = "ubuntu-${each.value}"
    Server = "${each.key}-server"
  }

  key_name               = aws_key_pair.local_key.id
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = aws_subnet.main.id

  root_block_device {
    volume_size = 10
  }
}

#I put the instance creation in this file because it can create the instances. You need to create a ssh key before you run this file
