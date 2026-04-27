# Target Group -- sends traffic to instances --> Fargate Instances
resource "aws_lb_target_group" "taskoverflow" {
    name = "taskoverflow"
    port = 6400
    protocol = "HTTP"
    vpc_id = aws_security_group.taskoverflow.vpc_id
    target_type = "ip"

    health_check {
        path = "/api/v1/health"
        port = "6400"
        protocol = "HTTP"
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 5
        interval = 10
    }
}

# External Application Load Balancer — publicly accessible, routes traffic to target group
resource "aws_lb" "taskoverflow" {
    name = "taskoverflow"
    internal = false                            # false = internet-facing
    load_balancer_type = "application"          # Layer 7 (HTTP/HTTPS)
    subnets = data.aws_subnets.private.ids      # subnets the ALB spans across
    security_groups = [aws_security_group.taskoverflow_lb.id]
}

# Firewall controlling what traffic can reach to ALB
resource "aws_security_group" "taskoverflow_lb" {
    name = "taskoverflow_lb"
    description = "TaskOverFlow Load Balancer Security Group"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # allow HTTP from anywhere (internet)
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"                 # -1 = all protocols
        cidr_blocks = ["0.0.0.0/0"]     # allow outbound to target group nodes
    }

    tags = {
        Name = "taskoverflow_lb_security_group"
    }
}

# Listener - entry point for the ALB, forwards incoming HTTP traffic to the target group
resource "aws_lb_listener" "taskoverflow" {
    load_balancer_arn = aws_lb.taskoverflow.arn     # attach to our ALB
    port = "80"
    protocol = "HTTP"

    default_action {
        type = "forward"        # forward to target group (not redirect/fixed-response)
        target_group_arn = aws_lb_target_group.taskoverflow.arn
    }
}

# Output the ALB's DNS name after `terraform apply` — use this to send requests to the service
output "taskoverflow_dns_name" {
    value = aws_lb.taskoverflow.dns_name
    description = "DNS name of the TaskOverflow load balancer."
}
