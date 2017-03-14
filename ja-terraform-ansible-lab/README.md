# ja-terraform-ansible-lab
The example launches $instance_num web servers, installs Apache HTTPD, creates an ELB for instance. It also creates security groups for the ELB and EC2 instances. 

To run, configure your AWS provider as described in https://www.terraform.io/docs/providers/aws/index.html


## Variables

## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| aws_region |  | `"eu-west-1"` | no |
| amis |  | `<map>` | no |
| instance_num |  | `1` | no |
| ssh_user |  | `"ec2-user"` | no |
| ssh_kp |  | `"pk/demo-kp.pem"` | no |

## Outputs

| Name | Description |
|------|-------------|
| weburl |  |


## Usage

1. Configure your aws credentials
2. Specify your region. aws_region [detault: eu-west-1]
3. Create your infrastructure

To create your balanced webservers execute

```bash

terraform apply -var-file=infra.tfvars

    Wait a couple of minutes for the EC2 Ansible to install Apache HTTPD, and then type the ELB DNS Name from outputs in your browser and see the welcome page


```

4. destroy everything

```bash

echo yes | terraform destroy
```

## License

BSD
