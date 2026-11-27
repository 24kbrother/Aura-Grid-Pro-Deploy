# Changelog

## 1.9.24-pro (2026-11-28)

### Design & Usability
- Unified Obsidian dual-palette theme (`obsidian-cobalt` and `obsidian-amber`) across Settings and top navigation banner, with an upgraded Bento Studio appearance page.
- Extended the Settings font-scale selector (`small` / `medium` / `large`) across the Settings sidebar, subpanels, and modals without affecting the main dashboard or information sidebar.
- Extracted the Page Size Adjuster into a backdrop-free floating card (`Teleport` outside the scaled shell) so dragging the width slider stays completely steady while previewing live canvas scaling.
- Improved Settings sidebar visual hierarchy (larger group headings with divider lines), replaced the developer edit mode icon with a wrench, and refined toolbar typography.

## 1.9.21-pro (2026-11-24)

### Improvements & Fixes
- Enabled `homeassistant_api: true` in add-on manifest for seamless Supervisor / Home Assistant core API communication.
- Fixed member logout and APNs account binding cleanup in frontend client.
- Improved SQLite journal recovery and automatic cleanup of failed backup directories on startup.

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
