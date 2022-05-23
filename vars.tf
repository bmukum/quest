
variable "ami_id" {
  description = "ami id"
  type        = string
  default     = "ami-0022f774911c1d690"
}

variable "instance_type" {
  description = "Instance type to create an instance"
  type        = string
  default     = "t2.micro"
}

variable "ssh_private_key" {
  description = "pem file of Keypair we used to login to EC2 instances"
  type        = string
  default     = "rearc.pem"
}
