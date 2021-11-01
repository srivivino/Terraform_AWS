key_name            = "demo"
region              = "us-east-1"
vpc_cidr_block      = "10.0.0.0/16"
pub_subnet_cidrs    = ["10.0.1.0/24", "10.0.3.0/24"]
pvt_subnet_cidrs    = ["10.0.2.0/24", "10.0.4.0/24"]
rds_instance_class  = "db.t2.micro"
rds_name = "mysql_rds_dev"
rds_username = "mysql_terraform_dev"
web_ami = "ami-e0ba5c83233443d"
web_instance = "t2.medium"