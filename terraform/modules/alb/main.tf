resource "aws_lb" "main" {
  name               = "aether-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.public_subnet_ids 

  tags = {
    Name = "${var.environment}-aether-alb"
  }
}

# Target Group for Backend ECS services
resource "aws_lb_target_group" "app" {
    name    =   "${var.environment}-aether-tg"
    port    =   80
    protocol    =   "HTTP"
    vpc_id      =   var.vpc_id
    target_type =   "ip"

    health_check {
        path                ="/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
}

# Listener to ROute INcoming Traffic

resource "aws_lb_listener" "http" {
    load_balancer_arn       =   aws_lb.main.arn 
    port                    =   80
    protocol                =   "HTTP"

    default_action {
        type                    =   "forward"
        target_group_arn        =   aws_lb_target_group.app.arn
    }
}