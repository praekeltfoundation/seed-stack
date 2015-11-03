consul = "127.0.0.1:8500"
retry = "10s"
max_stale = "10m"
log_level = "warn"
pid_file = "/var/run/consul-template.pid"

syslog {
  enabled = true
  facility = "LOCAL5"
}

template {
  source = "/etc/consular/nginx.ctmpl"
  destination = "/etc/nginx/sites-enabled/consul_template.conf"
  command = "/etc/init.d/nginx reload"
}
