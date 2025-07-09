#!/usr/bin/env bash

# Quick diagnosis script for trading services
set -euo pipefail

echo "🔍 Trading Services Status Check"
echo "==============================="

# Check Kafka service
echo "📊 Kafka Service:"
if systemctl --user is-active kafka.service >/dev/null 2>&1; then
    echo "  ✅ kafka.service is running"
    # Test Kafka connectivity
    if kafka-topics.sh --bootstrap-server 192.168.0.7:9092 --list >/dev/null 2>&1; then
        echo "  ✅ Kafka is responding to API calls"
        echo "  📋 Topics:"
        kafka-topics.sh --bootstrap-server 192.168.0.7:9092 --list | head -5
    else
        echo "  ⚠️  Kafka service running but not responding to API calls"
    fi
else
    echo "  ❌ kafka.service is not running"
    echo "  📋 Status:"
    systemctl --user status kafka.service --no-pager -l || true
fi

echo ""

# Check Valkey service
echo "🗄️  Valkey Service:"
if systemctl --user is-active valkey.service >/dev/null 2>&1; then
    echo "  ✅ valkey.service is running"
else
    echo "  ❌ valkey.service is not running"
    echo "  📋 Status:"
    systemctl --user status valkey.service --no-pager -l || true
fi

echo ""

# Check financial data consumer
echo "💰 Financial Data Consumer:"
if systemctl --user is-active financial_data_consumer.service >/dev/null 2>&1; then
    echo "  ✅ financial_data_consumer.service is running"
else
    echo "  ❌ financial_data_consumer.service is not running"
    echo "  📋 Status:"
    systemctl --user status financial_data_consumer.service --no-pager -l || true
    echo ""
    echo "  📋 Recent logs:"
    journalctl --user -u financial_data_consumer.service --since "10 minutes ago" --no-pager | tail -10 || true
fi

echo ""

# Network checks
echo "🌐 Network Connectivity:"
echo "  Testing Kafka port 192.168.0.7:9092..."
if timeout 3 bash -c "</dev/tcp/192.168.0.7/9092" 2>/dev/null; then
    echo "  ✅ Port 9092 is accessible"
else
    echo "  ❌ Port 9092 is not accessible"
fi

echo "  Testing Valkey port 127.0.0.1:6379..."
if timeout 3 bash -c "</dev/tcp/127.0.0.1/6379" 2>/dev/null; then
    echo "  ✅ Port 6379 is accessible"
else
    echo "  ❌ Port 6379 is not accessible"
fi

echo ""

# Service dependencies
echo "🔗 Service Dependencies:"
echo "  financial_data_consumer dependencies:"
systemctl --user list-dependencies financial_data_consumer.service --plain | head -10 || true

echo ""
echo "🎯 Quick Actions:"
echo "  Start all services:    systemctl --user start kafka valkey financial_data_consumer"
echo "  Restart consumer:      systemctl --user restart financial_data_consumer"
echo "  View logs:            journalctl --user -u financial_data_consumer -f"
echo "  Check Kafka manually: kafka-topics.sh --bootstrap-server 192.168.0.7:9092 --list"
