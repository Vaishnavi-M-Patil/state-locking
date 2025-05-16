terraform {
    backend "s3" {
        bucket = "terraform-backend-1283"
        region = "us-east-1"
        key = "backend/terraform.tfstate"     
        dynamodb_table = "state_lock" 
    }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "instance1" {
    ami = "ami-0953476d60561c955"
    instance_type = "t2.micro"
    key_name = "vir-key"
    tags = {
      Name = "ec2 instance- developer1"
    }
}