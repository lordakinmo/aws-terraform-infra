# AWS Infrastructure Provisioning with Terraform

This project demonstrates how to provision a secure and scalable AWS infrastructure using Terraform. It includes networking components (VPC, subnets, route tables), security groups, EC2 instance provisioning, and web server automation using a `user_data` script.

## 📌 Key Technologies
- **Terraform** for Infrastructure as Code (IaC)
- **AWS** EC2, VPC, Subnets, Security Groups, Elastic IP
- **Apache2** for automated web server deployment
- **Ubuntu AMI** for EC2 instance
- **Base64-encoded user_data** for cloud-init automation

---

## 🚀 Infrastructure Overview

The following resources are provisioned using Terraform:

1. **VPC** – Custom VPC with `10.0.0.0/16` CIDR block.
2. **Subnets** – Two subnets defined via variable input (for scalability).
3. **Internet Gateway** – Enables internet access to instances in public subnet.
4. **Custom Route Table** – Configured with default IPv4 and IPv6 routes.
5. **Security Group** – Inbound access for ports `22`, `80`, and `443`.
6. **Elastic IP** – Associated with a network interface on the EC2 instance.
7. **EC2 Instance** – Ubuntu instance with Apache2 installed automatically.
8. **Network Interface** – Attached to the EC2 instance for IP management.
9. **Outputs** – Public and private IPs of the EC2 instance are output.

---

## ⚙️ Setup & Usage

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/terraform-aws-ec2-webserver.git
cd terraform-aws-ec2-webserver
```
### 2. Configure AWS Credentials
Edit the provider block in main.tf to add your AWS credentials (or use environment variables / AWS CLI auth methods):
```bash
provider "aws" {
  region     = "us-east-1"
  access_key = "YOUR_ACCESS_KEY"
  secret_key = "YOUR_SECRET_KEY"
}
```
### 3. Define Subnet Variables
Create a terraform.tfvars file or edit in main.tf:
```bash
subnet_prefix = [
  {
    cidr_block = "10.0.1.0/24"
    name       = "subnet-1"
  },
  {
    cidr_block = "10.0.2.0/24"
    name       = "subnet-2"
  }
]
```
### 4. Initialize Terraform
```bash
terraform init
```
### 5. Plan the Deployment
```bash
terraform plan
```
### 6. Apply the Configuration
```bash
terraform apply --auto-approve
```
### What’s Automated?
Web Server Setup:
Apache2 is automatically installed and started on the EC2 instance. The landing page is customized to show “Web server Up and Running”.

Network & Security:
Ingress rules for HTTP (80), HTTPS (443), and SSH (22) are configured. An Elastic IP is bound to the network interface.

Outputs:
You’ll see the public and private IPs of the server after apply completes.

### Output Sample
output "server_public_ip" {
  value = aws_eip.onee.public_ip
}

output "server_private_ip" {
  value = aws_instance.web-server.private_ip
}

### Common Terraform Commands
```bash
terraform init                      # Initialize working directory
terraform plan                      # Preview infrastructure changes
terraform apply                     # Apply configuration to AWS
terraform destroy                   # Tear down all resources
terraform output                    # Show configured outputs
terraform refresh                   # Sync Terraform state with real infrastructure
terraform destroy -target=<res>     # Destroy a specific resource
terraform state list                # View all resources in state
terraform state show <resource>     # Inspect specific resource in state
```
### Notes
AMI Used: ami-084568db4383264d4 (Ubuntu, us-east-1 region)

Latest Tools: Latest versions of Terraform and Ubuntu are recommended

Elastic IP: Ensures a persistent public IP address for access

Private Key: Ensure your EC2 key pair is correctly set in key_name
