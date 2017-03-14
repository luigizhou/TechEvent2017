provider "aws" {
  region = "${var.aws_region}"
}

module "vpc" {
  source = "./modules/vpc"
}

resource "aws_key_pair" "demo-kp" {
  key_name   = "demo-pk"
  public_key = "${file("${path.module}/pk/demo-kp.pub")}"
}

module "web" {
  source = "./modules/web"
  instance_num = "${var.instance_num}"
  key_name = "demo-pk"
  ami_id   = "${lookup(var.amis, var.aws_region)}"
  vpc_id   = "${module.vpc.vpc_id}"
  subnets  = "${module.vpc.pub_id}"
}

resource "null_resource" "ansible-inventory" {
  count = "${var.instance_num >=1 ? 1 : 0 }" 
  triggers {
    instance_ids = "${module.web.name}"
    instances = "${var.instance_num}"
  }

  ## Create web group
  provisioner "local-exec" {
    command = "echo \"[web]\" > ansible/hosts/static"
  }

  provisioner "local-exec" {
    command = "echo \"${join("\n",formatlist("%s ansible_ssh_host=%s ansible_ssh_user=%s ansible_ssh_private_key_file=%s", split(",", module.web.name), split(",", module.web.ips), var.ssh_user, var.ssh_kp))}\" >> ansible/hosts/static"
  }

}

resource "null_resource" "ssh-ready" {
  count = "${var.instance_num}" 
  triggers {
    instance_ids = "${module.web.name}"
    instances = "${var.instance_num}"
  }
  depends_on = [ "null_resource.ansible-inventory" ]

  provisioner "remote-exec" {
    script = "scripts/wait_for_instance.sh"
    connection {
      host = "${element(split(",", module.web.ips), count.index)}"
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
    instance_ids = "${module.web.name}"
    instances = "${var.instance_num}"
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/hosts ansible/site.yml"
  }
}
