# Changelog

## 1.9.18-pro.1 (2026-11-15)

### Initial Home Assistant Add-on Release
* **Multi-Arch Support**: Official pre-built images for both `linux/arm64` and `linux/amd64` architectures.
* **Home Assistant Ingress**: Fully integrated into Home Assistant sidebar with seamless sub-path fallback and WebSocket streaming.
* **Embedded Redis**: Integrated lightweight internal Redis server running on `127.0.0.1:6379`, zero external dependencies.
* **Storage Alignment**: All persistent assets (SQLite database, floorplans, icons, JWT secret, and install ID) unified under `/data`.
* **Supervisor Watchdog**: Integrated with native `/health` probe for automated self-healing.
