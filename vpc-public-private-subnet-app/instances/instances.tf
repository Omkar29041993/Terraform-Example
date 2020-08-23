terraform {
    backend "s3" {}
}

data "terraform_remote_state" "network_configuration" {
  backend = "s3"
  config = {
    bucket = "omkar-terraform-test-bucket"
    key    = "infrastructure.tfstate"
    profile= "terrform-user"
    region = "us-east-1"
  }
}

resource "aws_security_group" "ec2-public-security-group" {
    name = "EC2-Public-SG"
    description = "Internet Reaching Access to Security Group"
    vpc_id = data.terraform_remote_state.network_configuration.outputs.vpc_id

    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_security_group" "ec2-private-security-group" {
    name  = "EC2-Private-SG"
    description = "Allow access from public instance only"
    vpc_id = data.terraform_remote_state.network_configuration.outputs.vpc_id

    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
     from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "elb_security_group" {
    name = "ELB-SG"
    description = "ELB-SG"
    vpc_id = data.terraform_remote_state.network_configuration.outputs.vpc_id
    ingress {
      description = "TLS from VPC"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      description = "TLS from VPC"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "EC2_IAM_Role"
  assume_role_policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" :
  [
    {
      "Effect" : "Allow",
      "Principal" : {
        "Service" : ["ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
      },
      "Action" : "sts:AssumeRole"
    }
  ] 
} 
EOF
}

resource "aws_iam_role_policy" "ec2_iam_role_policy" {
  name = "EC2-IAM-POLICY"
  role = aws_iam_role.ec2_iam_role.id
  policy  = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "cloudwatch:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2-IAM-Instance-Profile"
  role = aws_iam_role.ec2_iam_role.name
}

# data "aws_ami" "launch_configuration_ami" {
#   most_recent = true
#   owners = ["self"]
#   filter {
#     name = "owner-alias"
#     values = ["amazon"]
#   }
# }

resource "aws_launch_configuration" "ec2_private_lauch_configurtion" {
  name = "Private-Lauch-Configuration"
  image_id = "ami-0761dd91277e34178"
  instance_type = var.ec2_instance_type
  key_name = var.key_pair_name
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups = [aws_security_group.ec2-private-security-group.id]
  user_data = <<EOF
  #!/bin/bash
    yum update -y
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    echo "<html><body><h1>Hello from Production Backend at instance <b>"$INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html
  EOF
}

resource "aws_launch_configuration" "ec2_public_lauch_configurtion" {
  name = "WebApp-Lauch-Configuration"
  image_id = "ami-0761dd91277e34178"
  instance_type = var.ec2_instance_type
  key_name = var.key_pair_name
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups = [aws_security_group.ec2-public-security-group.id]
  user_data = <<EOF
  #!/bin/bash
    yum update -y
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    echo "<html><body><h1>Hello from Production WebApp at instance <b>"$INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html
  EOF
}

resource "aws_elb" "webapp-load-balancer" {
  name = "Production-WebApp-Load-Balancer"
  internal = false
  security_groups = [aws_security_group.elb_security_group.id]
  subnets = [
    data.terraform_remote_state.network_configuration.outputs.public_subnet1_id,
    data.terraform_remote_state.network_configuration.outputs.public_subnet2_id,
    data.terraform_remote_state.network_configuration.outputs.public_subnet3_id
  ]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 5
    timeout             = 10
    target              = "HTTP:80/index.html"
    interval            = 30
  }
}

resource "aws_elb" "backend-load-balancer" {
  name = "Production-Backend-Load-Balancer"
  internal = false
  security_groups = [aws_security_group.elb_security_group.id]
  subnets = [
    data.terraform_remote_state.network_configuration.outputs.private_subnet1_id,
    data.terraform_remote_state.network_configuration.outputs.private_subnet2_id,
    data.terraform_remote_state.network_configuration.outputs.private_subnet3_id
  ]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 5
    timeout             = 10
    target              = "HTTP:80/index.html"
    interval            = 30
  }
}

resource "aws_autoscaling_group" "ec2_private_autoscaling_group" {
  name = "Production-Backend-Autoscaling-Group"
  vpc_zone_identifier = [
    data.terraform_remote_state.network_configuration.outputs.private_subnet1_id,
    data.terraform_remote_state.network_configuration.outputs.private_subnet2_id,
    data.terraform_remote_state.network_configuration.outputs.private_subnet3_id
  ]
  max_size = var.instance_max_size
  min_size = var.instance_min_size
  launch_configuration = aws_launch_configuration.ec2_private_lauch_configurtion.name
  health_check_type = "ELB"
  load_balancers = [aws_elb.backend-load-balancer.id]
  tag {
    key                 = "Name"
    propagate_at_launch = false
    value               = "Backend-EC2-Instance"
  }

  tag {
    key                 = "Type"
    propagate_at_launch = false
    value               = "Backend"
  }
}

resource "aws_autoscaling_group" "ec2_public_autoscaling_group" {
  name = "Production-WebApp-Autoscaling-Group"
  vpc_zone_identifier = [
    data.terraform_remote_state.network_configuration.outputs.public_subnet1_id,
    data.terraform_remote_state.network_configuration.outputs.public_subnet2_id,
    data.terraform_remote_state.network_configuration.outputs.public_subnet3_id
  ]
  max_size = var.instance_max_size
  min_size = var.instance_min_size
  launch_configuration = aws_launch_configuration.ec2_public_lauch_configurtion.name
  health_check_type = "ELB"
  load_balancers = [aws_elb.webapp-load-balancer.id]
  tag {
    key                 = "Name"
    propagate_at_launch = false
    value               = "WebApp-EC2-Instance"
  }

  tag {
    key                 = "Type"
    propagate_at_launch = false
    value               = "WebApp"
  }
}

resource "aws_autoscaling_policy" "webapp-production-scaling-policy" {
  autoscaling_group_name = aws_autoscaling_group.ec2_public_autoscaling_group.name
  name  = "Production-WebApp-Autoscaling-Policy"
  policy_type = "TargetTrackingScaling"
  min_adjustment_magnitude = 1
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80.0
  }
}

resource "aws_autoscaling_policy" "backend-production-scaling-policy" {
  autoscaling_group_name = aws_autoscaling_group.ec2_private_autoscaling_group.name
  name = "Production-Backend-Autoscaling-Policy"
  policy_type = "TargetTrackingScaling"
  min_adjustment_magnitude = 1
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80.0
  }
}

resource "aws_sns_topic" "webapp_production_autoscaling_alert_topic" {
  display_name = "WebApp-AutoScaling-Topic"
  name         = "WebApp-AutoScaling-Topic"
}

resource "aws_sns_topic_subscription" "webapp_production_autoscaling_sms_subscription" {
  endpoint = "+918793250661"
  protocol = "sms"
  topic_arn = aws_sns_topic.webapp_production_autoscaling_alert_topic.arn
}

resource "aws_autoscaling_notification" "webapp_autoscaling_notification" {
  group_names = [aws_autoscaling_group.ec2_public_autoscaling_group.name]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR"
  ]
  topic_arn = aws_sns_topic.webapp_production_autoscaling_alert_topic.arn
}