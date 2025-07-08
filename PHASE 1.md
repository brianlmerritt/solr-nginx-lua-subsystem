# Solr Nginx Lua Proxy - Stage 1

A simple nginx lua proxy that forwards requests to a Solr server. This is the first stage of implementing a full proxy with Redis "tee" functionality.

## Current Stage

✅ **Stage 1**: Basic nginx lua proxy that passes through requests to Solr
- Nginx proxy on port 8983
- Solr server on internal port 8988
- Health check endpoints
- Basic logging

🔄 **Stage 2** (Next): Add Redis "tee" functionality to capture requests/responses

## Architecture

```
Client → Nginx Proxy (8983) → Solr Server (8988)
```

## Quick Start

1. **Build and start services:**
   ```bash
   make build
   make up
   ```

2. **Test the proxy:**
   ```bash
   make test
   ```

3. **Check health:**
   ```bash
   make health
   ```

## Services

- **Nginx Proxy**: Port 8983 (external)
- **Solr Server**: Port 8988 (external for direct access), Port 8983 (internal)

## Endpoints

- `GET /health` - Health check for the proxy
- `GET /nginx_status` - Nginx status (internal networks only)
- `/*` - All other requests proxied to Solr

## Testing

Test the proxy is working:

```bash
# Health check
curl http://localhost:8983/health

# Solr admin ping
curl http://localhost:8983/solr/admin/ping

# Solr select query
curl "http://localhost:8983/solr/select?q=*:*&wt=json"
```

## Configuration

The proxy uses environment variables:
- `SOLR_HOST`: Solr container hostname (default: "solr")
- `SOLR_PORT`: Solr container port (default: "8983")

## File Structure

```
├── docker-compose.yml      # Container orchestration
├── Dockerfile.nginx        # Nginx/OpenResty container
├── nginx.conf              # Nginx configuration
├── lua/
│   └── proxy.lua           # Lua proxy logic (basic)
├── Makefile               # Build/test commands
└── README.md              # This file
```

## Development

### Build and run:
```bash
make build up
```

### View logs:
```bash
make logs
```

### Clean up:
```bash
make clean
```

## Next Steps

Stage 2 will add:
- Redis integration (external subsystem)
- Request/response capture (local for sending requests to the above)
- Queue management for downstream processing (external system)
- Error handling and graceful degradation