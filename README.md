# MediaVault

本地媒体**编目工程**：以官方运行时镜像为底座，本仓库提供双分区片库布局（**视频 + 图册**）、精选元数据 providers 安装脚本与运维说明。

- **不是**上游应用源码的 fork / 移植（升级靠官方镜像 `docker compose pull`）。
- **是** docker-compose + 工程化脚手架：`primary`（A 向）与 `alternate`（B 向）两套 Library，Community 精选包、本地 `asia-catalog` 骨架，以及 GraphQL 自动扫描脚本。

适合推到**私有** Git 仓库，再在目标电脑部署。目录命名刻意中性，外人打开不易联想到具体题材。

## 平台脚本

| 平台 | 脚本 |
|------|------|
| **Windows** | `scripts/*.ps1`（PowerShell 5.1+） |
| **Linux / macOS** | `scripts/*.sh`（bash） |

两边功能对等；精选包名共用 [`presets/provider-list.b64.txt`](presets/provider-list.b64.txt)。

## 目录一览

| 路径 | 用途 |
|------|------|
| `library/primary/` | A 向媒体（`asia` / `western` / `indie` / `albums` 图册） |
| `library/alternate/` | B 向媒体（`studios` / `western` / `indie` / `albums` 图册） |
| `library/_inbox/` | 待整理投递区 |
| `config/` | 服务配置；`providers/` 落盘处；`providers-src/` 本地 provider 源 |
| `metadata/` `cache/` `blobs/` `generated/` | 运行时数据（默认不进 Git） |
| `presets/` | 双库路径、共享 Base64 清单与推荐设置 |
| `docs/` | 中文文档 |
| `scripts/` | 引导 / 启停 / providers / 本地骨架 / 自动扫描 / 更新 / 自检（ps1 + sh） |

容器内媒体根路径为 **`/data`**：

- primary → `/data/primary`
- alternate → `/data/alternate`

## 快速开始

### Windows

```powershell
cd <本仓库路径>
.\scripts\bootstrap.ps1
.\scripts\first-run-checklist.ps1
.\scripts\start.ps1
.\scripts\sanity-check.ps1
```

### Linux / macOS

```bash
cd <本仓库路径>
chmod +x scripts/*.sh
./scripts/bootstrap.sh
./scripts/first-run-checklist.sh
./scripts/start.sh
./scripts/sanity-check.sh
```

浏览器打开：<http://localhost:9999>（端口可用 `.env` 中 `MV_HOST_PORT` 修改）

首次进入 Web UI 后，按 [`presets/libraries.json.example`](presets/libraries.json.example) 添加两个库路径，并阅读 [`presets/recommended-settings.md`](presets/recommended-settings.md)。

API Key 写入 `.env` 的 `MV_API_KEY` 后，可用 `scripts/auto-scan` / `watch-inbox` 触发 GraphQL `metadataScan`（见 setup 文档）。本地编号骨架：`install-local-providers`。



### 插件与增量监视

- 推荐 Plugins（浏览 / 同类 / 分类 / 找源下载）：[docs/plugins.md](docs/plugins.md) / [presets/recommended-plugins.md](presets/recommended-plugins.md)
- 可选旁路 compose 示例：`docker-compose.whisparr.yml.example`、`docker-compose.ai-overhaul.yml.example`、`docker-compose.stash-sense.yml.example`（不默认启动；勿提交密钥）
- 三目录监视：`scripts/watch-media`（配合 `auto-scan`，默认不 Rescan）
- 番号资料站链接：`scripts/code-search-links`
- 演员待寻片单：[docs/wishlist.md](docs/wishlist.md)

## 日常更新

推荐一键：

```powershell
# Windows
.\scripts\update.ps1
.\scripts\update.ps1 -SkipProviders
```

```bash
# Linux / macOS
./scripts/update.sh
./scripts/update.sh -SkipProviders
```

等价手动步骤：

```text
git pull
install-providers -Profile all
docker compose pull
start（ensure .env + up -d）
```

## 文档

| 文档 | 内容 |
|------|------|
| [docs/architecture.md](docs/architecture.md) | 架构边界：镜像 vs 本仓库 |
| [docs/setup.md](docs/setup.md) | 部署与双库配置（Windows / Linux） |
| [docs/naming.md](docs/naming.md) | 文件 / 目录命名规范 |
| [docs/providers.md](docs/providers.md) | 精选 providers（模糊检索词） |
| [docs/plugins.md](docs/plugins.md) | Plugins：浏览 / 同类 / 分类 / 缺片下载 / AI Overhaul |
| [docs/git-publish.md](docs/git-publish.md) | 推私有 GitHub |

## 常用命令

```powershell
# Windows
.\scripts\start.ps1
.\scripts\stop.ps1
.\scripts\update.ps1
.\scripts\first-run-checklist.ps1
.\scripts\install-providers.ps1 -Profile all
.\scripts\install-providers.ps1 -Profile primary
.\scripts\install-providers.ps1 -Profile alternate
.\scripts\install-local-providers.ps1
.\scripts\auto-scan.ps1
.\scripts\watch-inbox.ps1 -Once
.\scripts\export-provider-list.ps1
.\scripts\sanity-check.ps1
```

```bash
# Linux / macOS
./scripts/start.sh
./scripts/stop.sh
./scripts/update.sh
./scripts/first-run-checklist.sh
./scripts/install-providers.sh -Profile all
./scripts/install-providers.sh -Profile primary
./scripts/install-providers.sh -Profile alternate
./scripts/install-local-providers.sh
./scripts/auto-scan.sh
./scripts/watch-inbox.sh --Once
./scripts/sanity-check.sh
```

## 原则

1. 元数据来自**资料站 / 厂牌官网 / 社区索引包**，不要用下载站页面当源。
2. 镜像名、上游环境变量键、Community 包路径在仓库中以 **Base64** 存放；`start` / `install-providers` 首次解码写入 gitignored 的 `.env` 或本地目录。精选包名清单：`presets/provider-list.b64.txt`。
3. 对外统一称 **MediaVault / 本地媒体编目服务**。
