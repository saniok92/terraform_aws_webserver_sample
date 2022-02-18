provider "aws" {
  # profile = "default" 
  region = "eu-central-1"
}

# owner = ["959519296277"] 

# 1. Create VPC
resource "aws_vpc" "prod_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-prod"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# 2. Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "gateway_prod"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# 3. Custom Route Table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "prod-route-table"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# 4. Subnet

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "prod-subnet"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# 5. Associate subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id

  lifecycle {
    create_before_destroy = true
  }
}

# 6. Create security group to allow port 22,80,443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "SSH"
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
  lifecycle {
    create_before_destroy = true
  }
}

# 7. Add network interface with an ip the subnet that was created in step 4

resource "aws_network_interface" "web-server" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  lifecycle {
    create_before_destroy = true
  }
}

# 8. Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]

  lifecycle {
    create_before_destroy = true
  }
}

# 9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "ubuntu_server" {
  ami               = "ami-0d527b8c289b4af7f"
  instance_type     = var.instance_type
  availability_zone = "eu-central-1a"
  key_name          = "#name key pairs"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server.id
  }
  user_data = file("apache2.sh")
  tags = {
    Name = "Ubuntu_server"
  }
  lifecycle {
    create_before_destroy = true
  }
}



