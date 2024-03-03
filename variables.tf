variable "AMI" {
  type = map(string)
  default = {
    us-east-1 = "ami-0e731c8a588258d0d"

  }
}

variable "REGION" {
  default = "us-east-1"
}

variable "INSTANCE_TYPE" {
  default = "t2.micro"
}

variable "KEY_NAME" {
  default = "main-key" # change to "vockey" for learner lab
}

variable "ROUTE_CIDR_BLOCK" {
 default = "0.0.0.0/0"
}

variable "CIDR_BLOCK_SUBNET" {
  default = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
}

variable "CIDR_BLOCK_ALL_IPV4" {
  default = ["0.0.0.0/0"]
}
variable "CIDR_BLOCK_VPC" {
  default = "10.0.0.0/16"
}

variable "HTTP_PORT" {
  default = "80"
}

variable "SSH_PORT" {
  default = "22"
}

variable "PROTOCOL_TCP" {
  default = "tcp"
}

variable "PROTOCOL_HTTP" {
  default = "HTTP"
}

variable "EGRESS_PROTOCOL" {
  default = "-1"
}

variable "EGRESS_PORT" {
  default = "0"
}

variable "SUBNET_TAGS" {
  default = ["first_subnet", "second_subnet", "third_subnet"]
}
variable "AVAILABILITY_ZONES" {
  default = ["us-east-1a","us-east-1b","us-east-1c"]
}

variable "PORT_80" {
  default = ["80"]
}

variable "LB_INTERNAL" {
  default = false
}

variable "LB_TYPE" {
  default = "application"
}

variable "LB_ADD_TYPE" {
  default = "ipv4"
}

variable "LB_TARGET_TYPE" {
  default = "instance"
}

variable "COUNTER" {
  default = 0
}

variable "MIN_AUTO_SCALING_SIZE"{
 default = 2
} 

variable "MAX_AUTO_SCALING_SIZE"{
 default = 5
}

variable "DESIRED_AUTO_SCALING_SIZE"{
 default = 3
}

variable "MAP_PUBLIC_IP_TRUE" {
  default = true
}

variable "BLOCK_PUBLIC_ACCESS_TO_BUCKET" {
  default = true
}

variable "bucketname" {
  default = "gov-terraform-macie-2024222"
}

variable "ACL" {
  default = "private"
}