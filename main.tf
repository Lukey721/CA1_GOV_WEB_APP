#Author: Luke Connolly
#Student Number: X00218713
#Module: IT Infastructure


#define virtual private cloud
resource "aws_vpc" "main_vpc" {
  cidr_block        = var.CIDR_BLOCK_VPC

  tags = {
    Name = "main_vpc"
  }
}

#creating multi subnets in vpc to have multiple AZ's
#AVAILABILITY ZONE 1
resource "aws_subnet" "first_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.CIDR_BLOCK_SUBNET[0]
  availability_zone = var.AVAILABILITY_ZONES[0]   #look to array for availability zone
  map_public_ip_on_launch = var.MAP_PUBLIC_IP_TRUE
  tags = {
    Name = var.SUBNET_TAGS[0]
  }
}

#AVAILABILITY ZONE 2
resource "aws_subnet" "second_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.CIDR_BLOCK_SUBNET[1]
  availability_zone = var.AVAILABILITY_ZONES[1]  
  map_public_ip_on_launch = var.MAP_PUBLIC_IP_TRUE
  tags = {
    Name = var.SUBNET_TAGS[1]
  }
}

#AVAILABILITY ZONE 3
resource "aws_subnet" "third_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.CIDR_BLOCK_SUBNET[2]
  availability_zone = var.AVAILABILITY_ZONES[2]
  map_public_ip_on_launch = var.MAP_PUBLIC_IP_TRUE
  tags = {
    Name = var.SUBNET_TAGS[2]
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "i_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "internet_gateway" 
  }
}

# Create a route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.ROUTE_CIDR_BLOCK
    gateway_id = aws_internet_gateway.i_gateway.id
  }

  tags = {
    Name = "route_table" 
  }
}

# Associate the subnet 1 with the route table
resource "aws_route_table_association" "subnet_1a_association" {
  subnet_id      = aws_subnet.first_subnet.id
  route_table_id = aws_route_table.public.id
}

# Associate the subnet 2 with the route table
resource "aws_route_table_association" "subnet_1b_association" {
  subnet_id      = aws_subnet.second_subnet.id
  route_table_id = aws_route_table.public.id
}

# Associate the subnet 3 with the route table
resource "aws_route_table_association" "subnet_1c_association" {
  subnet_id      = aws_subnet.third_subnet.id
  route_table_id = aws_route_table.public.id
}

#security group to decide inbound and outbound
resource "aws_security_group" "allow_web" {

    name = "Allow Web Traffic"
    description = "Allow Web Inbound"
    vpc_id = aws_vpc.main_vpc.id
  
  ingress {
    
    description = "Allow HTTP"
    from_port        = var.HTTP_PORT
    to_port          = var.HTTP_PORT
    protocol         = var.PROTOCOL_TCP
    cidr_blocks      = var.CIDR_BLOCK_ALL_IPV4
    
  }

  ingress {
    description = "Allow SSH"
    from_port        = var.SSH_PORT
    to_port          = var.SSH_PORT
    protocol         = var.PROTOCOL_TCP
    cidr_blocks      = var.CIDR_BLOCK_ALL_IPV4
    
  }

  egress {
    description = "Traffic Out"
    from_port        = var.EGRESS_PORT
    to_port          = var.EGRESS_PORT
    protocol         = var.EGRESS_PROTOCOL
    cidr_blocks      = var.CIDR_BLOCK_ALL_IPV4
    
  }

  tags = {
    Name = "Allow Web Traffic to VPC"
  }
}

#create load balancer
resource "aws_lb" "web-balancer" {
  name = "web-balancer"
  internal = var.LB_INTERNAL
  load_balancer_type = var.LB_TYPE #as web traffic choose between 3
  ip_address_type = var.LB_ADD_TYPE
  security_groups = [ aws_security_group.allow_web.id ] 
  subnets = [ aws_subnet.first_subnet.id, aws_subnet.second_subnet.id, aws_subnet.third_subnet.id ]

  tags = {
    Name = "web-balancer"
  }
}

#create target group for alb, route the incoming requests to targets
resource "aws_lb_target_group" "web-balancer-target-gp" {

  name = "web-balancer-target-gp"
  target_type = var.LB_TARGET_TYPE
  port = var.HTTP_PORT
  protocol = var.PROTOCOL_HTTP
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "web-balancer-target-gp"
  }
  
}

#create ALB listener on port 80 and send traffic to target group

resource "aws_lb_listener" "web_balancer_listener" {
  load_balancer_arn = aws_lb.web-balancer.arn
  port = var.HTTP_PORT
  protocol = var.PROTOCOL_HTTP

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web-balancer-target-gp.arn
  }
}

#configure settings for ec2's getting launched
resource "aws_launch_template" "app_launch_template" {
   
   name = "app_launch_template"
   image_id = lookup(var.AMI, var.REGION)
   instance_type = var.INSTANCE_TYPE
   key_name = var.KEY_NAME

   vpc_security_group_ids = [aws_security_group.allow_web.id]

   tag_specifications {
     resource_type = "instance"

     tags = {
       Name = "gov-server"
     }
   }
    user_data = filebase64("script.sh")

    lifecycle {
      create_before_destroy = true
    }

}

#create auto scaling group which will define the min and max ec2 
resource "aws_autoscaling_group" "web_auto_scaling" {
  name = "web_auto_scaling"
  desired_capacity = var.DESIRED_AUTO_SCALING_SIZE # num of instances
  max_size = var.MAX_AUTO_SCALING_SIZE
  min_size = var.MIN_AUTO_SCALING_SIZE

  launch_template {
    id = aws_launch_template.app_launch_template.id
  }

  vpc_zone_identifier = [ aws_subnet.first_subnet.id, aws_subnet.second_subnet.id, aws_subnet.third_subnet.id]
  tag {
    key = "Name"
    value = "web_auto_scaling"
    propagate_at_launch = true

  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_attachment" "web_auto_scaling_attachment" {
  
 autoscaling_group_name = aws_autoscaling_group.web_auto_scaling.id
 lb_target_group_arn = aws_lb_target_group.web-balancer-target-gp.arn
}


#create a s3 bucket for aws macie example
resource "aws_s3_bucket" "gov_data_bucket" {
  bucket = var.bucketname
}

#who owns bucket
resource "aws_s3_bucket_ownership_controls" "gov_data_bucket_oc" {
  bucket = aws_s3_bucket.gov_data_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#block public access to my bucket
resource "aws_s3_bucket_public_access_block" "gov_data_bucket_block_access" {
  bucket = aws_s3_bucket.gov_data_bucket.id

  block_public_acls       = var.BLOCK_PUBLIC_ACCESS_TO_BUCKET #true
  block_public_policy     = var.BLOCK_PUBLIC_ACCESS_TO_BUCKET
  ignore_public_acls      = var.BLOCK_PUBLIC_ACCESS_TO_BUCKET
  restrict_public_buckets = var.BLOCK_PUBLIC_ACCESS_TO_BUCKET
} 

resource "aws_s3_bucket_acl" "gov_data_bucket_acl" {

  depends_on = [
    aws_s3_bucket_ownership_controls.gov_data_bucket_oc,
    aws_s3_bucket_public_access_block.gov_data_bucket_block_access,
  ]

  bucket = aws_s3_bucket.gov_data_bucket.id
  #can be read by the bucket owner
   acl    = var.ACL

}

#upload file to bucket with no sensitive data
resource "aws_s3_object" "data" {
  bucket = aws_s3_bucket.gov_data_bucket.id
  key = "data.txt"
  source = "data.txt"
  acl = var.ACL
}

#upload file to bucket with non sensitive data 
resource "aws_s3_object" "sensitive" {
  bucket = aws_s3_bucket.gov_data_bucket.id
  key = "emp_details.csv"
  source = "emp_details.csv"
  acl = var.ACL
}

#upload file to bucket with sensitive data 
resource "aws_s3_object" "keys" {
  bucket = aws_s3_bucket.gov_data_bucket.id
  key = "keys.txt"
  source = "keys.txt"
  acl = var.ACL
}

















