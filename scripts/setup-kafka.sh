#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first:"
    echo "   https://docs.docker.com/engine/install/"
    exit 1
fi

echo "🚀 Starting Kafka cluster..."
docker compose up -d

echo "⏳ Waiting for Kafka to be ready..."
sleep 30

echo "📝 Creating test topic..."
docker exec kafka kafka-topics --create \
  --topic test-topic \
  --bootstrap-server localhost:9092 \
  --replication-factor 1 \
  --partitions 3

echo "✅ Kafka setup complete!"
echo "📊 Kafka UI available at: http://localhost:8080"
echo "🔌 Kafka broker available at: localhost:9092"