provider "aws" {
  profile = "default"
  region  = "eu-west-1"
  version = "2.70"
}

#* In case you need to configure the connection instead of using AWS CLI configs
# provider "aws" {
#   region     = "us-west-2"
#   access_key = "my-access-key"
#   secret_key = "my-secret-key"
# }