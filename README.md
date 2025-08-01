# 🧼 docker_janitor

**Clean up your Docker environment — safely, predictably, and beautifully.**  
Preview first, log everything, and decide what goes — images, volumes, containers, cache, and networks.

---

## 🚀 Install via Homebrew

```bash
brew tap raymonepping/homebrew-docker-janitor-cli
brew install docker_janitor_cli
```

---

## 🧪 If This Sounds Like You...

> "Why is Docker using so much space?"  
> "Do I really need all these `<none>:<none>` images?"  
> "Wait… what's safe to delete again?"

You're not alone. So we built a **safe-first**, no-surprises janitor CLI with:

- ✅ Dry-run previews  
- 📁 Markdown summary exports  
- 🎯 Scope control (safe vs deep)  
- 🧠 Emoji-driven UX  

---

## 📖 Usage

```bash
docker_janitor --help
```

### 🔧 Example

```bash
docker_janitor --cleanup images,containers --preview --log logs/cleanup_summary.md --stats
```

---

## 🎯 Cleanup Targets

Use `--cleanup <targets>` to select what to clean up:

| Target      | Description                  |
|-------------|------------------------------|
| `images`    | Dangling `<none>` images     |
| `volumes`   | Unused, dangling volumes     |
| `containers`| Exited containers            |
| `cache`     | Docker build cache (Buildx)  |
| `networks`  | Unused Docker networks       |

---

## 🧼 Cleanup Modes

| Option         | Description                                      |
|----------------|--------------------------------------------------|
| `--preview`    | 🔍 Show what *would* be removed (default dryrun) |
| `--force`      | 💣 Actually delete the selected items            |
| `--scope safe` | ✅ Default mode — conservative                   |
| `--scope deep` | ⚠️  More aggressive — includes cache cleanup     |

---

## 📊 Stats and Logging

| Option              | Description                                               |
|---------------------|-----------------------------------------------------------|
| `--stats`           | 📊 Show disk usage before and after cleanup               |
| `--log <file>`      | 📝 Write the summary output to a specified Markdown file  |
| `--dryrun-summary`  | 📁 Export dryrun targets to `logs/dryrun_targets.md`      |

---

## ⚙️ Additional Flags

| Option        | Description              |
|---------------|--------------------------|
| `--quiet`     | 🤫 Suppress most output  |
| `--verbose`   | 🔍 Enable debug output   |
| `--version`   | 🔢 Show current version  |

---

## 🧾 Example Output (Preview)

```bash
docker_janitor --cleanup volumes,containers --preview --stats
```

```txt
🧼 Starting Docker Janitor (DRYRUN)...
📦  2 exited container(s) (3.5 MB)
📦  3 dangling volume(s)
📊 Disk Usage Stats
Before: 325.60 MB
After: 325.60 MB
Delta: ±0.00 B
✅ Docker janitor complete.
```

---

## 📁 Sample Dryrun Summary

File: `logs/dryrun_targets.md`

```md
## 🧼 Docker Janitor Summary
Generated: Fri Aug  1 19:01:05 CEST 2025

### 🧱 Containers
- abc123 (Exited)
- def456 (Created)

### 🖼️ Images
- <none>:<none> (34.2 MB)
```

---

## 🛡️ Safety First

- ✅ By default, runs in **dryrun/preview** mode — nothing is deleted.
- 💣 Use `--force` to actually remove items.
- 🧼 `--scope safe` avoids destructive operations.
- 📝 Export results with `--log` or `--dryrun-summary`.

---

## 🛠 Maintainer

**Raymon Epping**  
[github.com/raymonepping](https://github.com/raymonepping)  
[medium.com/@raymonepping](https://medium.com/@raymonepping)

---

## 💬 Inspired By

- Real-world container bloat 😅  
- Safe, reproducible DevOps practices  
- A cleaner local Docker experience  

---

## 🧠 Because Automation Should Automate Itself

© 2025 — Built for DevOps clarity, safety, and swagger.