# TECH EVENT DEMO

This repository contains the entire code that will be used to perform a live demo for the tech event that will be held in June.

## PRE-REQUISITES

- Virtualbox
- Vagrant
- A Good Internet Connection :)


## USAGE

```bash
cd tech_event_demo
vagrant up
```

A CentOS 7 Image will be downloaded and used to create a VM. The newly created VM will be provisioned using a script that will perform an entire system update and will install some necessary package.
Once ansible is installed, a playbook is launched to install and configure the remaining necessary software.

## DEMO USAGE

### FIRST STEP

```bash
vagrant ssh
cd techevent-lab
./create_setenv.sh
# Answer the prompt with correct AWS Keys
. ./setenv.sh
terraform plan
terraform apply -var-file=infra.tfvars #without infra.tfvars a single ec2 instance will be created.
```

This will create two linux t2.micro ec2 instances balanced on port 80 and it will also generate all the network configuration needed to make everything works (Security groups, vpc, internet gatewy, etc..).

At the end of the terraform apply, the load balancer URL will be printed from which will be possible to see the two EC2 Instances configured with apache balanced on port 80.

### SECOND STEP

To show how ansible is used to do configuration management, from "techevent-lab" folder just launch the following command:

```bash
ansible-playbook -i ansible/hosts/hosts ansible/site.yml -e 'page=index2 version=2'
```


### THIRD STEP

```bash
echo yes | terraform destroy # or terraform destroy -force
```

## DEMO DETAILS

- Terraform Null Resource is used to provision Ansible at the end of terraform configuration
- A lot of work behind the scenes is done that is not in the scope of the Demo (how AWS networking works)
- Everything can be tested using AWS Free Tier, as long as you don't exceed the given hours, everything will be fine
- Terragrunt is not used, not in the scope of the demo


## AUTHOR

Luigi Zhou 
