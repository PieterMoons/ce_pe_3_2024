/*
Variables that will be used in our dev environment
*/

##################################################
################### General ######################
##################################################

################ admin user ######################

admin_id = "motoyo"

################# Region #########################

region = "us-east-1"


################# project #########################

project     = "ce-pe-3"
environment = terraform.workspace



##################################################
################### VPC ##########################
##################################################


azs                   = ["us-east-1a", "us-east-1b"]
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
database_subnet_cidrs = ["10.0.100.0/24", "10.0.200.0/24"]


##################################################
################### Database Tier ################
##################################################


db_allocated_storage = 20
db_storage_type      = "gp2"
db_engine            = "mysql"
db_engine_version    = "8.0.35"
db_instance_class    = "db.t3.micro"
db_identifier        = "db-ce-crud-app-r0785469-instance"
db_name              = "db-ce-crud-app-r0785469--database"



##################################################
################### App Tier #####################
##################################################


untagged_images   = 10
minimum_instances = 1
maximum_instances = 5
container_cpu     = 512
container_memory  = 1024








##################################################
################### Web Tier #####################
##################################################

cloudflare_domain = "motoyohosting.uk"


##################EC2 configuration###############



