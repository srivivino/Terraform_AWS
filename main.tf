terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 3.0"
    }
  }
}

# Configure the Provider ex: aws, azurerm, google
provider "aws" {
    region = "${var.region}"
}

locals {
   vpc_name = "vpc_name-${terraform.workspace}"
   region   = "us-east-1"
   tags     = {
     Owner       = "abc@example.com"
     Environment = "${terraform.workspace}"
  }
}

data "aws_availability_zones" "available" {}

# Create a VPC
resource "aws_vpc" "my-vpc" {
    cidr_block              = "${var.vpc_cidr_block}"
    tags                    = merge(local.tags, {
      Project               = "demo_project-${terraform.workspace}"})
}

# Create public subnet for common resources like NAT Gateway etc.
resource "aws_subnet" "public" {
  count                     = "${length(var.pub_subnet_cidrs)}"
  vpc_id                    = "${aws_vpc.my-vpc.id}"
  availability_zone         = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block                = "${var.pub_subnet_cidrs[count.index]}"

  tags                      = merge(local.tags, {
    Name                    = "public-${count.index}-${terraform.workspace}"})
}

# Create Private Subnet for application and database
resource "aws_subnet" "private" {
  count                     = "${length(var.pvt_subnet_cidrs)}"
  vpc_id                    = "${aws_vpc.my-vpc.id}"
  availability_zone         = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block                = "${var.pvt_subnet_cidrs[count.index]}"

  tags                      = merge(local.tags, {
    Name                    = "private-${count.index}-${terraform.workspace}"})
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id                    = "${aws_vpc.my-vpc.id}"

  tags = merge(local.tags, {
      Name                  = "igw-${terraform.workspace}"})
}

# Create Public Subnet route table
resource "aws_route_table" "pub-rt" {
  vpc_id                    = "${aws_vpc.my-vpc.id}"

  route {
    cidr_block              = "0.0.0.0/0"
    gateway_id              = "${aws_internet_gateway.igw.id}"
  }

  tags = merge(local.tags, {
      Name                  = "pub_rt-${terraform.workspace}"})
}

# Create Web Subnet association with Web route table
resource "aws_route_table_association" "public" {
  count                     = "${length(var.pub_subnet_cidrs)}"
  subnet_id                 = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id            = "${aws_route_table.pub-rt.id}"
}

# Create Elastic IP for NAT gateway
resource "aws_eip" "nat_eip" {
  vpc                       = true

  tags = merge(local.tags, {
      Name                  = "ngw-ip-${terraform.workspace}"})
}

# Create an NAT gateway to give our private subnets to access to the outside world
resource "aws_nat_gateway" "default" {
  allocation_id             = "${aws_eip.nat_eip.id}"
  subnet_id                 = "${element(aws_subnet.public.*.id, 0)}"

  tags = {
    Name                    = "${local.vpc_name}"
  }
}

# Create Route tables for application
resource "aws_route_table" "pvt-rt" {
  vpc_id                    = "${aws_vpc.my-vpc.id}"

  route {
    cidr_block              = "0.0.0.0/0"
    gateway_id              = "${aws_nat_gateway.default.id}"
  }

  tags = merge(local.tags, {
      Name                  = "pvt_rt-${terraform.workspace}"})
}

resource "aws_route_table_association" "private" {
  count                     = "${length(var.pvt_subnet_cidrs)}"
  subnet_id                 = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id            = "${aws_route_table.pvt-rt.id}"
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name                      = "${var.rds_subnet_name}"
  subnet_ids                = ["${aws_subnet.private.*.id}"]
}

# Create security group for webservers
resource "aws_security_group" "webserver_sg" {
  name                      = "allow_http"
  description               = "Allow http inbound traffic"
  vpc_id                    = "${aws_vpc.my-vpc.id}"

  ingress {
    from_port               = 80
    to_port                 = 80
    protocol                = "tcp"
    cidr_blocks             = ["0.0.0.0/0"]
  }

  egress {
    from_port               = 0
    to_port                 = 0
    protocol                = "-1"
    cidr_blocks             = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
      Name                  = "${var.websg_name}-${terraform.workspace}"})
}

# Create Database Security Group
resource "aws_security_group" "database-sg" {
  name                      = "Database-SG"
  description               = "Allow inbound traffic from application layer"
  vpc_id                    = "${aws_vpc.my-vpc.id}"

  ingress {
    description             = "Allow traffic from application layer"
    from_port               = 3306
    to_port                 = 3306
    protocol                = "tcp"
    security_groups         = ["${aws_security_group.webserver_sg.id}"]
  }

  egress {
    from_port               = 32768
    to_port                 = 65535
    protocol                = "tcp"
    cidr_blocks             = ["0.0.0.0/0"]
  }

  tags = {
    Name                    = "Database-SG"
  }
}

# Create RDS instance 
resource "aws_db_instance" "rds" {
  allocated_storage         = "${var.rds_storage}"
  engine                    = "${var.rds_engine}"
  instance_class            = "${var.rds_instance_class}"
  name                      = "${var.rds_name}"
  username                  = "${var.rds_username}"
  password                  = "${var.rds_password}"
  db_subnet_group_name      = "${var.rds_subnet_name}"
  depends_on                = [aws_db_subnet_group.rds_subnet_group]
}

# # Create EC2 instances for webservers
# resource "aws_instance" "webservers" {
#   count           = "${length(var.pub_subnet_cidrs)}"
#   ami             = "${var.web_ami}"
#   instance_type   = "${var.web_instance}"
#   security_groups = ["${aws_security_group.webserver_sg.id}"]
#   subnet_id       = "${element(aws_subnet.public.*.id,count.index)}"
# }

resource "aws_launch_configuration" "asg-launch-config" {
  image_id                  = "${var.web_ami}"
  instance_type             = "${var.web_instance}"
  security_groups           = ["${aws_security_group.webserver_sg.id}"]
#   iam_instance_profile = "Role_1"
  
  user_data = <<-EOF
              #!/bin/bash
              apt install nginx -y
              echo "Hello world!...." > /usr/share/nginx/html/index.html
              service nginx restart
              EOF
  lifecycle {
    create_before_destroy    = true
  }
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration      = "${aws_launch_configuration.asg-launch-config.id}"
  availability_zones        = "${data.aws_availability_zones.available.names}"
  min_size                  = 2
  max_size                  = 5

  load_balancers            = ["${aws_lb.weblb.name}"]
  health_check_type         = "ELB"

  tag {
    key                     = "Name"
    value                   = "asg-${terraform.workspace}"
    propagate_at_launch     = true
  }
}

# Creating application load balancer
resource "aws_lb" "weblb" {
  name                      = "${var.lb_name}"
  load_balancer_type        = "application"
  security_groups           = ["${aws_security_group.webserver_sg.id}"]
  subnets                   = ["${aws_subnet.public.*.id}"]

  tags = {
    Name                    = "${var.lb_name}"
  }
}

# Creating load balancer target group
resource "aws_lb_target_group" "alb_group" {
  name                  = "${var.tg_name}"
  port                  = "${var.tg_port}"
  protocol              = "${var.tg_protocol}"
  vpc_id                = "${aws_vpc.my-vpc.id}"
}

#Creating listeners
resource "aws_lb_listener" "webserver-lb" {
  load_balancer_arn     = "${aws_lb.weblb.arn}"
  port                  = "${var.listener_port}"
  protocol              = "${var.listener_protocol}"

  # certificate_arn  = "${var.certificate_arn_user}"
  default_action {
    target_group_arn    = "${aws_lb_target_group.alb_group.arn}"
    type                = "forward"
  }
}

#Creating listener rules
resource "aws_lb_listener_rule" "allow_all" {
  listener_arn          = "${aws_lb_listener.webserver-lb.arn}"

  action {
    type                = "forward"
    target_group_arn    = "${aws_lb_target_group.alb_group.arn}"
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }

}

resource "aws_s3_bucket" "s3_bucket-1" {
  bucket                = "my-tf-test-bucket"
  acl                   = "private"

  tags = {
    Name                = "s3_bucket-1"
    Environment         = "${terraform.workspace}"
  }
}

output "lb_dns_name" {
  description           = "The DNS name of the load balancer"
  value                 = "${aws_lb.weblb.dns_name}"
}