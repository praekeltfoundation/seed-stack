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
  source = "/etc/consular/nginx-upstreams.ctmpl"
  destination = "/etc/nginx/sites-enabled/seed-upstreams.conf"
  command = "/etc/init.d/nginx reload"
}
template {
  source = "/etc/consular/nginx-websites.ctmpl"
  destination = "/etc/nginx/sites-enabled/seed-websites.conf"
  command = "/etc/init.d/nginx reload"
}
template {
  source = "/etc/consular/nginx-services.ctmpl"
  destination = "/etc/nginx/sites-enabled/seed-services.conf"
  command = "/etc/init.d/nginx reload"
}
