module "cpu_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2" #this has no place into root/main.tf because only in the module it gets used, not in the root. Root calls this module so no need to double call it in root also
    #version is only specified where the download of the module occurs, not in the root.

  #bellow are the variables for the alarm, comes from terraform.tfvars in monitoring section
  alarm_name = var.cpu_alarm_name
  alarm_description = var.cpu_alarm_description
  comparison_operator = "GreaterThanThreshold"
  metric_name = var.cpu_metric_name
  create_metric_alarm = var.cpu_create_metric_alarm
  period = var.cpu_period # the minutes for the metric to be collected
  evaluation_periods = var.cpu_evaluation_periods # the minutes for threshold to be met
  threshold = var.cpu_threshold #triggers when over 80% CPU usage for more than 2 minutes
  statistic = var.cpu_statistic #uses an average value of the metric (the 80% in 2 minutes) and compares it to the threshold

  dimensions = {#this has no place into root/main.tf because it is a submodule
    ClusterName = var.eks_cluster_name
  }

  alarm_actions = var.cpu_alarm_actions   #Slack alerts to SNS topic defined in terraform.tfvars in monitoring section
}