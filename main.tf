resource "aws_vpc" "rearc_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.rearc_vpc.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.1.0/32"

  tags = {
    "Name" = "rearc-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.rearc_vpc.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.2.0/32"

  tags = {
    "Name" = "rearc-public-subnet-2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.rearc_vpc.id

  tags = {
    "Name" = "Internet-Gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.rearc_vpc.id

  tags = {
    "Name" = "Public-RouteTable"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_association_1" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "public_rt_association_2" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet_2.id
}

resource "aws_security_group" "sg" {

  name        = "CustomSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.rearc_vpc.id
  egress = [
    {
      description      = "for all outgoing traffics"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  ingress = [
    {
      description = "Allow inbound traffic"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description = "Allow inbound ssh"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  tags = {
    Name = "AWS security group block"
  }

}

resource "aws_instance" "instance" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.sg.id, ]
  key_name        = "rearc"
  user_data       = "bootstrap.sh"

  tags = {
    "Name" = "rearc-instance"
  }

}
data "aws_availability_zones" "azs" {}

resource "aws_lb_target_group" "tg" {
  name        = "TargetGroup"
  port        = 3000
  target_type = "instance"
  protocol    = "tcp"
  vpc_id      = aws_vpc.rearc_vpc.id
}

resource "aws_alb_target_group_attachment" "tgattachment" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.instance.id
}

resource "aws_lb" "lb" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id, ]
  subnets            = flatten([aws_subnet.public_subnet_1.*.id, aws_subnet.public_subnet_2.*.id])
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "3000"
  protocol          = "tcp"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

#   default_action {
#     type = "redirect"

#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
}
# resource "aws_lb_listener_rule" "static" {
#   listener_arn = aws_lb_listener.front_end.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tg.arn

#   }
# }