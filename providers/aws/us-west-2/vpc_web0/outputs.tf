output "security_group" {
  value = "${aws_security_group.web0-http-public.id}"
}

output "launch_configuration" {
  value = "${aws_launch_configuration.web0-lc.id}"
}

output "asg_name" {
  value = "${aws_autoscaling_group.helloworld-asg.id}"
}

output "elb_name" {
  value = "${aws_elb.helloworld-elb.dns_name}"
}