# Development Tools

A collection of local development tools for containerized applications with SSL support.

## 🛠️ Tools

| Tool | Description | Access |
|------|-------------|--------|
| **Traefik** | Reverse proxy with automatic SSL | https://dns.localhost |
| **IT Tools** | Web-based developer utilities | https://ittools.localhost |

## 🔧 Traefik Configuration

Traefik acts as a reverse proxy with automatic HTTPS redirect and SSL termination using mkcert certificates.

### Features
- 🔒 Automatic HTTP → HTTPS redirect
- 📋 Dashboard at https://dns.localhost
- 🎯 Route services using Docker labels
- 🔐 Wildcard SSL certificates for `*.localhost`

### Add a Service
```yaml
services:
  myapp:
    image: nginx
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.localhost`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls=true"
    networks:
      - tools
```

## 🔐 SSL Certificates (mkcert)

Generate trusted SSL certificates for local development using `mkcert.sh`.

### Quick Start
```bash
# Generate with defaults (cert.pem, key.pem)
./mkcert.sh

# Custom certificate names
./mkcert.sh --cert-file app.pem --key-file app-key.pem

# Specify domains via CSV
./mkcert.sh --domains "api.localhost,web.localhost,127.0.0.1"
```

### Domain Configuration
Domains can be specified in order of preference:
1. **Command line**: `--domains "api.localhost,web.localhost"`
2. **File**: `.domains` (one domain per line)
3. **Defaults**: `*.localhost localhost 127.0.0.1 ::1`

### Options
```
-h, --help              Show help
-f, --force             Skip confirmations
--cert-file FILE        Certificate output (default: cert.pem)
--key-file FILE         Key output (default: key.pem)
--domains CSV           Comma-separated domains
--file FILE             Custom domains file (default: .domains)
```

## 🚀 Getting Started

1. **Start Traefik**
   ```bash
   cd traefik
   podman compose up -d
   ```

2. **Generate SSL certificates**
   ```bash
   ./mkcert.sh --force
   ```

3. **Access dashboard**
   - https://dns.localhost

4. **Add to /etc/hosts** (if needed)
   ```
   127.0.0.1 dns.localhost ittools.localhost
   ```

## 🌐 Network

All services use the `tools` external network:
```bash
podman network create tools
```

Services automatically get `*.localhost` domains via Traefik's default rule.