################# Application tier #########################


#Retrieve data source labrole (Needed for the task definition creation)

data "aws_iam_role" "labrole" {
  name = "labrole"
}

output "labrole_id" {
  value = data.aws_iam_role.labrole.arn

}


#retrieve ECR repository url


data "aws_ecr_repository" "crud_app_repo" {
  name = "ce-pe-3-repo-motoyo"
}

#Creation of the ECS cluster

resource "aws_ecs_cluster" "crud_app" {
  name = "${local.prefix}-ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-db-instance" })
  )

}

#Fargate capacity provider

resource "aws_ecs_cluster_capacity_providers" "ecs_web_tier_fargate" {
  cluster_name = aws_ecs_cluster.crud_app.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Task definition that will deploy the container.
# The container definitions json encoded file will configure the environment variables needed for the SQLAlchemy connection to the RDS database
# We will be using the secrets module of AWS, otherwise the secrets are stored in clear.

resource "aws_ecs_task_definition" "crud_app" {
  family                = "${local.prefix}-crud-app"
  container_definitions = <<TASK_DEFINITION
  [
  {
    "portMappings": [
      {
        "hostPort": 80,
        "protocol": "tcp",
        "containerPort": 80
      }
    ],
    "cpu": ${var.container_cpu},
    "environment": [
		{
          "name": "DB_HOST",
          "value": "${aws_db_instance.db_app.address}"
        },
        {
          "name": "DB_NAME",
          "value": "entries"
        }],
    "secrets": [
        {
          "name" : "DB_USERNAME",
          "valueFrom": "${aws_secretsmanager_secret.database_username_secret.arn}:DB_USERNAME::"
        },
        {
          "name": "DB_PASSWORD",
          "valueFrom": "${aws_secretsmanager_secret.database_password_secret.arn}:DB_PASSWORD::"
        }
    ],
    "memory": ${var.container_memory},
    "image": "${var.ecr_image_api}",
    "essential": true,
    "name": "crud-app"
  }
]
TASK_DEFINITION

  network_mode = "awsvpc"
  requires_compatibilities = [
  "FARGATE"]
  memory             = var.container_memory
  cpu                = var.container_cpu
  execution_role_arn = data.aws_iam_role.labrole.arn
  task_role_arn      = data.aws_iam_role.labrole.arn

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-db-instance" })
  )
}

#ECS service that will run the task definition, FARGATE version 1.4 is needed to support secrets injection in the container as env variables

resource "aws_ecs_service" "crud_app" {
  name             = "crud-app"
  cluster          = aws_ecs_cluster.crud_app.id
  task_definition  = aws_ecs_task_definition.crud_app.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  lifecycle {
    ignore_changes = [
    desired_count]
  }

  network_configuration {
    subnets = [
      aws_subnet.private_subnets[0].id,
      aws_subnet.private_subnets[1].id
    ]
    security_groups = [
    aws_security_group.app_tier_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "crud-app"
    container_port   = 80
  }
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ecs-service" })
  )

  depends_on = [aws_db_instance.db_app]
}

#Autoscaling group for the ecs service;  the target tracking scaling type

resource "aws_appautoscaling_target" "asg_target" {
  max_capacity       = var.maximum_instances
  min_capacity       = var.minimum_instances
  resource_id        = "service/${aws_ecs_cluster.crud_app.name}/${aws_ecs_service.crud_app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"


  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-asg-target" })
  )
}

# The autoscaling policy will define when other instances of the container are launched
# In this case --> Memory 80% or CPU 60%

resource "aws_appautoscaling_policy" "asg_memory" {
  name               = "${local.prefix}-asg-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.asg_target.resource_id
  scalable_dimension = aws_appautoscaling_target.asg_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }

}

resource "aws_appautoscaling_policy" "asg_cpu" {
  name               = "${local.prefix}-asg-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.asg_target.resource_id
  scalable_dimension = aws_appautoscaling_target.asg_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}

