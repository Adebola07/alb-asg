resource "aws_launch_template" "tg-1" {
  name = "Tg-1_launch_template"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
    }
  }

  ebs_optimized = true

  image_id = "ami-02c21308fed24a8ab"

  instance_type = "t2.micro"

  key_name = "Demo"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.instance-sg.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Demo-instance-profile"
    }
  }

  user_data = filebase64("exec-script.sh")
}

resource "aws_ebs_encryption_by_default" "encrypt" {
  enabled = true
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = aws_subnet.private-subnets[*].id
  health_check_type   = "ELB"
  target_group_arns   = [aws_lb_target_group.first-tg.arn]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  launch_template {
    id      = aws_launch_template.tg-1.id
    version = "$Latest"
  }
  depends_on = [aws_lb.ALB]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale up poliicy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_description   = "Watch for upper threshold alarm"
  alarm_name          = "Upper threshols alarm"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "40"
  evaluation_periods  = "2"
  period              = "120"
  statistic           = "Average"
  actions_enabled     = true
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale up poliicy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_description   = "Watch for upper threshold alarm"
  alarm_name          = "Upper threshols alarm"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "5"
  evaluation_periods  = "2"
  period              = "120"
  statistic           = "Average"
  actions_enabled     = true
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

}
