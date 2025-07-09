# Troubleshooting Kafka Connectivity Issues

## Overview

If the financial-data-consumer service fails with "failed waiting for kafka", follow this troubleshooting guide.

## Quick Diagnosis Commands

### 1. Check Service Status
```bash
# Check if Kafka service is running
systemctl --user status kafka

# Check financial-data-consumer service status
systemctl --user status financial_data_consumer

# View logs for both services
journalctl --user -u kafka -f
journalctl --user -u financial_data_consumer -f
```

### 2. Test Kafka Connectivity
```bash
# Test if Kafka port is open (replace IP with your Kafka hostIp)
telnet 192.168.0.7 9092

# List Kafka topics manually
kafka-topics.sh --bootstrap-server 192.168.0.7:9092 --list

# Check if __consumer_offsets topic exists
kafka-topics.sh --bootstrap-server 192.168.0.7:9092 --list | grep __consumer_offsets
```

### 3. Check Network Configuration
```bash
# Check what ports Kafka is listening on
ss -tlnp | grep 9092

# Check network interfaces
ip addr show

# Test DNS resolution (if using hostname)
nslookup 192.168.0.7
```

## Common Issues and Solutions

### Issue 1: Wrong Kafka Bootstrap Server Address

**Symptoms:**
- Connection timeouts
- "Failed to connect to Kafka" in logs

**Solution:**
1. Check your Kafka configuration in `modules/home/pai/roles/server.nix`:
   ```nix
   kafkaKRaft = {
     hostIp = "192.168.0.7";  # This should match your network setup
     kafkaPort = 9092;
   };
   ```

2. Update the financial-data-consumer configuration:
   ```nix
   financial_data_consumer = {
     kafkaBootstrapServer = "192.168.0.7:9092";  # Must match hostIp:kafkaPort
   };
   ```

3. For localhost setup, use:
   ```nix
   kafkaKRaft = {
     hostIp = "127.0.0.1";
   };
   financial_data_consumer = {
     kafkaBootstrapServer = "127.0.0.1:9092";
   };
   ```

### Issue 2: Kafka Service Not Starting

**Symptoms:**
- `systemctl --user status kafka` shows failed state
- Port 9092 not listening

**Solution:**
1. Check Kafka logs:
   ```bash
   journalctl --user -u kafka -n 50
   ```

2. Common fixes:
   - Ensure data directory exists and is writable: `/mnt/shaun/kafka-kraft`
   - Check disk space: `df -h /mnt/shaun`
   - Verify Java is available: `java --version`

3. Restart Kafka:
   ```bash
   systemctl --user restart kafka
   ```

### Issue 3: Service Dependency Issues

**Symptoms:**
- Services start in wrong order
- financial-data-consumer starts before Kafka is ready

**Solution:**
1. Check systemd dependencies:
   ```bash
   systemctl --user list-dependencies financial_data_consumer
   ```

2. The service should have these dependencies:
   ```nix
   After = [ "kafka.service" "valkey.service" ];
   Requires = [ "kafka.service" "valkey.service" ];
   BindsTo = [ "kafka.service" ];
   ```

### Issue 4: __consumer_offsets Topic Not Created

**Symptoms:**
- Kafka is running but wait script fails
- Topic list doesn't include `__consumer_offsets`

**Solution:**
1. The topic should be auto-created. Check Kafka configuration:
   ```bash
   # Check if auto-creation is enabled
   kafka-configs.sh --bootstrap-server 192.168.0.7:9092 --describe --entity-type brokers --entity-name 0
   ```

2. Manually create the topic if needed:
   ```bash
   kafka-topics.sh --bootstrap-server 192.168.0.7:9092 \
     --create --topic __consumer_offsets \
     --partitions 50 --replication-factor 1 \
     --config cleanup.policy=compact
   ```

### Issue 5: Firewall/Network Issues

**Symptoms:**
- Port reachable locally but not from network
- Services on different hosts can't connect

**Solution:**
1. Check firewall rules:
   ```bash
   # NixOS firewall status
   systemctl status firewall

   # Check if port 9092 is open
   sudo ss -tlnp | grep 9092
   ```

2. Ensure ports are open in NixOS configuration:
   ```nix
   networking.firewall.allowedTCPPorts = [ 9092 ];
   ```

## Advanced Debugging

### Enable Debug Logging

1. **Kafka Debug Logs:**
   ```bash
   # Edit Kafka config to enable debug logging
   # Add to kraft.properties:
   log4j.logger.kafka=DEBUG
   ```

2. **Consumer Debug Logs:**
   ```nix
   financial_data_consumer = {
     rustLogLevel = "debug";  # Change from "error" to "debug"
   };
   ```

### Network Troubleshooting

```bash
# Test connectivity step by step
ping 192.168.0.7                    # Basic connectivity
telnet 192.168.0.7 9092             # Port connectivity
nc -zv 192.168.0.7 9092             # Alternative port test

# Check routing
traceroute 192.168.0.7

# Monitor network traffic
sudo tcpdump -i any port 9092
```

### Service Startup Analysis

```bash
# Analyze service startup timing
systemd-analyze --user critical-chain financial_data_consumer

# Check service startup logs
journalctl --user -u financial_data_consumer --since "10 minutes ago"

# Monitor service dependencies
systemctl --user list-dependencies --all financial_data_consumer
```

## Configuration Examples

### Local Development Setup
```nix
# For development on localhost
kafkaKRaft = {
  hostIp = "127.0.0.1";
  kafkaPort = 9092;
};

financial_data_consumer = {
  kafkaBootstrapServer = "127.0.0.1:9092";
};
```

### Network Server Setup
```nix
# For server accessible from network
kafkaKRaft = {
  hostIp = "0.0.0.0";        # Listen on all interfaces
  kafkaPort = 9092;
};

financial_data_consumer = {
  kafkaBootstrapServer = "192.168.0.7:9092";  # Connect to specific IP
};
```

### Docker/Container Setup
```nix
# For containerized environments
kafkaKRaft = {
  hostIp = "0.0.0.0";
  kafkaPort = 9092;
};

financial_data_consumer = {
  kafkaBootstrapServer = "kafka:9092";  # Use container hostname
};
```

## Preventive Measures

1. **Health Checks:**
   ```bash
   # Add to cron or systemd timer
   #!/bin/bash
   kafka-topics.sh --bootstrap-server 192.168.0.7:9092 --list > /dev/null || \
     systemctl --user restart kafka
   ```

2. **Monitoring:**
   ```bash
   # Monitor Kafka metrics
   kafka-console-consumer.sh --bootstrap-server 192.168.0.7:9092 \
     --topic __consumer_offsets --from-beginning --max-messages 1
   ```

3. **Automated Recovery:**
   ```nix
   # Add to service configuration
   Service = {
     Restart = "on-failure";
     RestartSec = "10s";
     StartLimitBurst = 3;
     StartLimitIntervalSec = "60s";
   };
   ```

## Getting Help

If issues persist:

1. **Collect Information:**
   ```bash
   # System info
   nixos-version
   
   # Service status
   systemctl --user status kafka financial_data_consumer
   
   # Recent logs
   journalctl --user -u kafka -u financial_data_consumer --since "1 hour ago"
   
   # Network info
   ip addr show
   ss -tlnp | grep 9092
   ```

2. **Check Configuration:**
   ```bash
   # Verify Nix configuration
   nix eval .#nixosConfigurations.dataserver.config.modules.services.kafkaKRaft
   ```

3. **Test Manually:**
   ```bash
   # Start services manually for debugging
   systemctl --user stop kafka financial_data_consumer
   
   # Run Kafka manually
   kafka-server-start.sh /path/to/kraft.properties
   
   # Test consumer connection
   kafka-console-consumer.sh --bootstrap-server 192.168.0.7:9092 --topic test
   ```
