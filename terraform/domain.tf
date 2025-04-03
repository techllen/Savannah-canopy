# -----------------------------------------------------------------------------------------------------------------------
# Adding custom request layer
# -----------------------------------------------------------------------------------------------------------------------
# VPC and Subnets
# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
#
#   tags = {
#     Name = "main-vpc"
#   }
# }
#
# resource "aws_subnet" "public" {
#   count             = 2
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.${count.index}.0/24"
#   availability_zone = data.aws_availability_zones.available.names[count.index]
#
#   tags = {
#     Name = "Public Subnet ${count.index + 1}"
#   }
# }

# # ECS Cluster
# resource "aws_ecs_cluster" "main" {
#   name = "main-cluster"
# }

# ECS Task Definition
# resource "aws_ecs_task_definition" "app" {
#   family                   = "app-task"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "256"
#   memory                   = "512"
#
#   container_definitions = jsonencode([{
#     name  = "app"
#     image = "your-docker-image:tag"
#     portMappings = [{
#       containerPort = 8080
#       hostPort      = 8080
#     }]
#   }])
# }

# ALB
# resource "aws_lb" "main" {
#   name               = "main-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb.id]
#   subnets            = aws_subnet.public[*].id
# }

# resource "aws_lb_target_group" "app" {
#   name        = "app-tg"
#   port        = 8080
#   protocol    = "HTTP"
#   vpc_id      = aws_vpc.main.id
#   target_type = "ip"
#
#   health_check {
#     path = "/"
#   }
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = "80"
#   protocol          = "HTTP"
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
# }

# ECS Service
# resource "aws_ecs_service" "app" {
#   name            = "app-service"
#   cluster         = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.app.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"
#
#   network_configuration {
#     subnets         = aws_subnet.public[*].id
#     security_groups = [aws_security_group.ecs_tasks.id]
#   }
#
#   load_balancer {
#     target_group_arn = aws_lb_target_group.app.arn
#     container_name   = "app"
#     container_port   = 8080
#   }
# }

# Route 53
# resource "aws_route53_zone" "main" {
#   name = "savannah-canopy.com"
# }
#
# resource "aws_route53_record" "www" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "www.savannah-canopy.com"
#   type    = "A"
#
#   alias {
#     name                   = aws_lb.main.dns_name
#     zone_id                = aws_lb.main.zone_id
#     evaluate_target_health = true
#   }
# }

# Security Groups
# resource "aws_security_group" "alb" {
#   name        = "alb-sg"
#   description = "ALB Security Group"
#   vpc_id      = aws_vpc.main.id
#
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "ecs_tasks" {
#   name        = "ecs-tasks-sg"
#   description = "ECS Tasks Security Group"
#   vpc_id      = aws_vpc.main.id
#
#   ingress {
#     from_port       = 8080
#     to_port         = 8080
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb.id]
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
#
# # Data source for availability zones
# data "aws_availability_zones" "available" {}
