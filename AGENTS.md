# Workspace Instructions & Infrastructure Guide

## Project Overview
- **Project**: Hugo-based personal portfolio site (Toha theme) for Dan Rowe ([dannoprojects.com](https://www.dannoprojects.com)).
- **Repository Root**: `/Users/danrowe/CodeRepo/web`

---

## Local Development Infrastructure

### Runtime: Rancher Desktop (macOS)
- **Container Engine**: Rancher Desktop with Moby (Docker runtime).
- **Binary Paths**:
  - Docker CLI: `/Users/danrowe/.rd/bin/docker` (or `~/.rd/bin/docker`)
  - Docker Compose: `/Users/danrowe/.rd/bin/docker compose`
  - Rancher CLI: `/Users/danrowe/.rd/bin/rdctl`
- **Host Architecture**: Apple Silicon (Mac) / macOS zsh.
- **Note on Hugo**: Hugo is **not** installed directly on the host machine. The development server runs entirely inside a Docker container configured in `compose.yaml` and `Dockerfile`.

---

## How to Manage the Local Environment

### 1. Check & Start Rancher Desktop
Before starting the web container, verify Rancher Desktop is running:
```bash
pgrep -fl "Rancher Desktop"
```
If not running, launch it:
```bash
open -a "Rancher Desktop"
```
Verify the backend VM and Docker socket are ready:
```bash
/Users/danrowe/.rd/bin/rdctl api /v1/backend_state
# Expected: {"vmState":"STARTED","locked":false}
```

### 2. Start the Hugo Dev Container
Launch the container in detached mode:
```bash
/Users/danrowe/.rd/bin/docker compose up -d
```
- **Container Name**: `dannoprojects-web`
- **Port**: `1313:1313`
- **URL**: [http://localhost:1313](http://localhost:1313) or [http://127.0.0.1:1313](http://127.0.0.1:1313)

### 3. Verify Build & Live Server
Check build logs:
```bash
/Users/danrowe/.rd/bin/docker logs --tail 30 dannoprojects-web
```
Verify HTTP response:
```bash
curl -I http://127.0.0.1:1313/
```

### 4. Stop the Environment
```bash
/Users/danrowe/.rd/bin/docker compose down
```

---

## Live Editing & Hot Reload
- The repository root is mounted into the container at `/src`.
- The container runs Hugo with `--watch --poll 700ms`.
- Edits made to data files (`data/en/sections/*.yaml`), site configs (`hugo.yaml`, `data/en/site.yaml`), layouts, and posts (`content/posts/`) trigger automatic rebuilds without needing to restart the container.
- If dependency or module issues occur, restart the container:
  ```bash
  /Users/danrowe/.rd/bin/docker compose restart
  ```
