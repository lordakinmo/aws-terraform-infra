provider "aws" {
 region = "us-east-1"
 access_key = ""
 secret_key = ""
}
# resource "aws_instance" "first-server" {
#   ami           = "ami-084568db4383264d4"
#   instance_type = "t2.micro"
#   tags = {
#     Name = "ubuntu2"
#   }
# }

# resource "aws_subnet" "subnet-1" {
#   vpc_id     = aws_vpc.first-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod-subnet"
#   }
# }

# resource "aws_vpc" "first-vpc" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#      Name = "production"
#    }
# }

# Terraform variables
variable "subnet_prefix" {
  description = "cidr for subnet"
  #type = string
}


# 1. Create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
   tags = {
     Name = "production"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

# 3. Create Custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# 4. Create a Subnet
 resource "aws_subnet" "subnet-1" {
   vpc_id     = aws_vpc.prod-vpc.id
   cidr_block = var.subnet_prefix[0].cidr_block
   availability_zone = "us-east-1a"
   tags = {
     Name = var.subnet_prefix[0].name
   }
}

resource "aws_subnet" "subnet-2" {
   vpc_id     = aws_vpc.prod-vpc.id
   cidr_block = var.subnet_prefix[1].cidr_block
   availability_zone = "us-east-1a"
   tags = {
     Name = var.subnet_prefix[1].name
   }
}


# 5. Associate subnet with Custom Route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create Security group to allow port 22, 80, 443
resource "aws_security_group" "allow_web" {
  name        = "allow_web-traffic"
  description = "Allow Web traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  tags = {
    Name = "allow_web-traffic"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_web_https" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  description       = "HTTPS"
}

resource "aws_vpc_security_group_ingress_rule" "allow_web_http" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  description       = "HTTP"
}

resource "aws_vpc_security_group_ingress_rule" "allow_web_ssh" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "SSH"
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that was created with step 4
resource "aws_network_interface" "web-server-net-int" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "onee" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-net-int.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

# 8.1 Output command lets you see the output on the terminal
output "server_public_ip" {
    value = aws_eip.onee.public_ip
}

# 9. Create Ubuntu server and install apache2
 resource "aws_instance" "web-server" {
   ami           = "ami-084568db4383264d4"
   instance_type = "t2.micro"
   availability_zone = "us-east-1a"
   key_name = 	"main-key"

  network_interface  {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-net-int.id
  }
  
   user_data = base64encode(<<-EOF
                 #!/bin/bash
                 sudo apt update -y
                 sudo apt install apache2 -y
                 sudo systemctl start apache2
                 sudo bash -c 'echo Web server Up and Running> /var/www/html/index.html'
                 EOF
   )
    tags = {
      Name = "web-server"
    }
 }


output "server_private_ip" {
  value = aws_instance.web-server.private_ip
}

 # Terraform Commands

 # terraform init - initialize terraform to work with provider
 # terraform plan - view the infrastructure to be applied.
 # terraform apply - create infrastructure
 # terraform destroy - remove entire previously created infrastructure (safer to comment out the resource and apply)
 # terraform destroy -target <resource_name> - target a specific resource to destroy and not the entire infrastructure.
 # -target - targets a specific resource, were the command should be applied.
 # --auto-approve - carry out command with prompt
 # terraform state list - view all resources in infrastructure
 # terraform state show <resource_name> - show the configuration of the resource as it is on the cloud, without the console.
 # terraform output - show the output of the already configured output commands in the terraform script.7
 # terraform refresh - to refresh state and output, with applying changes.
 # terraform apply -var-file example.tfvars -  apply variable values from the example.tfvars file, but this doe not need to be explicitly
 # stated if the example.tfvars is in the same folder as project.
 # example.tfvars - used to assign the variable values, while the variables are defined in the main.tf file.