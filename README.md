# SOLR Nginx Lua Subsystem

A reverse proxy built on OpenResty/Nginx with Lua that forwards Moodle ⇄ Solr traffic and "tees" each request/response into Redis for the Learning Tools AI Playground.

## Overview

This subsystem acts as a transparent bridge between Moodle's Global Search and Solr, while simultaneously capturing search queries and responses for processing by the embeddings workers. It enables a plug-and-play RAG (Retrieval-Augmented Generation) workflow without modifying Moodle or Solr code.

## Architecture

```
Moodle → [Nginx Lua Proxy] → Solr
              ↓
           Redis Queue
              ↓
        Embeddings Workers
```

### Key Components

- **OpenResty/Nginx**: High-performance reverse proxy with Lua scripting capabilities
- **Lua Scripts**: Handle request/response interception and Redis queuing
- **Redis Integration**: Store search jobs for asynchronous processing
- **Health Checks**: `/health` endpoint for monitoring integration

## Features

- **Transparent Proxy**: Forwards all Moodle ⇄ Solr traffic without modification
- **Low Latency**: Adds < 1ms latency at 300 req/s
- **Redis Teeing**: Captures search queries and responses in Redis queue
- **Graceful Degradation**: Continues proxying even if Redis is down
- **Load Control**: Optional downsampling for query rate limiting
- **Health Monitoring**: Built-in health check endpoints

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Redis instance (provided by the main playground)
- Solr instance (provided by the main playground)

### Installation

1. **Clone as submodule** (handled by main playground):
   ```bash
   # This is managed by bin/plugin_submodules.sh
   git submodule add <repository-url> plugins/solr_nginx_lua_subsystem
   ```

2. **Add to plugins.yaml**:
   ```yaml
   submodules:
     - name: SOLR Nginx Lua
       path: plugins/solr_nginx_lua_subsystem
       docker: "docker-compose up -d"
   ```

3. **Bring up the service**:
   ```bash
   ./bin/ai_up.sh
   ```

### Configuration

#### Environment Variables

Set in `/bin/setup_environment.sh`:

```bash
# Redis configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0

# Solr configuration
SOLR_HOST=solr
SOLR_PORT=8983
SOLR_PATH=/solr

# Proxy configuration
PROXY_PORT=8984  # Different from Solr to avoid conflicts
DOWNSAMPLE_RATIO=1  # 1 = capture all, 2 = capture every 2nd query, etc.
```

#### Docker Configuration

The service is configured via `docker-compose.yaml`:

```yaml
version: '3.8'
services:
  solr-proxy:
    build: .
    ports:
      - "8984:80"
    environment:
      - REDIS_HOST=${REDIS_HOST:-redis}
      - SOLR_HOST=${SOLR_HOST:-solr}
      - DOWNSAMPLE_RATIO=${DOWNSAMPLE_RATIO:-1}
    networks:
      - moodle_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## API Reference

### Health Check

```
GET /health
```

Returns:
```json
{
  "status": "healthy",
  "redis": "connected",
  "solr": "reachable",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### Nginx Status

```
GET /nginx_status
```

Returns Nginx stub_status format for Prometheus monitoring.

### Proxy Endpoints

All requests to the proxy are forwarded to Solr with the following mapping:

- `GET /solr/*` → `http://solr:8983/solr/*`
- `POST /solr/*` → `http://solr:8983/solr/*`
- All other Solr endpoints are proxied transparently

## Redis Queue Format

### Search Jobs

Jobs are pushed to the `solr_jobs` Redis list with the following JSON structure:

```json
{
  "id": "unique-job-id",
  "timestamp": "2024-01-01T00:00:00Z",
  "type": "search_query",
  "method": "GET",
  "path": "/solr/select",
  "query_params": {
    "q": "search term",
    "wt": "json"
  },
  "request_body": null,
  "response_status": 200,
  "response_body": "...",
  "processing_time_ms": 45
}
```

## Development

### Local Development

1. **Build the image**:
   ```bash
   docker build -t solr-nginx-lua .
   ```

2. **Run with local Redis and Solr**:
   ```bash
   docker-compose up --build
   ```

3. **Test the proxy**:
   ```bash
   curl "http://localhost:8984/solr/select?q=test&wt=json"
   ```

### Testing

Run tests with:
```bash
make test
```

Tests include:
- Unit tests for Lua functions
- Integration tests for proxy functionality
- Performance benchmarks
- Health check validation

### Monitoring

#### Prometheus Metrics

The service exposes metrics at `/metrics`:

- `nginx_http_requests_total`: Total HTTP requests
- `nginx_http_request_duration_seconds`: Request duration
- `solr_proxy_redis_jobs_total`: Total jobs pushed to Redis
- `solr_proxy_redis_errors_total`: Redis connection errors

#### Logs

Logs are available via:
```bash
docker-compose logs -f solr-proxy
```

## Troubleshooting

### Common Issues

1. **Redis Connection Failed**
   - Check Redis is running: `docker ps | grep redis`
   - Verify network connectivity: `docker network ls`
   - Check environment variables in `setup_environment.sh`

2. **Solr Connection Failed**
   - Verify Solr is running: `docker ps | grep solr`
   - Check Solr health: `curl http://solr:8983/solr/admin/ping`
   - Ensure correct host/port configuration

3. **High Latency**
   - Check Redis performance: `redis-cli info memory`
   - Monitor network usage: `docker stats`
   - Verify downsampling is configured correctly

### Debug Mode

Enable debug logging by setting:
```bash
export NGINX_DEBUG=true
```

Then rebuild and restart:
```bash
docker-compose down
docker-compose up --build
```

## Performance

### Benchmarks

- **Latency**: < 1ms added latency at 300 req/s
- **Throughput**: 1000+ req/s sustained
- **Memory**: ~50MB base usage
- **CPU**: < 5% under normal load

### Optimization

1. **Tune Nginx workers**:
   ```nginx
   worker_processes auto;
   worker_connections 1024;
   ```

2. **Optimize Lua code**:
   - Use `ngx.shared.DICT` for caching
   - Minimize Redis operations
   - Use efficient JSON encoding

3. **Monitor and adjust**:
   - Watch Redis memory usage
   - Monitor network latency
   - Adjust downsampling ratio as needed

## Security

### Network Security

- All traffic is internal to the Docker network
- No external ports exposed by default
- TLS termination handled by upstream proxy

### Access Control

- Redis ACLs can be configured for production
- Nginx access logs for audit trails
- Rate limiting available via Nginx modules

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

### Code Style

- Lua: Follow [Lua Style Guide](https://github.com/Olivine-Labs/lua-style-guide)
- Nginx: Follow [Nginx Best Practices](https://nginx.org/en/docs/best_practices.html)
- Docker: Follow [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Check the [troubleshooting section](#troubleshooting)
- Review the [main playground documentation](../../README.md)
- Open an issue in the main repository

## Related Documentation

- [Learning Tools AI Playground](../../README.md)
- [Subsystems and Networks](../../docs/subsystems_and_networks.md)
- [Search Proxy Project](../../docs/search_proxy_project.md) 