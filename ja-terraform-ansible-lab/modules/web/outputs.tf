output "address" {
  value = "${aws_elb.web.dns_name}"
}

output "ips" {
  value = "${join(",", aws_instance.web.*.public_ip)}"
}

output "name" {
  value = "${join(",", aws_instance.web.*.tags.Name)}"
}
