module "cloudwatch_metric-alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"
  
  alarm_name = var.cpu_alarm_name
  alarm_description = var.cpu_alarm_description
  metric_name = var.cpu_metric_name
  create_metric_alarm = var.cpu_create_metric_alarm
  period = var.cpu_period # the minutes for the metric to be collected
  evaluation_periods = var.cpu_evaluation_periods # the minutes for threshold to be met
  threshold = var.cpu_threshold #triggers when over 80% CPU usage for more than 2 minutes
  statistic = var.cpu_statistic #uses an average value of the metric (the 80% in 2 minutes) and compares it to the threshold

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  alarm_actions = [var.alarm_actions]
}