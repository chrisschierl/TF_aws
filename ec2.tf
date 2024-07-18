# Create a Subnet
resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true
}

# Create an Internet Gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# Create a Route Table
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.example.id
  route_table_id = aws_route_table.example.id
}

# Create a Security Group
resource "aws_security_group" "example" {
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# Create an IAM Role
resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach IAM Policies to the Role
resource "aws_iam_role_policy" "example" {
  name   = "example-policy"
  role   = aws_iam_role.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2-instance-connect:SendSSHPublicKey",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create an IAM Instance Profile
resource "aws_iam_instance_profile" "example" {
  name = "example-instance-profile"
  role = aws_iam_role.example.name
}

# Create a Key Pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "example" {
  key_name   = "example-key"
  public_key = tls_private_key.example.public_key_openssh
}

# Save the private key to a file
resource "local_file" "example_pem" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/example-key.pem"
}

# Create an Elastic IP
resource "aws_eip" "example" {
  domain = "vpc"
}


# Create an EC2 Instance
resource "aws_instance" "example" {
  ami                         = "ami-0e872aee57663ae2d" # Example AMI ID, change it to the desired one
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.example.id
  vpc_security_group_ids      = [aws_security_group.example.id]
  iam_instance_profile        = aws_iam_instance_profile.example.name
  key_name                    = aws_key_pair.example.key_name
  associate_public_ip_address = true

  tags = {
    Name = "ExampleInstance"
  }
}

# Associate the Elastic IP with the EC2 Instance
resource "aws_eip_association" "example" {
  instance_id   = aws_instance.example.id
  allocation_id = aws_eip.example.id
}