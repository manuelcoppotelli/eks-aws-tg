locals {
  database_name = format("%s-postgresql", var.environment)
}

resource "random_password" "postgresql" {
  length  = 26
  special = false
}

data "aws_iam_policy_document" "rds_monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["monitoring.rds.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name_prefix        = "rds-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume.json
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_enhanced" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = format("arn:%s:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole", local.aws_partition)
}

resource "aws_db_subnet_group" "data" {
  name       = format("%s-data", var.environment)
  subnet_ids = values(module.subnet_data.ids)
}

data "aws_kms_key" "rds" {
  key_id = "alias/aws/rds"
}

resource "aws_rds_cluster_parameter_group" "aurora_postgresql_14" {
  name        = format("%s-aurora-postgresql14", var.environment)
  family      = "aurora-postgresql14"
  description = "RDS cluster parameter group for aurora postgresql 14"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "aurora_postgresql_14" {
  name        = format("%s-aurora-postgresql14", var.environment)
  family      = "aurora-postgresql14"
  description = "RDS parameter group for aurora postgresql 14"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "postgresql" {
  name_prefix            = format("%s-", local.database_name)
  description            = "Communication to/from postgresql"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = true
}

resource "aws_vpc_security_group_ingress_rule" "postgresql_in_backend" {
  security_group_id = aws_security_group.postgresql.id

  description                  = "Allow connection from cluster nodes"
  referenced_security_group_id = aws_security_group.karpenter_node.id
  from_port                    = aws_rds_cluster.postgresql.port
  to_port                      = aws_rds_cluster.postgresql.port
  ip_protocol                  = "tcp"
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier   = local.database_name
  db_subnet_group_name = aws_db_subnet_group.data.name
  engine               = "aurora-postgresql"

  master_username = "postgresql"
  master_password = random_password.postgresql.result

  kms_key_id                      = data.aws_kms_key.rds.arn
  storage_encrypted               = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_postgresql_14.name
  backup_retention_period         = var.database.backup_retention_period
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = var.database.log.exports
  engine_version                  = "14.6"
  engine_mode                     = "provisioned"
  preferred_backup_window         = var.database.backup_window
  vpc_security_group_ids          = [aws_security_group.postgresql.id]
  final_snapshot_identifier       = format("%s-final", local.database_name)
}

resource "aws_rds_cluster_instance" "postgresql" {
  count = 1

  identifier                   = format("%s-%d", local.database_name, count.index)
  cluster_identifier           = aws_rds_cluster.postgresql.id
  instance_class               = var.database.instance_class
  engine                       = aws_rds_cluster.postgresql.engine
  engine_version               = aws_rds_cluster.postgresql.engine_version
  db_subnet_group_name         = aws_db_subnet_group.data.name
  db_parameter_group_name      = aws_db_parameter_group.aurora_postgresql_14.name
  publicly_accessible          = "false"
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn
  monitoring_interval          = 60
  preferred_maintenance_window = var.database.maintenance_window
  auto_minor_version_upgrade   = true
}

resource "aws_secretsmanager_secret" "postgresql" {
  name = format("%s-credentials", local.database_name)
}

resource "aws_secretsmanager_secret_version" "postgresql" {
  secret_id = aws_secretsmanager_secret.postgresql.id
  secret_string = jsonencode({
    username            = aws_rds_cluster.postgresql.master_username
    password            = random_password.postgresql.result
    host                = aws_rds_cluster.postgresql.endpoint
    port                = aws_rds_cluster.postgresql.port
    dbClusterIdentifier = aws_rds_cluster.postgresql.cluster_identifier
  })
}

# Log groups will not be created if using a cluster identifier prefix
resource "aws_cloudwatch_log_group" "postgresql" {
  for_each = toset(var.database.log.exports)

  name              = format("/aws/rds/cluster/%s/%s", local.database_name, each.value)
  retention_in_days = var.database.log.retention
}

resource "aws_appautoscaling_target" "postgresql" {
  min_capacity       = var.database.autoscaling.min_capacity
  max_capacity       = var.database.autoscaling.max_capacity
  resource_id        = format("cluster:%s", aws_rds_cluster.postgresql.cluster_identifier)
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"
}

resource "aws_appautoscaling_policy" "postgresql" {
  name               = format("%s-read-replica-count", local.database_name)
  policy_type        = "TargetTrackingScaling"
  resource_id        = format("cluster:%s", aws_rds_cluster.postgresql.cluster_identifier)
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.database.autoscaling.metric_type
    }

    scale_in_cooldown  = var.database.autoscaling.scale_in_cooldown
    scale_out_cooldown = var.database.autoscaling.scale_out_cooldown
    target_value       = var.database.autoscaling.metric_type == "RDSReaderAverageCPUUtilization" ? var.database.autoscaling.target_cpu : var.database.autoscaling.target_connections
  }

  depends_on = [
    aws_appautoscaling_target.postgresql
  ]
}
