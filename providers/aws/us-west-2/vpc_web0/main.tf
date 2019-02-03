# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"

}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.vpc_name}"
  cidr = "10.0.0.0/16"

  azs             = ["${var.availability_zones}"]
  private_subnets = ["10.0.1.0/24","10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24","10.0.102.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "production"
  }
}

resource "aws_key_pair" "helloworld" {
  key_name   = "helloworld"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCNqRoQwBd52bWybx4bTOOvTZWvU0pVs4s8PENeKpSKRAApQ/CMLfKDRkvMs/g0ZZ7bgkRw64Xxk1CiUH+P9Ephpa9KY08quD9F6kICadr9uxr7Xbo595aGeRENgxuOZrcKBL1+bu59qUsykWmdhX8dCc8vH0sLbX9gaDt5x2npDkyXNP69TEKN56q3tj4bd0AwF5E4vH1z4COWHl606jnhap3Z++vDS8OytD+AANPEPUpnA7SkF8rz288tjAmnaILt+1VMJBV3w0LtBqwT88D2CbWUCOinrV9GKWHXlihZ7pIVYXFkdUKaaqFyduHKf/0IO33y8vTCjWYp14MSV/pF"
}

//resource "aws_lb" "helloworld-lb" {
//  name               = "helloworld-lb"
//  internal           = false
//  load_balancer_type = "application"
//  security_groups    = ["${aws_security_group.web0-http-public.id}"]
//  subnets            = ["${module.vpc.public_subnets}"]
//  tags = {
//    Environment = "production"
//  }
//}


resource "aws_elb" "helloworld-elb" {
  name               = "${var.vpc_name}-helloworld"
  security_groups = ["${aws_security_group.web0-http-public.id}"]
  subnets = ["${module.vpc.public_subnets}"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }


  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "${var.vpc_name}-helloworld"
  }
}



resource "aws_autoscaling_group" "helloworld-asg" {
  availability_zones   = []
  name                 = "${var.vpc_name}-helloworld"
  max_size             = "${var.asg_max}"
  min_size             = "${var.asg_min}"
  desired_capacity     = "${var.asg_desired}"
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.web0-lc.name}"
  load_balancers = ["${aws_elb.helloworld-elb.id}"]
//  target_group_arns = ["${aws_lb_target_group.web0-helloworld.arn}"]
  vpc_zone_identifier    = ["${module.vpc.private_subnets}"]
  tag {
    key                 = "Name"
    value               = "${var.vpc_name}-helloworld"
    propagate_at_launch = "true"
  }
}


//resource "aws_lb_target_group" "web0-helloworld" {
//    name           = "${var.vpc_name}-heloworld"
//    vpc_id         = "${module.vpc.vpc_id}"
//    port           = 80
//    protocol       = "HTTP"
//
//}
//
//
//resource "aws_lb_listener" "web" {
//  load_balancer_arn = "${aws_lb.helloworld-lb.arn}"
//  port              = "80"
//  protocol          = "HTTP"
//
//  default_action {
//    type             = "forward"
//    target_group_arn = "${aws_lb_target_group.web0-helloworld.arn}"
//  }
//}

resource "aws_launch_configuration" "web0-lc" {
  name          = "${var.vpc_name}-helloworld"
  image_id      = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${var.instance_type}"
  # Security group
  security_groups = ["${aws_security_group.web0-http-private.id}"]
  user_data       = "${file("userdata.sh")}"
  key_name        = "helloworld"
}


#Ideally ssh should be locked down to a vpn
resource "aws_security_group" "web0-http-public" {
  name        = "web0-http-public"
  description = "Public http and ssh"
  vpc_id = "${module.vpc.vpc_id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web0-http-private" {
  name        = "web0-http-private"
  description = "Private ssh and http"
  vpc_id = "${module.vpc.vpc_id}"


  # HTTP access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.web0-http-public.id}"]
  }
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${aws_security_group.web0-http-public.id}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "bastion" {
  ami           = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "t2.micro"
  key_name        = "helloworld"
  vpc_security_group_ids = ["${aws_security_group.web0-http-public.id}"]
  subnet_id   = "${module.vpc.public_subnets[0]}"
  tags = {
    Name = "bastion"
  }
}