# ─────────────────────────────────────────
# PROVIDER
# ─────────────────────────────────────────
provider "aws" {
  region = "ap-southeast-2"
}

# ─────────────────────────────────────────
# VARIABLES
# ─────────────────────────────────────────
variable "account_id" {
  description = "280428843100"
  type        = string
}

locals {
  ecr_base = "${var.account_id}.dkr.ecr.ap-southeast-2.amazonaws.com"
}

# ─────────────────────────────────────────
# NETWORKING — use default VPC (simplest!)
# ─────────────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ─────────────────────────────────────────
# SECURITY GROUP
# ─────────────────────────────────────────
resource "aws_security_group" "ecs_sg" {
  name   = "canvas-ecs-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 65535
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

# ─────────────────────────────────────────
# ECS CLUSTER
# ─────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "canvas-art-cluster"
}

# ─────────────────────────────────────────
# IAM ROLE FOR ECS TASKS
# ─────────────────────────────────────────
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "canvas-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─────────────────────────────────────────
# USER SERVICE
# ─────────────────────────────────────────
resource "aws_ecs_task_definition" "user_service" {
  family                   = "user-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "user-service"
    image = "${local.ecr_base}/user-service:latest"
    portMappings = [{
      containerPort = 3001
      protocol      = "tcp"
    }]
    environment = [
      { name = "PORT",       value = "3001" },
      { name = "JWT_SECRET", value = "canvas_secret_key_2026" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/user-service"
        awslogs-region        = "ap-southeast-2"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/ecs/user-service"
  retention_in_days = 7
}

resource "aws_ecs_service" "user_service" {
  name            = "user-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

# ─────────────────────────────────────────
# PRODUCT SERVICE
# ─────────────────────────────────────────
resource "aws_ecs_task_definition" "product_service" {
  family                   = "product-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "product-service"
    image = "${local.ecr_base}/product-service:latest"
    portMappings = [{
      containerPort = 3002
      protocol      = "tcp"
    }]
    environment = [
      { name = "PORT", value = "3002" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/product-service"
        awslogs-region        = "ap-southeast-2"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "product_service" {
  name              = "/ecs/product-service"
  retention_in_days = 7
}

resource "aws_ecs_service" "product_service" {
  name            = "product-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.product_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

# ─────────────────────────────────────────
# ORDER SERVICE
# ─────────────────────────────────────────
resource "aws_ecs_task_definition" "order_service" {
  family                   = "order-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "order-service"
    image = "${local.ecr_base}/order-service:latest"
    portMappings = [{
      containerPort = 3003
      protocol      = "tcp"
    }]
    environment = [
      { name = "PORT", value = "3003" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/order-service"
        awslogs-region        = "ap-southeast-2"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/ecs/order-service"
  retention_in_days = 7
}

resource "aws_ecs_service" "order_service" {
  name            = "order-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

# ─────────────────────────────────────────
# OUTPUTS
# ─────────────────────────────────────────
output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "next_step" {
  value = "Go to AWS Console → ECS → canvas-art-cluster → click each service → Tasks → click task → find Public IP"
}