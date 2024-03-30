######################### Bastion Host #######################


#Create ssh-key / aws keypair for connection to bastion-host, certificate will be used to create the AWS keypair for remote ssh connetion
#cd .certificates
#ssh-keygen -f bastion_host


# Get je-pair from AWS

data "aws_key_pair" "mykeypair" {
  key_name           = "mykeypair"
  include_public_key = true

}

#Get latest ubuntu 20.04 LTS AMI version

data "aws_ami" "ubuntu" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

output "ubuntu" {
  value = data.aws_ami.ubuntu.image_id
}


#Create actual bastion host

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.image_id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.bastion_host_sg.id]
  user_data                   = <<EOF
		#! /bin/bash
        sudo apt update -y && sudo apt upgrade -y
        sudo apt install mysql-client-core-8.0 -y
	EOF

  key_name = data.aws_key_pair.mykeypair.key_name


  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-bastion-host" })
  )

  depends_on = [aws_db_instance.db_app]
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.bastion.public_ip
}

