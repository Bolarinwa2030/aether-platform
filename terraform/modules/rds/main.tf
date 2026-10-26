# Database subnet group (RDS across private subnet)
resource "aws_db_subnet_group" "main" {
    name    =   "${var.environment}-aether-db-subnet-group"
    subnet_ids  =   var.private_subnet_ids

    tags    =   {
        Name    = "${var.environment}-aether-db-subnet-group"
    }
}

# RDS Database instance
resource "aws_db_instance" "main" {
    identifier          = "${var.environment}-aether-db"
    engine              =   "postgres"
    engine_version      =   "15.4"
    instance_class      =   "db.t3.micro"
    allocated_storage   =   20
    max_allocated_storage   =   100
    db_name             =   "aetherdb"
    username            =   var.db_username
    password            =   var.db_password
    db_subnet_group_name    =   aws_db_subnet_group.main.name 
    vpc_security_group_ids  =   var.security_groups 
    skip_final_snapshot     =   true
}
