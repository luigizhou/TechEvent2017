variable "aws_region" {
  default = "eu-west-1"
}

variable "amis" {
  type = "map"
  default = {
    eu-west-1 = "ami-02ace471"
  }
}

variable "instance_num" {
  default = 1
}

variable "ssh_user" {
  default = "ec2-user"
}

variable "ssh_kp" {
  default = "pk/demo-kp.pem"
}


variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "key_name" {
  default = "demo-pk"
}

variable "elb_enable" {
  default = 1
}
