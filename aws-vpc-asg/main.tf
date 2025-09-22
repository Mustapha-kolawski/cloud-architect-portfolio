
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" { region = var.region }

variable "region" { type = string, default = "us-east-1" }
variable "prefix" { type = string, default = "ms-asg" }

data "aws_availability_zones" "azs" {}

resource "aws_vpc" "this" {
  cidr_block = "10.20.0.0/16"
  tags = { Name = "${var.prefix}-vpc", env = "lab" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.azs.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.this.id }

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route { cidr_block = "0.0.0.0/0" , gateway_id = aws_internet_gateway.igw.id }
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name   = "${var.prefix}-web-sg"
  vpc_id = aws_vpc.this.id
  ingress { from_port=80 to_port=80 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  egress  { from_port=0  to_port=0  protocol="-1"   cidr_blocks=["0.0.0.0/0"] }
}

data "aws_ami" "al" {
  most_recent = true
  owners      = ["137112412989"]
  filter { name="name" values=["al2023-ami-*-x86_64"] }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.prefix}-lt-"
  image_id      = data.aws_ami.al.id
  instance_type = "t3.micro"
  user_data     = base64encode(<<-EOT
    #!/bin/bash
    dnf install -y httpd
    echo "Hello from $(hostname)" > /var/www/html/index.html
    systemctl enable --now httpd
  EOT)
  network_interfaces { security_groups = [aws_security_group.web.id] }
}

resource "aws_lb" "alb" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.public : s.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action { type = "forward" , target_group_arn = aws_lb_target_group.tg.arn }
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.prefix}-asg"
  min_size            = 2
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = [for s in aws_subnet.public : s.id]
  target_group_arns   = [aws_lb_target_group.tg.arn]
  launch_template { id = aws_launch_template.lt.id , version = "$Latest" }
}
