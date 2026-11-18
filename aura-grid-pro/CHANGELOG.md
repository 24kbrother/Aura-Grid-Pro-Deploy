# Changelog

## 1.9.20-pro (2026-11-18)

### Security and reliability
- Added independent, expiring APNs authorization for Pro notifications, with background credential renewal.
- Lite installations remain unable to use APNs.
- Existing iOS apps do not need a source update or device re-pairing.
- Existing Pro installations can use the legacy authorization path until 2027-01-01 00:00 China Standard Time.

## 1.9.18-pro.1 (2026-11-15)

### Initial Home Assistant Add-on Release
* **Multi-Arch Support**: Official pre-built images for both `linux/arm64` and `linux/amd64` architectures.
* **Home Assistant Ingress**: Fully integrated into Home Assistant sidebar with seamless sub-path fallback and WebSocket streaming.
* **Embedded Redis**: Integrated lightweight internal Redis server running on `127.0.0.1:6379`, zero external dependencies.
* **Storage Alignment**: All persistent assets (SQLite database, floorplans, icons, JWT secret, and install ID) unified under `/data`.
* **Supervisor Watchdog**: Integrated with native `/health` probe for automated self-healing.
