terraform {
  backend "s3" {}
}

resource "aws_vpc" "production-vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    "Name" = "Production-VPC"
  }
}

resource "aws_subnet" "public-subnet1" {
    cidr_block = var.public_subnet1_cidr_block
    vpc_id = aws_vpc.production-vpc.id
    availability_zone = "us-east-1a"
    tags = {
     "Name" = "Production-PublicSubnet1"
    }
}

resource "aws_subnet" "public-subnet2" {
    cidr_block = var.public_subnet2_cidr_block
    vpc_id = aws_vpc.production-vpc.id
    availability_zone = "us-east-1b"
    tags = {
      "Name" = "Production-PublicSubnet2"
    }
}

resource "aws_subnet" "public-subnet3" {
    cidr_block = var.public_subnet3_cidr_block
    vpc_id = aws_vpc.production-vpc.id
    availability_zone = "us-east-1c"
    tags = {
      "Name" = "Production-PublicSubnet3"
    }
}

resource "aws_subnet" "private-subnet1" {
    cidr_block = var.private_subnet1_cidr_block
    vpc_id = aws_vpc.production-vpc.id
    availability_zone = "us-east-1a"
    tags = {
      "Name" = "Production-PrivateSubnet1"
    }
}

resource "aws_subnet" "private-subnet2" {
    cidr_block = var.private_subnet2_cidr_block
    vpc_id = aws_vpc.production-vpc.id
    availability_zone = "us-east-1b"
    tags = {
      "Name" = "Production-PrivateSubnet2"
    }
}

resource "aws_subnet" "private-subnet3" {
    cidr_block = var.private_subnet3_cidr_block
    vpc_id = aws_vpc.production-vpc.id
    availability_zone = "us-east-1c"
    tags = {
      "Name" = "Production-PrivateSubnet3"
    }
}

resource "aws_route_table" "public-route-table" {
    vpc_id = aws_vpc.production-vpc.id
    tags = {
      "Name" = "Public-Route-Table"
    }
}

resource "aws_route_table" "private-route-table" {
    vpc_id = aws_vpc.production-vpc.id
    tags = {
      "Name" = "Private-Route-Table"
    }
}

resource "aws_route_table_association" "public-subnet1-association" {
    route_table_id = aws_route_table.public-route-table.id
    subnet_id = aws_subnet.public-subnet1.id
} 

resource "aws_route_table_association" "public-subnet2-association" {
    route_table_id = aws_route_table.public-route-table.id
    subnet_id = aws_subnet.public-subnet2.id
} 

resource "aws_route_table_association" "public-subnet3-association" {
    route_table_id = aws_route_table.public-route-table.id
    subnet_id = aws_subnet.public-subnet3.id
} 

resource "aws_route_table_association" "private-subnet1-association" {
    route_table_id = aws_route_table.private-route-table.id
    subnet_id = aws_subnet.private-subnet1.id
} 

resource "aws_route_table_association" "private-subnet2-association" {
    route_table_id = aws_route_table.private-route-table.id
    subnet_id = aws_subnet.private-subnet2.id
} 

resource "aws_route_table_association" "private-subnet3-association" {
    route_table_id = aws_route_table.private-route-table.id
    subnet_id = aws_subnet.private-subnet3.id
} 

resource "aws_eip" "nat_eip" {
  vpc = true
  associate_with_private_ip = "10.0.0.5"
  tags = {
    "Name" = "Production-NAT-EIP"
  }
}
resource "aws_nat_gateway" "production-nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public-subnet1.id
  tags = {
    "Name" = "Production-NAT-Gateway"
  }
  depends_on = [aws_eip.nat_eip]
}

resource "aws_route" "public-nat-gateway-route" {
  route_table_id = aws_route_table.private-route-table.id
  nat_gateway_id = aws_nat_gateway.production-nat.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_internet_gateway" "production-igw" {
  vpc_id = aws_vpc.production-vpc.id
  tags = {
    "Name" = "Production-NAT-Gateway"
  }
}

resource "aws_route" "public-igw-gateway-route" {
  route_table_id = aws_route_table.public-route-table.id
  gateway_id = aws_internet_gateway.production-igw.id
  destination_cidr_block = "0.0.0.0/0"
}