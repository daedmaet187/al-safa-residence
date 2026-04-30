locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ECR Repository
resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-api"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = local.name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = local.name_prefix
    Project     = var.project_name
    Environment = var.environment
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.name_prefix}-api"
  retention_in_days = 30

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Role: ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_secrets_access" {
  name = "${local.name_prefix}-secrets-access"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [var.secret_arn]
      }
    ]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "api" {
  family                   = "${local.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name  = "api"
      image = "${aws_ecr_repository.api.repository_url}:latest"
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${var.secret_arn}:DATABASE_URL::"
        },
        {
          name      = "JWT_ACCESS_SECRET"
          valueFrom = "${var.secret_arn}:JWT_ACCESS_SECRET::"
        },
        {
          name      = "JWT_REFRESH_SECRET"
          valueFrom = "${var.secret_arn}:JWT_REFRESH_SECRET::"
        },
        {
          name      = "FCM_SERVER_KEY"
          valueFrom = "${var.secret_arn}:FCM_SERVER_KEY::"
        },
        {
          name      = "S3_BUCKET_NAME"
          valueFrom = "${var.secret_arn}:S3_BUCKET_NAME::"
        },
        {
          name      = "CLOUDFRONT_URL"
          valueFrom = "${var.secret_arn}:CLOUDFRONT_URL::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.name_prefix}-api"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      essential = true
    }
  ])

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ALB
resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "${local.name_prefix}-alb"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ALB Target Group
resource "aws_lb_target_group" "api" {
  name        = "alsafa-prod-api-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ACM Certificate for API domain (eu-central-1)
resource "aws_acm_certificate" "api" {
  domain_name       = "safa-api.stuff187.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "safa-api.stuff187.com"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ALB Listener: HTTP → HTTPS redirect
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener: HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.api.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  depends_on = [aws_acm_certificate.api]
}

# ECS Service
resource "aws_ecs_service" "api" {
  name            = "${local.name_prefix}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.https,
    aws_iam_role_policy_attachment.ecs_task_execution_policy,
  ]

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
