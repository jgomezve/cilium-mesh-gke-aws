resource "aws_security_group" "example_sg" {
  name        = "example-security-group"
  description = "Allow SSH, HTTP, and ICMP inbound traffic"
  vpc_id      = aws_vpc.eks_cluster.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "example" {
  ami           = "ami-01816d07b1128cd2d"
  instance_type = "t2.micro"
  key_name      = "my-demo-key"

  subnet_id              = aws_subnet.eks_nodes.id
  vpc_security_group_ids = [aws_security_group.example_sg.id]

  tags = {
    Name = "Terraform-EC2"
  }
}
