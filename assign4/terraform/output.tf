# output public ip address of the 2 instances
output "instance_public_ips" {
  value = { for i in aws_instance.ubuntu: i.tags.Name => i.public_ip }
}

#this is here because it outputs the ip of the ec2 instance after the other config files finish running
