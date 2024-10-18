#!/bin/bash

random_name=$(openssl rand -hex 4)

# Prompt for the custom EC2 instance name
read -p "Enter the custom name for your EC2 instance (default is instance-$random_name): " instance_name
instance_name=${instance_name:-instance-$random_name}

echo
echo "Instace name: $instance_name"
echo 

# check if terraform is installed
if ! [ -x "$(command -v terraform)" ]; then
  echo "Terraform is not installed."
fi

# check if aws cli is installed
if ! [ -x "$(command -v aws)" ]; then
  echo "AWS CLI is not installed."
fi

# read which region to use, shows available regions
echo "Available regions: sa-east-1, us-east-1, us-east-2, us-west-1, us-west-2"
# check if region is valid and if not, ask for it again
while [ "$region" != "sa-east-1" ] && [ "$region" != "us-east-1" ] && [ "$region" != "us-east-2" ] && [ "$region" != "us-west-1" ] && [ "$region" != "us-west-2" ]; do
  read -p "Enter the region to use (default is sa-east-1): " region
  region=${region:-"sa-east-1"}
  if [ "$region" != "sa-east-1" ] && [ "$region" != "us-east-1" ] && [ "$region" != "us-east-2" ] && [ "$region" != "us-west-1" ] && [ "$region" != "us-west-2" ]; then
    echo "Invalid region."
  fi
done
echo 
echo "Region: $region"
echo

# Ask if want to add swap memory int the instance, default is Y
read -p "Do you want to add swap memory to the instance? (Y/n): " add_swap
add_swap=${add_swap:-"y"}
echo  
echo "Add swap: $(if [ "$add_swap" == "y" ]; then echo "Yes"; else echo "No"; fi)"
echo
# ternary of add add_swap


# Ask if want to install Docker in the instance, default is Y
read -p "Do you want to install Docker in the instance? (Y/n): " install_docker
install_docker=${install_docker:-"y"}
echo  
echo "Install Docker: $(if [ "$install_docker" == "y" ]; then echo "Yes"; else echo "No"; fi)"
echo

# Ask how much size in GB for the EBS volume, default is 30 GB
read -p "How much size in GB for the EBS volume? (default is 30): " ebs_size
ebs_size=${ebs_size:-"30"}
echo  
echo "EBS size: $ebs_size GB"
echo

# check if terraforms folder exists and if exists, clean it
rm -rf terraforms 2>/dev/null
mkdir terraforms 2>/dev/null

# Create the Terraform file
cat <<EOL > terraforms/${instance_name}.tf
provider "aws" {
  region = "$region"  # Specify your preferred AWS region
}

resource "aws_key_pair" "$instance_name-key" {
  key_name   = "$instance_name-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Update with your actual public key file path
}

resource "aws_security_group" "$instance_name-allow_tcp" {
  name        = "$instance_name-allow_tcp"
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

resource "aws_ebs_volume" "$instance_name-ebs" {
  availability_zone = aws_instance.web.availability_zone
  size              = $ebs_size
  tags = {
    Name = "$instance_name EBS"
  }
}

resource "aws_instance" "$instance_name" {
  ami           = "ami-0c5410a9e09852edd"  # Ubuntu Server 24.04 LTS for sa-east-1 (update with your region's AMI ID)
  instance_type = "t2.micro"

  user_data = <<-EOF
    #!/bin/bash
    $(if [ "$add_swap" == "y" ]; then echo "curl -fsSL https://raw.githubusercontent.com/frani/tools/main/create_swap.sh | sudo bash"; fi)
    $(if [ "$install_docker" == "y" ]; then echo "curl -fsSL https://raw.githubusercontent.com/frani/tools/main/install-docker-nginx-ubuntu.sh | sudo bash"; fi)
    EOF

  key_name      = aws_key_pair.my_key.key_name
  security_groups = [aws_security_group.$instance_name-allow_tcp.name]

  tags = {
    Name = "$instance_name"
  }
}

resource "aws_eip" "$instance_name-eip" {
  domain = "vpc"
}

resource "aws_eip_association" "$instance_name-eip_assoc" {
  instance_id   = aws_instance.$instance_name.id
  allocation_id = aws_eip.$instance_name-eip.id
}

output "instance_ip" {
  value = aws_eip.$instance_name-eip.public_ip
}
EOL

# Notify the user
echo "Terraform file '$instance_name.tf' created in 'terraforms' folder."
echo "Follow next steps:"
echo "1. go to 'terraforms' folder"
echo "2. run 'terraform init'"
echo "3. run 'terraform plan'"
echo "4. run 'terraform apply'"
echo "5. Ready to launch ubuntu 24.04 LTS EC2 instance $instance_name in $region with EIP"
echo "6. Copy the instance_ip that should be displayed after running 'terraform apply' and use it to connect to the instance with ssh: ubuntu@<instance_ip>"

