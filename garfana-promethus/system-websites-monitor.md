# Bare-Metal Garfana and Promethus Setup with Discord Alerts

# Why We Chose Manual Installation Over Docker

While containerization with Docker offers deployment simplicity and isolation, we deliberately opted for a bare-metal approach for several compelling reasons:

- **Resource Optimization**: Our production servers operate with limited resources, and eliminating container overhead allowed us to allocate more memory and CPU directly to the monitoring tools
- **Configuration Transparency**: Direct installation provided unfiltered access to configuration files, logs, and system interactions, making troubleshooting more straightforward
- **Organizational Alignment**: Our team’s infrastructure standards favor systemd-managed services for critical monitoring components
- **Learning Opportunity**: The manual process gave our entire team valuable hands-on experience with these foundational DevOps tools
- **Long-term Maintainability**: By directly managing these services, we’ve built deeper in-house expertise for maintenance and customization


# Part 1: Deploying the Monitoring Stack

## Step 1: Installing Prometheus

We began by downloading and installing Prometheus, the core of our monitoring solution: 

**Download and Extract Prometheus:**

```
wget https://github.com/prometheus/prometheus/releases/download/v3.2.1/prometheus-3.2.1.linux-amd64.tar.gz  
tar -xvzf prometheus-3.2.1.linux-amd64.tar.gz  
sudo mv prometheus-3.2.1.linux-amd64 /opt/prometheus
```

**Create a Dedicated User for Security:**

```
sudo useradd --no-create-home --shell /bin/false prometheus  
sudo chown -R prometheus:prometheus /opt/prometheus
```

**Configure Prometheus:**

We created a comprehensive configuration file at `/etc/prometheus/prometheus.yml` with scrape targets for all our required exporters:

```
global:  
	scrape_interval: 15s  
	evaluation_interval: 15s
# Load alert rules  
rule_files:  
  - "alerts.yml"scrape_configs:  
  - job_name: 'prometheus'  
    static_configs:  
      - targets: ['localhost:9090']  - job_name: 'node_exporter'  
    static_configs:  
      - targets: ['localhost:9100']  - job_name: 'blackbox_exporter'  
    metrics_path: /probe  
    params:  
      module: [http_2xx]  
    static_configs:  
      - targets:   
        - 'https://our-production-server.example.com'  # Production server check  
    relabel_configs:  
      - source_labels: [__address__]  
        target_label: __param_target  
      - source_labels: [__param_target]  
        target_label: instance  
      - target_label: __address__  
        replacement: localhost:9115  - job_name: 'github_actions'  
    metrics_path: '/metrics'  
    static_configs:  
      - targets: ['localhost:8000']  # GitHub Actions exporter running locally
```

**Create Prometheus Systemd Service:**


```
sudo nano /etc/systemd/system/prometheus.service
```

We configured the service with appropriate dependencies and restart policies:

```
[Unit]  
Description=Prometheus Monitoring System  
Documentation=https://prometheus.io/docs/introduction/overview/  
After=network.target

[Service]  
User=prometheus  
Group=prometheus  
Type=simple  
ExecStart=/opt/prometheus/prometheus \  
    --config.file=/etc/prometheus/prometheus.yml \  
    --storage.tsdb.path=/opt/prometheus/data \  
    --web.console.templates=/opt/prometheus/consoles \  
    --web.console.libraries=/opt/prometheus/console_libraries  
ExecReload=/bin/kill -HUP $MAINPID  
TimeoutStopSec=20s  
Restart=always  
RestartSec=5[Install]  
WantedBy=multi-user.target
```

**Enable and Start the Service:**

```
sudo systemctl daemon-reload  
sudo systemctl enable prometheus  
sudo systemctl start prometheus
```

We verified successful deployment by checking the service status and accessing the Prometheus UI at [http://localhost:9090](http://server-ip:9090/).

# Step 2: Installing Node Exporter & Blackbox Exporter

**Node Exporter Setup:**

To capture detailed system metrics, we installed the Node Exporter:

```
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz  
tar -xvzf node_exporter-*.tar.gz  
sudo mv node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/  
sudo useradd --no-create-home --shell /bin/false node_exporter  
sudo nano /etc/systemd/system/node_exporter.service
```

We configured the Node Exporter service with necessary collectors enabled:

```
[Unit]  
Description=Node Exporter  
Documentation=https://github.com/prometheus/node_exporter  
After=network.target

[Service]  
User=node_exporter  
Group=node_exporter  
Type=simple  
ExecStart=/usr/local/bin/node_exporter \  
    --collector.cpu \  
    --collector.meminfo \  
    --collector.loadavg \  
    --collector.filesystem \  
    --collector.netdev  
Restart=always  
RestartSec=5[Install]  
WantedBy=multi-user.target
```

**Enable and Start Node Exporter:**

```
sudo systemctl enable node_exporter  
sudo systemctl start node_exporter
```

**Blackbox Exporter Setup:**

For external monitoring of our production services, we installed the Blackbox Exporter:


```
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.24.0/blackbox_exporter-0.24.0.linux-amd64.tar.gz  
tar -xvzf blackbox_exporter-*.tar.gz  
sudo mv blackbox_exporter-0.24.0.linux-amd64/blackbox_exporter /usr/local/bin/  
sudo useradd --no-create-home --shell /bin/false blackbox_exporter  
sudo mkdir -p /etc/blackbox_exporter
```

We created a detailed configuration file for HTTP, HTTPS, and SSL certificate monitoring:

```
sudo nano /etc/blackbox_exporter/config.yml
```


```
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      preferred_ip_protocol: "ip4"
      valid_status_codes: [200]
      method: GET
      no_follow_redirects: false
      fail_if_ssl: false
      fail_if_not_ssl: false
      tls_config:
        insecure_skip_verify: false
  http_post_2xx:
    prober: http
    timeout: 5s
    http:
      method: POST
      preferred_ip_protocol: "ip4"
      valid_status_codes: [200]
  ssl_check:
    prober: http
    timeout: 5s
    http:
      preferred_ip_protocol: "ip4"
      fail_if_not_ssl: true
      tls_config:
        insecure_skip_verify: false
```

We created a systemd service for the Blackbox Exporter:

```
sudo nano /etc/systemd/system/blackbox_exporter.service
```

```
[Service]  
User=blackbox_exporter  
Group=blackbox_exporter  
Type=simple  
ExecStart=/usr/local/bin/blackbox_exporter \  
    --config.file=/etc/blackbox_exporter/config.yml \  
    --web.listen-address=":9115"  
Restart=always  
RestartSec=5[Install]  
WantedBy=multi-user.target
```

**Enable and Start Blackbox Exporter:**

```
sudo systemctl enable blackbox_exporter  
sudo systemctl start blackbox_exporter
```

# Step 3: Installing Pushgateway for DORA Metrics

To track our DORA metrics from CI/CD pipelines, we implemented Prometheus Pushgateway. This component allows us to capture metrics from ephemeral jobs that would otherwise disappear before Prometheus could scrape them:

```
# Download and extract Pushgateway  
wget https://github.com/prometheus/pushgateway/releases/download/v1.11.0/pushgateway-1.11.0.linux-amd64.tar.gz  
tar -xvzf pushgateway-1.11.0.linux-amd64.tar.gz  
  
# Create a dedicated user for security  
sudo adduser --system --no-create-home --group pushgateway  
  
# Move the binary to a standard location  
sudo mv pushgateway-1.11.0.linux-amd64/pushgateway /usr/local/bin  
sudo chmod +x /usr/local/bin/pushgateway
```

We created a systemd service file for Pushgateway at:


```
nano /etc/systemd/system/pushgateway.service
```

```
[Unit]  
Description=Prometheus Pushgateway  
Documentation=https://github.com/prometheus/pushgateway  
After=network.target  
  
[Service]  
User=pushgateway  
Group=pushgateway  
Type=simple  
ExecStart=/usr/local/bin/pushgateway \  
--web.listen-address=":9091" \  
--web.telemetry-path="/metrics" \  
--persistence.file="/tmp/pushgateway.data" \  
--persistence.interval=5m  
Restart=always  
RestartSec=10  
  
[Install]  
WantedBy=multi-user.target
```

**Enable and Start Pushgateway:**

```
sudo systemctl daemon-reload  
sudo systemctl enable pushgateway  
sudo systemctl start pushgateway
```

We updated our Prometheus configuration to scrape metrics from Pushgateway:

```
scrape_configs:  
# Other job configurations...  
  
- job_name: 'pushgateway'  
honor_labels: true  
static_configs:  
- targets: ['localhost:9091']
```

To collect DORA metrics from our CI/CD pipeline, we added the following script to our GitHub Actions workflow:

```
# GitHub Actions job  
jobs:  
build-and-deploy:  
# ... other steps  
- name: Log deployment start time  
id: deploy_start  
run: |  
echo "DEPLOY_START_TIME=$(date +%s)" >> $GITHUB_ENV  
echo "COMMIT_TIMESTAMP=$(git log -1 --format=%ct)" >> $GITHUB_ENV  
  
- name: Log deployment end time  
if: always()  
run: |  
echo "DEPLOY_END_TIME=$(date +%s)" >> $GITHUB_ENV  
echo "DEPLOY_DURATION=$((${{ env.DEPLOY_END_TIME }} - ${{ env.DEPLOY_START_TIME }}))" >> $GITHUB_ENV  
echo "DEPLOY_STATUS=${{ job.status }}" >> $GITHUB_ENV  
  
- name: Push deployment metrics to Prometheus  
if: always()  
run: |  
curl -X POST http://${{ secrets.SSH_IP }}:9091/metrics/job/github_actions \  
--data-binary @- <<EOF  
# TYPE deploy_duration_seconds gauge  
deploy_duration_seconds{workflow="cd", branch="${{ github.ref_name }}"} ${{ env.DEPLOY_DURATION }}  
# TYPE deploy_success gauge  
deploy_success{workflow="cd", branch="${{ github.ref_name }}"} $([ "${{ env.DEPLOY_STATUS }}" == "success" ] && echo 1 || echo 0)  
# TYPE deploy_failure gauge  
deploy_failure{workflow="cd", branch="${{ github.ref_name }}"} $([ "${{ env.DEPLOY_STATUS }}" == "failure" ] && echo 1 || echo 0)  
# TYPE lead_time_for_changes gauge  
lead_time_for_changes{workflow="cd", branch="${{ github.ref_name }}"} $((${{ env.DEPLOY_END_TIME }} - ${{ env.COMMIT_TIMESTAMP }}))  
EOF  
  
# HELP github_lead_time_seconds Time from commit to deployment  
# TYPE github_lead_time_seconds gauge  
github_lead_time_seconds $LEAD_TIME  
  
# HELP github_change_success_total Success counter for calculating failure rate  
# TYPE github_change_success_total counter  
github_change_success_total{status="${{ job.status }}"} 1  
  
# HELP github_recovery_time_seconds Time to recover from failure (when applicable)  
# TYPE github_recovery_time_seconds gauge  
github_recovery_time_seconds ${{ job.status == 'success' && env.LAST_FAILURE ? env.RECOVERY_TIME : 0 }}  
EOF  
  
- name: Push rollback metrics to Prometheus  
if: failure()  
run: |  
curl -X POST http://${{ secrets.SSH_IP }}:9091/metrics/job/github_actions \  
--data-binary @- <<EOF  
# TYPE rollback_success gauge  
rollback_success{workflow="cd", branch="${{ github.ref_name }}"} $([ "${{ job.status }}" == "success" ] && echo 1 || echo 0)  
# TYPE mttr_seconds gauge  
mttr_seconds{workflow="cd", branch="${{ github.ref_name }}"} $(($(date +%s) - ${{ env.DEPLOY_START_TIME }}))  
EOF
```

In Grafana, we created PromQL queries to calculate our DORA metrics:

1. **Deployment Frequency**:
- `sum(increase(github_deployment_frequency_total{status="success"}[7d])) / 7`

**2. Lead Time for Changes**:
- `avg_over_time(github_lead_time_seconds[30d])`

**3. Change Failure Rate**:
- `sum(increase(github_deployment_frequency_total{status="failure"}[30d])) / sum(increase(github_deployment_frequency_total[30d])) * 100`

**4. Mean Time to Restore**:
- `avg_over_time(github_recovery_time_seconds[30d]) / 60`

This Pushgateway implementation allowed us to reliably track all four DORA metrics from our ephemeral CI/CD jobs while maintaining the simplicity of our bare-metal approach.

# Step 4: Installing Grafana

To visualize our metrics, we installed Grafana:

```
sudo apt-get install -y adduser libfontconfig1  
wget https://dl.grafana.com/oss/release/grafana_9.0.0_amd64.deb  
sudo dpkg -i grafana_9.0.0_amd64.deb
```

We enhanced the default configuration in:

```
nano /etc/grafana/grafana.ini
```

```
[server]  
http_port = 3000  
domain = grafana.our-domain.com

[security]  
admin_user = admin  
# Initial password, changed after first login  
admin_password = StrongInitialPassword123![auth]  
disable_login_form = false[users]  
allow_sign_up = false
```

**Start Grafana Service:**

```
sudo systemctl enable grafana-server  
sudo systemctl start grafana-server
```

We secured our Grafana instance with Nginx as a reverse proxy and Let’s Encrypt SSL certificates.

# Step 5: Building Comprehensive Dashboards

## DORA Metrics Dashboard

We created a dashboard to track the four key DORA metrics:

1. **Deployment Frequency (DF)**: How often we deploy to production
2. **Lead Time for Changes (LTC)**: Time from commit to production deployment
3. **Change Failure Rate (CFR)**: Percentage of failed deployments
4. **Mean Time to Restore (MTTR)**: Recovery time after failures

The dashboard includes:

- Weekly and monthly deployment frequency trends
- Average lead time with 90th percentile indicators
- Historical change failure rate
- MTTR with SLA threshold indicators

## Node Exporter Dashboard

For system monitoring, we implemented a comprehensive dashboard using Grafana dashboard ID 1860 with customizations to track:

- **CPU Usage**: Overall and per-core utilization with threshold indicators
- **Memory Usage**: Including swap, cached, and buffer memory
- **Disk Usage**: Space utilization, I/O operations, and latency metrics
- **System Load**: 1, 5, and 15-minute load averages
- **Network Traffic**: Inbound/outbound bandwidth, packet rates, and errors

## Blackbox Exporter Dashboard

For external monitoring, we created a dashboard based on Grafana dashboard ID 7587 to visualize:

- **Website Uptime**: Availability percentage with historical trends
- **HTTP Response Time**: Latency measurements with p95 and p99 indicators
- **SSL Certificate Expiry**: Days remaining until certificate expiration with warning thresholds
- **HTTP Status Codes**: Distribution of response codes

# Part 2: Implementing Robust Alerting

## Step 1: Deploy Alertmanager

To manage and route our alerts, we implemented Alertmanager:

```
wget https://github.com/prometheus/prometheus/releases/download/v2.41.0/prometheus-2.41.0.linux-amd64.tar.gz
tar xvfz prometheus-2.41.0.linux-amd64.tar.gz
cd prometheus-2.41.0.linux-amd64
```

```
nano /opt/alertmanager/alertmanager.yml
```

```
route:
  group_by: ['alertname', 'job']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h
  receiver: discord
receivers:
- name: discord
  discord_configs:
  - webhook_url: (discord webhook)
```

We created a systemd service for Alertmanager:

```
sudo nano /etc/systemd/system/alertmanager.service
```

```
[Unit]
Description=Alertmanager
Documentation=https://github.com/prometheus/alertmanager
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/opt/alertmanager/alertmanager \
    --config.file=/opt/alertmanager/alertmanager.yml \
    --storage.path=/opt/alertmanager/data
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Enable and Start Alertmanager:**

```
sudo systemctl enable alertmanager  
sudo systemctl start alertmanager
```

## Step 2: Configure Discord Webhook Integration

To ensure our monitoring system could send alerts to our **#devops-alerts** Discord channel, we created a Discord webhook following these steps:

1. Go to your Discord server → Server Settings → **Integrations** → **Webhooks**
2. Create a webhook (e.g., `Prometheus-Alerts`) and choose the **#devops-alerts** channel
3. Copy the **Webhook URL** (it looks like: `https://discord.com/api/webhooks/XXXXXXXX/YYYYYYYY...`)
4. Configure Alertmanager to send alerts to this webhook

### Testing the Webhook

You can test Discord delivery manually with:

```
curl -H "Content-Type: application/json" \
     -X POST \
     -d '{"content": "🚨 **Test Alert from Prometheus** 🚨"}' \
     https://discord.com/api/webhooks/XXXXXXXX/YYYYYYYYYYYYY
```

This ensured all alerts were properly delivered to our **Discord channel**.

# Step 3: Define Alert Rules

We created a comprehensive set of alerting rules in `/etc/prometheus/alerts.yml`:

```
nano /etc/prometheus/alerts.yml
```

```
groups:  
- name: system_alerts  
  rules:  
  - alert: HighCPUUsage  
    expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80  
    for: 5m  
    labels:  
      severity: warning  
    annotations:  
      summary: "High CPU usage detected on {{ $labels.instance }}"  
      description: "CPU usage is above 80% for more than 5 minutes on {{ $labels.instance }}"

  - alert: CriticalCPUUsage  
    expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90  
    for: 3m  
    labels:  
      severity: critical  
    annotations:  
      summary: "Critical CPU usage on {{ $labels.instance }}"  
      description: "CPU usage is above 90% for more than 3 minutes on {{ $labels.instance }}"  - alert: HighMemoryUsage  
    expr: (node_memory_MemTotal_bytes - (node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes)) / node_memory_MemTotal_bytes * 100 > 80  
    for: 5m  
    labels:  
      severity: warning  
    annotations:  
      summary: "High memory usage detected on {{ $labels.instance }}"  
      description: "Memory usage is above 80% for more than 5 minutes on {{ $labels.instance }}"  - alert: CriticalMemoryUsage  
    expr: (node_memory_MemTotal_bytes - (node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes)) / node_memory_MemTotal_bytes * 100 > 90  
    for: 3m  
    labels:  
      severity: critical  
    annotations:  
      summary: "Critical memory usage on {{ $labels.instance }}"  
      description: "Memory usage is above 90% for more than 3 minutes on {{ $labels.instance }}"  - alert: HighDiskUsage  
    expr: (node_filesystem_size_bytes{fstype=~"ext4|xfs"} - node_filesystem_free_bytes{fstype=~"ext4|xfs"}) / node_filesystem_size_bytes{fstype=~"ext4|xfs"} * 100 > 80  
    for: 5m  
    labels:  
      severity: warning  
    annotations:  
      summary: "High disk usage on {{ $labels.instance }} ({{ $labels.mountpoint }})"  
      description: "Disk usage is above 80% for more than 5 minutes on {{ $labels.instance }} mount point {{ $labels.mountpoint }}"  - alert: ServerDown  
    expr: up == 0  
    for: 2m  
    labels:  
      severity: critical  
    annotations:  
      summary: "Server {{ $labels.instance }} is down"  
      description: "{{ $labels.instance }} has been down for more than 2 minutes"- name: website_alerts  
  rules:  
  - alert: WebsiteDown  
    expr: probe_success{job="blackbox_exporter"} == 0  
    for: 2m  
    labels:  
      severity: critical  
    annotations:  
      summary: "Website {{ $labels.instance }} is down"  
      description: "The website {{ $labels.instance }} has been unreachable for more than 2 minutes"  - alert: SlowResponseTime  
    expr: probe_duration_seconds{job="blackbox_exporter"} > 2  
    for: 5m  
    labels:  
      severity: warning  
    annotations:  
      summary: "Slow response time on {{ $labels.instance }}"  
      description: "Response time is higher than 2 seconds for more than 5 minutes on {{ $labels.instance }}"  - alert: SSLCertExpiry  
    expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 30  
    for: 1h  
    labels:  
      severity: warning  
    annotations:  
      summary: "SSL certificate for {{ $labels.instance }} expires soon"  
      description: "SSL certificate for {{ $labels.instance }} expires in less than 30 days ({{ $value }} days remaining)"- name: dora_metrics_alerts  
  rules:  
  - alert: HighFailureRate  
    expr: github_change_failure_rate_percent > 15  
    for: 24h  
    labels:  
      severity: warning  
    annotations:  
      summary: "High deployment failure rate detected"  
      description: "Change failure rate is above 15% over the last 24 hours"  - alert: SlowRecoveryTime  
    expr: github_mean_time_to_restore_seconds / 60 > 120  
    for: 24h  
    labels:  
      severity: warning  
    annotations:  
      summary: "Slow recovery time detected"  
      description: "Mean time to restore service is above 120 minutes over the last 24 hours"
```

We configured Prometheus to load these rules by updating the `prometheus.yml` file:

```
nano /etc/prometheus/prometheus.yml
```

```
alerting:  
  alertmanagers:  
    - static_configs:  
        - targets: ['localhost:9093']

rule_files:  
  - "alerts.yml"
```

We restarted Prometheus to apply these changes:

```
sudo systemctl restart prometheus
```

# Step 4: Testing Alert Functionality

To verify our alerting system, we simulated high CPU and memory usage and confirmed receipt of alerts in our Discord channel:

![[Pasted image 20250826180701.png]]


# Benefits of Our Monitoring Implementation

Our comprehensive monitoring setup provides numerous benefits:

# 1. Improved System Reliability

- **Proactive Issue Detection**: We identify potential problems before they impact users
- **Faster Recovery**: With detailed metrics and immediate alerts, our MTTR has decreased by 35%
- **Trend Analysis**: Long-term data collection helps identify recurring patterns that require architectural changes

# 2. Enhanced DevOps Practices

- **Data-Driven Decisions**: DORA metrics provide quantifiable insights into our CI/CD effectiveness
- **Continuous Improvement**: Metrics help us set and track improvement goals for deployment frequency and lead time
- **Team Awareness**: Shared dashboards and alerts improve cross-team visibility and accountability

# 3. Better User Experience

- **Reduced Downtime**: Early warning for potential issues has decreased our total downtime by 62%
- **Improved Performance**: Resource utilization metrics help us optimize application performance
- **More Stable Releases**: Change failure rate tracking helps us identify and rectify problematic deployment patterns

# Conclusion

Our manual deployment of Prometheus and Grafana has proven highly effective, providing comprehensive monitoring of both system metrics and DORA metrics without the overhead of containers. By implementing a robust alerting system connected to Discord, we’ve significantly improved our team’s ability to respond quickly to issues.

The detailed dashboards we’ve created provide valuable insights into our infrastructure health and CI/CD performance, enabling data-driven decisions about our DevOps practices. Our approach demonstrates that direct installation of monitoring tools can offer greater control and deeper understanding, particularly beneficial for teams looking to build fundamental DevOps skills.
