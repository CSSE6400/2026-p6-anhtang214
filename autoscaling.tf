resource "aws_appautoscaling_target" "taskoverflow" {
    max_capacity = 4                                    # scale out up to 4 tasks
    min_capacity = 1                                    # always keep at least 1 task running
    resource_id = "service/taskoverflow/taskoverflow"   # cluster/service
    scalable_dimension = "ecs:service:DesiredCount"     # what we're scaling (task count)
    service_namespace = "ecs"

    depends_on = [ aws_ecs_service.taskoverflow ]       # ECS service must exist first
}

# Auto-scaling policy - scales task count up/down based on average CPU usage
resource "aws_appautoscaling_policy" "taskoverflow-cpu" {
    name = "taskoverflow-cpu"
    policy_type = "TargetTrackingScaling"       # auto-adjusts to maintain target metric
    resource_id = aws_appautoscaling_target.taskoverflow.resource_id
    scalable_dimension = aws_appautoscaling_target.taskoverflow.scalable_dimension
    service_namespace = aws_appautoscaling_target.taskoverflow.service_namespace

    target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = 20   # trigger scaling when average CPU across tasks exceeds 20%
    }
}