### Web - tier deployment

## TLS configuration

# Uploading the certificates to AWS Credentials Manager, specify the absolute locations in the tfvars file

data "aws_acm_certificate" "cert" {

  domain    = terraform.workspace == "production" ? "www.motoyohosting.uk" : "staging.motoyohosting.uk"
  statuses  = ["ISSUED"]
  types     = ["IMPORTED"]
  key_types = ["RSA_2048", "EC_prime256v1"]

}

#Creation of the internet facing loadbalancer located in both Public Subnets

resource "aws_lb" "elb" {
  name               = "${local.prefix}-if-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internet_alb_sg.id]

  subnets = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-if-alb" })
  )

}

# Standard target group listening on port 80 where the containers can register, health checks will be performed before traffic is routed to the containers

resource "aws_lb_target_group" "ecs" {
  name        = "${local.prefix}-if-alb-tg-ecs"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 300
    path                = "/"
    timeout             = 60
    matcher             = "200"
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }


  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-if-alb-tg-ecs" })
  )

}

# The ALB will listen on port 80 & 443 to forward traffic to the healthy containers that are registered in the target group
# When traffic hits port 80 it will be redirected to port 443

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.elb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-if-alb-ls-ecs" })
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-if-alb-lis-ecs" })
  )

}



# Create a CNAME record on cloudflare pointing to the DNS name of the internet facing loadbalancer

data "cloudflare_zone" "motoyohosting" {
  name = var.cloudflare_domain
}

resource "cloudflare_record" "cname" {
  zone_id = data.cloudflare_zone.motoyohosting.id
  name    = terraform.workspace == "production" ? "www" : "staging"
  value   = aws_lb.elb.dns_name
  type    = "CNAME"
  proxied = false

}


output "url_application" {
  value = "${cloudflare_record.cname.name}.${var.cloudflare_domain}"
}