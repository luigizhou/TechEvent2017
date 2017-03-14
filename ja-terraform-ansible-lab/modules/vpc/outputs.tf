output "pub_id" {
  value = "${join(",", aws_subnet.public.*.id)}"
}

output "vpc_id" {
  value = "${aws_vpc.default.id}"
}

output "igw_id" {
  value = "${aws_internet_gateway.igw.id}"
}
