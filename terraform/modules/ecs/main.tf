# 1. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-aether-cluster"
}

# 2. ECS Task Definition (The Blueprint)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-aether-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# 3. ECS Service (Running and Managing Tasks)
resource "aws_ecs_service" "main" {
  name            = "${var.environment}-aether-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # Network configuration using your private subnets and security groups
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = var.security_groups
    assign_public_ip = false # Private tasks do not need public IPs
  }

  # Hooking up to the ALB Target Group we created earlier
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = 80
  }

  depends_on = [var.alb_listener_listener_dependency]
}