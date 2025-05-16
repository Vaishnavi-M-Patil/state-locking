# Terraform State Locking using DynamoDB

Terraform state is the backbone of terraform project for provisioning cloud infrastructure. When we work on large infrastructure provisioning with Terraform then it is always more than one developer or team of a developer working on the same terraform project.

The problems arise when two developers try to update the same terraform state file which is stored remotely(S3 Bucket). Ideally, the update on the state file should be done incrementally so that when one developer finishes pushing its state file changes another developer can push their changes after taking the update.

But because of the agile working environment, we can not guarantee that incremental updates on terraform state files will be performed one after another. Any developer can update and push terraform state file at any point in time, so there should be some provision to prevent a developer from writing or updating terraform file when it is already being used by another developer.

Why Terraform State Locking is important?- It prevents Terraform state file(terraform.tfstate) from accidental updates by putting a lock on file so that the current update can be finished before processing the new change. The feature of Terraform state locking is supported by AWS S3 and Dynamo DB.

## Steps:
## 1. How to store Terraform state file remotely on S3?
Provision an EC2 instance using Terraform and store the Terraform state file (terraform.tfstate) remotely in an S3 bucket.
```hcl
terraform {
    backend "s3" {
        bucket = "terraform-backend-1283"
        region = "us-east-1"
        key = "backend/terraform.tfstate"     # path of tfstate file stored in s3
    }
}
```

## 2. Create DynamoDB table on AWS
1. Goto your AWS management console and search for DynamoDB onto the search bar.
2. Click on the DynamoDB
3. From the left navigation panel click on Tables
4. Click on Create Table
5. Enter the Table name - "state-lock" and Partition Key - "LockID"
6. Click on Create Table and you can verify the table after the creation

## 3. Add AWS DynamoDB Table reference to Backend S3 remote state?
After creating the DynamoDB table in the previous step, let's add the reference of DynamoDB table name (state-lock) to backend.
Your final Terraform project1/main.tf should look like this -
```hcl
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

resource "aws_instance" "ec2-instance" {
    ami = "ami-0953476d60561c955"
    instance_type = "t2.micro"
    key_name = "vir-key"
    tags = {
      Name = "ec2 instance- developer1"
    }
}
```

## 4. Spin one more EC2 instance with same terraform state file
To test terraform state locking I will provision one more EC2 machine using the same Terraform state file (jhooq/terraform/remote/s3/terraform.tfstate) stored in my S3 bucket along with the same DynamoDB table (dynamodb-state-locking).

we are still using following two components from previous main.tf:
S3 Bucket - jhooq-terraform-s3-bucket
DynamoDB Table - dynamodb-state-locking
Terraform state file - jhooq/terraform/remote/s3/terraform.tfstate
Here is my another project1/main.tf file -
```hcl
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

resource "aws_instance" "ec2-instance" {
    ami = "ami-0953476d60561c955"
    instance_type = "t2.micro"
    key_name = "vir-key"
    tags = {
      Name = "ec2 instance- developer2"
    }
}
```
Run both the terraform files at the same time to simulate the Locking on terraforming state file

### Terraform State Locking
1. Open two terminals in the same Terraform project.(one for 'project1' and another for 'project2')
2. In Terminal 1, run terraform apply and pause at the approval step.
3. In Terminal 2, try running any Terraform command like plan or apply.
4. Result: Terminal 2 will show a state lock message, as only one process can modify the infrastructure at a time.

## 5. Conclusion:
Terraform state file locking is one of the most valuable features for managing the Terraform state file. When using AWS S3 for remote state storage combined with DynamoDB for state locking, Terraform ensures safer state management by preventing concurrent modifications.
