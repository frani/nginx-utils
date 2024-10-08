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

# check if terraforms folder exists and if exists, clean it
rm -rf terraforms 2>/dev/null
mkdir terraforms 2>/dev/null

# Create the Terraform file
cat <<EOL > terraforms/${instance_name}.tf
provider "aws" {
  region = "$region"  # Specify your preferred AWS region
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
echo "Terraform file '$instance_name.tf' created in 'terraforms' folder."
echo "Follow next steps:"
echo "1. go to 'terraforms' folder"
echo "2. run 'terraform init'"
echo "3. run 'terraform plan'"
echo "4. run 'terraform apply'"
echo "5. Ready to launch ubuntu 24.04 LTS EC2 instance $instance_name in $region with EIP"
echo "6. Copy the instance_ip that should be displayed after running 'terraform apply' and use it to connect to the instance with ssh: ubuntu@<instance_ip>"

