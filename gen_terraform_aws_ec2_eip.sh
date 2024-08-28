#!/bin/bash

# Prompt for the custom EC2 instance name
read -p "Enter the custom name for your EC2 instance: " instance_name

mkdir Terraforms 2>/dev/null
# Create the Terraform file
cat <<EOL > Terraforms/${instance_name}.tf
provider "aws" {
  region = "sa-east-1"  # Specify your preferred AWS region
}

resource "aws_key_pair" "my_key" {
  key_name   = "my_key"
  public_key = file("~/.ssh/id_rsa.pub")  # Update with your actual public key file path
}

resource "aws_security_group" "allow_tcp" {
  name        = "allow_tcp"
  description = "Allow multiple TCP inbound traffic"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c5410a9e09852edd"  # Ubuntu Server 24.04 LTS for sa-east-1 (update with your region's AMI ID)
  instance_type = "t2.micro"

    user_data = <<-EOF
              #!/bin/bash
              curl -fsSL https://raw.githubusercontent.com/frani/tools/main/create_swap.sh | sudo bash
              EOF

  key_name      = aws_key_pair.my_key.key_name
  security_groups = [aws_security_group.allow_tcp.name]

  tags = {
    Name = "$instance_name"
  }
}

resource "aws_eip" "eip" {
  domain = "vpc"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.eip.id
}

output "instance_ip" {
  value = aws_eip.eip.public_ip
}
EOL

# Notify the user
echo "Terraform file '$instance_name.tf' created in 'Terraforms' folder."
echo "Go to 'Terraforms' Folder and run 'terraform apply $instance_name'. Ready to launch ubuntu 24.04 LTS EC2 instance $instance_name in sa-east-1 with EIP"
