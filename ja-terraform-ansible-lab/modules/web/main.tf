# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "instance_sg"
  description = "demo-sg"
  vpc_id      = "${var.vpc_id}"

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

# Our elb security group to access
# the ELB over HTTP
resource "aws_security_group" "elb" {
  count = "${var.elb_enable}"
  name        = "elb_sg"
  description = "demo elb sg"

  vpc_id = "${var.vpc_id}"

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

resource "aws_elb" "web" {
  name = "demo-elb"
  count = "${var.instance_num >= 1 ? var.elb_enable : 0 }"

  # The same availability zone as our instance
  subnets = [ "${split(",", var.subnets)}" ]

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

#resource "aws_lb_cookie_stickiness_policy" "default" {
#  name                     = "lbpolicy"
#  load_balancer            = "${aws_elb.web.id}"
#  lb_port                  = 80
#  cookie_expiration_period = 600
#}

resource "aws_instance" "web" {
  instance_type = "t2.micro"
  count         = "${var.instance_num}"

  ami = "${var.ami_id}"

  key_name = "${var.key_name}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  subnet_id              = "${element(split(",", var.subnets), count.index )}"

  #Instance tags

  tags {
    Name = "demo-elb-${count.index}"
  }
}
