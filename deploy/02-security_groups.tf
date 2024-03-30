
################# Security Groups #########################

#Security group for the internet-facing load balancer:

#Security group 

resource "aws_security_group" "internet_alb_sg" {
  name        = "${local.prefix}-internet-alb-sg"
  description = "Security group for internet facing loadbalancer"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-internet-alb-sg" })
  )


}


#Rules that allows incoming connections on port 80/443 source --> anywhere

resource "aws_vpc_security_group_ingress_rule" "internet_alb_sg_rule_1" {
  security_group_id = aws_security_group.internet_alb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}


resource "aws_vpc_security_group_ingress_rule" "internet_alb_sg_rule_2" {
  security_group_id = aws_security_group.internet_alb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

# Outbound rule that allows all trafic to all destinations
resource "aws_vpc_security_group_egress_rule" "internet_alb_sg_rule_3" {
  security_group_id = aws_security_group.internet_alb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1

}


#Security group for the App-tier where the containers will be deployed. We only allow HTTP traffic coming from the internet facing load balancer. 


resource "aws_security_group" "app_tier_sg" {
  name        = "${local.prefix}-app-tier-sg"
  description = "Security group for the containers in the application tier"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-app-tier-sg" })
  )

}

#Rules that allows incoming connections on port 80/443 source --> aws_security_group.internet_lb_sg.id

resource "aws_vpc_security_group_ingress_rule" "app_tier_sg_rule_1" {
  security_group_id = aws_security_group.app_tier_sg.id

  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
  referenced_security_group_id = aws_security_group.internet_alb_sg.id

}


resource "aws_vpc_security_group_ingress_rule" "app_tier_sg_rule_3" {
  security_group_id = aws_security_group.app_tier_sg.id

  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
  referenced_security_group_id = aws_security_group.bastion_host_sg.id

}

# Outbound rule that allows all trafic to all destinations

resource "aws_vpc_security_group_egress_rule" "app_tier_sg_rule_2" {
  security_group_id = aws_security_group.app_tier_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1

}

#Security group for the database tier, allowing incoming connections from the app-tier

resource "aws_security_group" "db_tier_sg" {
  name        = "${local.prefix}-db-tier-sg"
  description = "Security group for database tier"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-db-tier-sg" })
  )

}

#Rules that allows incoming connections on port 3306 source --> aws_security_group.app_tier_sg.id

resource "aws_vpc_security_group_ingress_rule" "db_tier_sg_rule_1" {
  security_group_id = aws_security_group.db_tier_sg.id

  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.app_tier_sg.id

}

resource "aws_vpc_security_group_ingress_rule" "db_tier_sg_rule_3" {
  security_group_id = aws_security_group.db_tier_sg.id

  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.bastion_host_sg.id

}

# Outbound rule that allows all trafic to all destinations

resource "aws_vpc_security_group_egress_rule" "db_tier_sg_rule_2" {
  security_group_id = aws_security_group.db_tier_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1

}



#Security Group for bastion host allowing only traffic on port 22

resource "aws_security_group" "bastion_host_sg" {
  name        = "${local.prefix}-bastion-host-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-bastion-host-sg" })
  )

}

#Rule only allowing inbound SSH connections from the public internet

resource "aws_vpc_security_group_ingress_rule" "bastion_host_sg_rule_1" {
  security_group_id = aws_security_group.bastion_host_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}


# Outbound rule that allows all trafic to all destinations

resource "aws_vpc_security_group_egress_rule" "ibastion_host_sg_rule_3" {
  security_group_id = aws_security_group.bastion_host_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1

}
