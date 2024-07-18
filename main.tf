provider "aws" {
  region  = "eu-central-1"
  profile = "christoph"
  shared_credentials_files = ["./credentials"]
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
} 