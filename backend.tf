terraform {
  backend "s3" {
    bucket         = "serhii-goit-terraform-state-bucket"
    key            = "devops/lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}