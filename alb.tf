# variable for alb sg parameter
variable "sg_params" {
  type    = map(any)
  default = { "Allow https inbound traffic for ALB" : [443, "0.0.0.0/0"] }

}

# create alb security group 
resource "aws_security_group" "Alb-sg" {
  name = "ALB-sg"

  vpc_id = aws_vpc.my-vpc.id
  dynamic "ingress" {
    for_each = var.sg_params

    content {
      description = ingress.key
      from_port   = ingress.value[0]
      to_port     = ingress.value[0]
      protocol    = "tcp"
      cidr_blocks = [ingress.value[1]]

    }

  }


  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.instance-sg.id]
  }

  tags = {
    Name = "ALB-Sg"
  }
}

# create security for the registered instance to receive traffic only from alb
resource "aws_security_group" "instance-sg" {
  name = "instance-sg"

  vpc_id = aws_vpc.my-vpc.id
  ingress {

    description = "security group for ec2 instances in private subnet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Instance-Sg"
  }
}

# create an application load balancer
resource "aws_lb" "ALB" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Alb-sg.id]

  subnets = [for subnet in aws_subnet.public-subnets[*] : subnet.id]

  enable_deletion_protection = false

  tags = {
    Name = "Demo-Alb"
  }
}


/*resource "aws_lb_listener" "ALB-listener" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    #type = "redirect"
    type             = "forward"
    target_group_arn = aws_lb_target_group.first-tg.arn


    #redirect {
      #port        = "443"
      #protocol    = "HTTPS"
      #status_code = "HTTP_301"
    #}
  }
}*/


# create an alb listener to listen on https port 443
resource "aws_lb_listener" "ELB-listener" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.my-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.first-tg.arn
  }

  depends_on = [aws_acm_certificate.my-cert]
}


# create a target group to receive traffic on http port 80
resource "aws_lb_target_group" "first-tg" {
  name        = "first-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.my-vpc.id
}


