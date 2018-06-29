output "broker_internal_ip" {
  value = ["${local.kafka_addrs}"]
}

output "broker_internal_dns" {
  value = ["${aws_route53_record.private_kafka.*.fqdn}"]
}

output "zookeeper_internal_ip" {
  value = ["${local.zookeeper_addrs}"]
}

output "zookeeper_internal_dns" {
  value = ["${aws_route53_record.private_zookeeper.*.fqdn}"]
}
