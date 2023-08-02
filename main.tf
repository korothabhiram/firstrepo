#create a VPC
#Create an internet gateway
#create a custom route table
#create a subnet
#associate subnet with route table
#create a security group to allow ports 22,443 and 80
#create a network interface with an IP in the subnet--step 4
#assign an elastic IP to the network interface--step 7
#creaate an ubuntu server and install/enable apache2


# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "AKIA6BMSZKSMSA4JX6FB"
  secret_key = "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"
}

resource "aws_vpc" "test_server" {
  cidr_block = "10.0.0.0/16"
  
   tags = {
    Name = "test"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.test_server.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.test_server.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "rt"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.test_server.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "st"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "port" {
  name        = "Connection"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.test_server.id

  ingress {
    description = "https from outside"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description = "http from outside"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  
  ingress {
    description = "ssh from outside"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.port.id]
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.test.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_instance" "web" {
  ami = "ami-0885b1f6bd170450c"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "ec2key"
  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.test.id
  }
  user_data = <<-EOF
               #!/bin/bash
               sudo apt update -y
               sudo apt install apache2 -y
               sudo systemctl start apache2
               sudo bash -c "echo your first webserver >> /var/www/html/index.html"
               EOF 
    tags = {
      "Name" = "webserver"
    }
}
