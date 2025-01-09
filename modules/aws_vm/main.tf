resource "aws_security_group" "instance_sg" {
  name   = "sgrp-${var.name}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "host" {
  ami           = var.ami
  instance_type = var.type
  key_name      = var.ssh_key_name

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  tags = {
    Name = var.name
  }
}
