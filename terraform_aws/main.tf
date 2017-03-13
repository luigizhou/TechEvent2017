# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

############################################################################################################
# SSH KEY-PAIR

resource "aws_key_pair" "demo-kp" {
  key_name   = "demo-pk"
  public_key = "${file("${path.module}/pk/demo-kp.pub")}"
}

###########################################################################################################


# NETWORK SETTINGS
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
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.default.id}"
  depends_on     = ["aws_vpc.default", "aws_internet_gateway.igw"]
}


################################################################################################
# SECURITY GROUPS
# Our elb security group to access
# the ELB over HTTP
resource "aws_security_group" "elb" {
  count = "${var.elb_enable}"
  name        = "elb_sg"
  description = "demo elb sg"

  vpc_id = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags {
    Name = "demo-elb-sg"
  }

  # ensure the VPC has an Internet gateway or this step will fail
}

###############################################################################################
# SERVERS (ELB and EC2 instances)
# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "instance_sg"
  description = "demo-sg"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "demo-ec2-sg"
  }
}


resource "aws_elb" "web" {
  name = "demo-elb"
  count = "${var.instance_num >= 1 ? var.elb_enable : 0 }"

  # The same availability zone as our instance
  subnets = [ "${aws_subnet.public.id}" ]

  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }

  # The instance is registered automatically

  instances                   = [ "${aws_instance.web.*.id}" ]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "demo-elb"
  }
}

#######################################################
# Stickness policy commented out as it is not needed
#resource "aws_lb_cookie_stickiness_policy" "default" {
#  name                     = "lbpolicy"
#  load_balancer            = "${aws_elb.web.id}"
#  lb_port                  = 80
#  cookie_expiration_period = 600
#}

resource "aws_instance" "web" {
  instance_type = "t2.micro"
  count         = "${var.instance_num}"

  ami = "${lookup(var.amis, var.aws_region)}"

  key_name = "${var.key_name}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  subnet_id              = "${aws_subnet.public.id}"

  #Instance tags
  tags {
    Name = "demo-elb-${count.index}"
  }
}


#################################################################
# TF null resource FOR ANSIBLE

resource "null_resource" "ansible-inventory" {
  count = "${var.instance_num >=1 ? 1 : 0 }" 
  triggers {
    instance_ids = "${join(",", aws_instance.web.*.tags.Name)}"
    instances = "${var.instance_num}"
  }

  ## Create web group
  provisioner "local-exec" {
    command = "echo \"[web]\" > ansible/hosts/static"
  }

  provisioner "local-exec" {
    command = "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=%s ansible_ssh_private_key_file=%s", aws_instance.web.*.tags.Name , aws_instance.web.*.public_ip, var.ssh_user, var.ssh_kp))}\" >> ansible/hosts/static"
  }

}

resource "null_resource" "ssh-ready" {
  count = "${var.instance_num}"
  triggers {
    instance_ids = "${join(",",aws_instance.web.*.tags.Name)}"
    instances = "${var.instance_num}"
  }
  depends_on = [ "null_resource.ansible-inventory" ]

  provisioner "remote-exec" {
    script = "scripts/wait_for_instance.sh"
    connection {
      host = "${element(aws_instance.web.*.public_ip, count.index)}"
      type = "ssh"
      user = "${var.ssh_user}"
      private_key = "${file("${path.module}/${var.ssh_kp}")}"
      agent = "false"
    }
  }

}

resource "null_resource" "ansible-provision" {
  count = "${var.instance_num >=1 ? 1 : 0 }" 
  depends_on = [ "null_resource.ssh-ready" ]
  triggers {
    instance_ids = "${join(",",aws_instance.web.*.tags.Name)}"
    instances = "${var.instance_num}"
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/hosts ansible/site.yml"
  }
}
