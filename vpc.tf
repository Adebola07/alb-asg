# Create a VPC
resource "aws_vpc" "my-vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
  tags = {
    Name = "demo-vpc"
  }
}

# Create 3 public subnets
resource "aws_subnet" "public-subnets" {
  count                   = 3
  vpc_id                  = aws_vpc.my-vpc.id
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(aws_vpc.my-vpc.cidr_block, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.az.names, count.index)

  tags = {
    Name = "demo-public-subnet"
  }

}

# Create 3 private subnets
resource "aws_subnet" "private-subnets" {
  count             = 3
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.my-vpc.cidr_block, 8, count.index + 3)
  availability_zone = element(data.aws_availability_zones.az.names, count.index)

  tags = {
    Name = "demo-private-subnet"
  }

}

# Create public subnets route table
resource "aws_route_table" "my-public-rtb" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rtb"
  }
}

# Create private subnets route table
resource "aws_route_table" "my-private-rtb" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "private-rtb"
  }
}

# Create public subnets route table association
resource "aws_route_table_association" "public-sub" {
  count          = 3
  subnet_id      = element(aws_subnet.public-subnets[*].id, count.index)
  route_table_id = aws_route_table.my-public-rtb.id
}

# Create private subnets route table association
resource "aws_route_table_association" "private-sub" {
  count          = 3
  subnet_id      = element(aws_subnet.private-subnets[*].id, count.index)
  route_table_id = aws_route_table.my-private-rtb.id
}

# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "demo-igw"
  }
}

# Create nat gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.vpc-eip.id
  subnet_id     = aws_subnet.public-subnets[0].id

  tags = {
    Name = "demo-nat-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Create elastic IP
resource "aws_eip" "vpc-eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "demo-eip"
  }
}




data "aws_availability_zones" "az" {
  state = "available"
}
