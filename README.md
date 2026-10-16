# Danno Projects (dannoprojects.com)

Personal portfolio and technical blog built with [Hugo](https://gohugo.io/) and the [Toha](https://toha-guides.netlify.app/) theme.

## Local Development

The site runs in a Docker container using **Rancher Desktop**:

```bash
# 1. Start Rancher Desktop (if not already running)
open -a "Rancher Desktop"

# 2. Launch the Hugo development server
docker compose up -d

# 3. View the site at:
# http://localhost:1313
```

- Hugo auto-reloads changes with a 700ms polling watcher.
- Production builds and CI deployments are managed automatically via Netlify and GitHub Actions.
