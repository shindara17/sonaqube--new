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

# create security group for the sonarqube instance
resource "aws_security_group" "ec2_security_group_sonarqube" {
  name        = "ec2 security group_sonarqube"
  description = "allow access on ports 8080 and 22"
  vpc_id      = aws_vpc.prodvpc.id

  # allow access on port 8080
  ingress {
    description      = "sonarqube access"
    from_port        = 9000
    to_port          = 9000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "http proxy access"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

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
    Name = "sonarqube server security group"
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

resource "aws_instance" "fourthinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.ec2_security_group_sonarqube.id]
  subnet_id              = aws_subnet.prodsubnet1.id
  key_name               = "Virginia - 2024"
  availability_zone      = "us-east-1a"
  user_data              =  "${file("sonaqube.sh")}"
  


  tags = {
    Name = "Sonaqube_Server"
  }
}


# print the url of the sonaqube server
output "Sonaqube_website_url1" {
  value     = join ("", ["http://", aws_instance.fourthinstance.public_dns, ":", "9000"])
  description = "Sonaqube Server is fourthinstance"
}