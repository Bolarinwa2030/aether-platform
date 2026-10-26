resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-aether-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "${var.environment}-aether-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-aether-db"
  engine         = "postgres"
  engine_version = var.engine_version # major only, e.g. "16"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name                     = "aetherdb"
  username                    = var.db_username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_groups
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period         = var.backup_retention_period
  auto_minor_version_upgrade      = true
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.environment}-aether-db-final"

  tags = { Name = "${var.environment}-aether-db" }
}