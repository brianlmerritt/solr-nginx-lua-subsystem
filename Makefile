# Makefile for Solr Nginx Lua Proxy

.PHONY: build up down logs test clean health

# Build the containers
build:
	docker-compose build

# Start the services
up:
	docker-compose up -d

# Stop the services
down:
	docker-compose down

# Follow logs
logs:
	docker-compose logs -f

# Test the proxy
test:
	@echo "Testing health endpoint..."
	curl -f http://localhost:8983/health || echo "Health check failed"
	@echo "\nTesting Solr proxy..."
	curl -f "http://localhost:8983/solr/admin/ping" || echo "Solr ping failed"

# Check health
health:
	@echo "Checking proxy health..."
	curl -s http://localhost:8983/health | jq .
	@echo "\nChecking nginx status..."
	curl -s http://localhost:8983/nginx_status

# Clean up
clean:
	docker-compose down -v
	docker system prune -f

# Development helpers
restart: down up

rebuild: down build up

# Show container status
status:
	docker-compose ps