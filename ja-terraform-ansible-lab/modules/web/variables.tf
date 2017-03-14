variable "subnets" { }
variable "ami_id" { }
variable "key_name" {
  default = "demo-pk"
}
variable "instance_num" { }
variable "vpc_id" { }
variable "elb_enable" {
  default = 1
}
