provider "aws" {
  region     = var.region
  profile = "posh"
}

# Create a VPC

resource "aws_vpc" "prodvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "production_vpc"
  }
}

# Create a Subnet

resource "aws_subnet" "prodsubnet1" {
  vpc_id            = aws_vpc.prodvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "prod-subnet"
  }
}


#Create the Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prodvpc.id

  tags = {
    Name = "New"
  }
}

# Create a Route Table
resource "aws_route_table" "prodroute" {
  vpc_id = aws_vpc.prodvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "RT"
  }
}


#Associate the subnet with the Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prodsubnet1.id
  route_table_id = aws_route_table.prodroute.id
}


# create security group for the Nexus instance
resource "aws_security_group" "ec2_security_group_nexus" {
  name        = "ec2 security group_nexus"
  description = "allow access on ports 8080 and 22"
  vpc_id      = aws_vpc.prodvpc.id

  # allow access on port 8080
  ingress {
    description      = "nexus access"
    from_port        = 8081
    to_port          = 8081
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # ingress {
  #   description      = "http proxy access"
  #   from_port        = 8082
  #   to_port          = 8082
  #   protocol         = "tcp"
  #   cidr_blocks      = ["0.0.0.0/0"]
  # }

  # allow access on port 22
  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "nexus server security group"
  }
}


# use data source to get a registered ubuntu ami
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

# Create the EC2 instance and assign key pair

resource "aws_instance" "thirdinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.xlarge"
  vpc_security_group_ids = [aws_security_group.ec2_security_group_nexus.id]
  subnet_id              = aws_subnet.prodsubnet1.id
  key_name               = "Virginia - 2024"
  availability_zone      = "us-east-1a"
  user_data              =  "${file("nexus.sh")}"
  


  tags = {
    Name = "Nexus_Server"
  }
}


# print the url of the nexus server
output "Nexus_website_url1" {
  value     = join ("", ["http://", aws_instance.thirdinstance.public_dns, ":", "8081"])
  description = "Nexus Server is thirdinstance"
}
