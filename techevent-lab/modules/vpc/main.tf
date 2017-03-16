resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr_block}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "demo-vpc"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "demo-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = "${var.azs_num}"
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr_block, 8, count.index)}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  depends_on              = ["aws_vpc.default"]

  tags {
    Name = "demo-sn-pub-${count.index}"
  }
}

resource "aws_route_table" "default" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name = "demo-internet-route-table"
  }
}

resource "aws_route_table_association" "a" {
  count          = "${var.azs_num}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.default.id}"
  depends_on     = ["aws_vpc.default", "aws_internet_gateway.igw"]
}
