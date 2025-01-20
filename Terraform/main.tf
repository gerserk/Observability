terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "avability_zone" {
  type = string
}

variable "cidr_vpc" {
  type = string
}

variable "cidr_subnet" {
  type = string
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = "eu-west-1"
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_vpc
}

resource "aws_subnet" "ansible_fleet" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"
  cidr_block              = var.cidr_subnet

  tags = {
    Name = "Fleet subnet"
    Type = "Public"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name"  = "Main"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Public"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.ansible_fleet.id
  route_table_id = aws_route_table.rt1.id
}


resource "aws_security_group" "ansible_fleet_sg" {
  name        = "ansible fleet sg"
  description = "Allow traffic on nginx"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ansible_fleet_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "prometheus" {
  security_group_id = aws_security_group.ansible_fleet_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "9090 from anywhere"
  from_port         = 9090
  to_port           = 9090
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "prometheus_alert" {
  security_group_id = aws_security_group.ansible_fleet_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "9093 from anywhere"
  from_port         = 9093
  to_port           = 9093
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "graphana" {
  security_group_id = aws_security_group.ansible_fleet_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "3000 from anywhere"
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "anywhere" {
  security_group_id = aws_security_group.ansible_fleet_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "egress anywhere"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
}

# ###############################################################################  TARGETS
resource "aws_vpc_security_group_ingress_rule" "node_exporter" {
  security_group_id = aws_security_group.ansible_fleet_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "9100 from anywhere"
  from_port         = 9100
  to_port           = 9100
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "cadvisor" {
  security_group_id = aws_security_group.ansible_fleet_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "9101 from anywhere"
  from_port         = 9101
  to_port           = 9101
  ip_protocol       = "tcp"
}
# ###############################################################################

resource "aws_instance" "Ansible_Target1" {
  ami                    = "ami-0d64bb532e0502c46"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.ansible_fleet.id
  vpc_security_group_ids = [aws_security_group.ansible_fleet_sg.id]
  key_name = "myKey"
  depends_on = [
    aws_key_pair.devkey
  ]
}

resource "aws_instance" "Ansible_Target2" {
  ami                    = "ami-0d64bb532e0502c46"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.ansible_fleet.id
  vpc_security_group_ids = [aws_security_group.ansible_fleet_sg.id]
  key_name = "myKey"
  depends_on = [
    aws_key_pair.devkey
  ]
}

resource "aws_instance" "Ansible_Target3" {
  ami                    = "ami-0d64bb532e0502c46"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.ansible_fleet.id
  vpc_security_group_ids = [aws_security_group.ansible_fleet_sg.id]
  key_name = "myKey"
  depends_on = [
    aws_key_pair.devkey
  ]
}

# rpivate key to ssh to instances 
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "devkey" {
  key_name   = "myKey"       # Create a "myKey" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh
  provisioner "local-exec" {
    command = <<EOF
      echo '${tls_private_key.pk.private_key_pem}' > ~/.ssh/ec2-key.pem
      chmod 400 ~/.ssh/ec2-key.pem
    EOF
  }
}
