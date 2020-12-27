#TODO list:
# * add new az and new subnet so we can run ALB
# * 

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.vpc_name}example_1"
  cidr = "10.0.0.0/16"

  azs                  = ["eu-west-1a", "eu-west-1b"]
  private_subnets      = ["10.0.1.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

}


module "instance_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "user-service-sg"
  description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id      = module.vpc.vpc_id
  
  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "http-8080-tcp",
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "efs_sg" {
  #* EFS Security Group
  
  source = "terraform-aws-modules/security-group/aws"

  name        = "user-service-sg-efs"
  description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id      = module.vpc.vpc_id

  number_of_computed_ingress_with_source_security_group_id = 1
  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "nfs-tcp"
      source_security_group_id = module.instance_sg.this_security_group_id
    }
  ]
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_key_pair" "ec2key" {
  key_name   = var.public_key_name
  public_key = file(var.public_key_path)
}

resource "aws_efs_file_system" "efs" {
  creation_token = "${var.vpc_name}efs"
  encrypted      = true
  tags = {
    Name = "${var.vpc_name}efs"
  }
}

resource "aws_efs_mount_target" "efs_mount" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [module.efs_sg.this_security_group_id]
}

resource "aws_efs_access_point" "efs_access_point" {
  file_system_id = aws_efs_file_system.efs.id
}

#* script to setup the instance
data "template_file" "init" {
  template = file("script.tpl")
  vars = {
    efs_id              = aws_efs_file_system.efs.id
    efs_mount_id        = aws_efs_mount_target.efs_mount.id
    efs_access_point_id = aws_efs_access_point.efs_access_point.id
  }
}


module "auto_scaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "${var.vpc_name}auto_scaling"

  # Launch configuration
  lc_name = "${var.vpc_name}auto_scaling_lc"

  image_id        = var.instance_ami
  instance_type   = var.instance_type
  security_groups = [module.instance_sg.this_security_group_id]

  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "8"
      delete_on_termination = true
    },
  ]


  # Auto scaling group
  asg_name                  = "${var.vpc_name}auto_scaling_lc"
  vpc_zone_identifier       = [module.vpc.public_subnets[0]]
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  user_data                 = data.template_file.init.rendered
  key_name                  = aws_key_pair.ec2key.key_name

  tags = [
    {
      key                 = "Environment"
      value               = "Dev"
      propagate_at_launch = true
    }
  ]

}

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 2.0"

  name = "elb-example"

  subnets         = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_groups = [module.instance_sg.this_security_group_id]
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    }
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 300
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 60
  }
  

}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = module.auto_scaling.this_autoscaling_group_id
  elb                    = module.elb_http.this_elb_id
}

