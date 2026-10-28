# MediaVault

本地媒体**编目工程**：以官方运行时镜像为底座，本仓库提供双分区片库布局、精选元数据 providers 安装脚本与运维说明。

- **不是**上游应用源码的 fork / 移植。
- **是** docker-compose + 工程化脚手架：`primary`（A 向）与 `alternate`（B 向）两套 Library，配合 Community 精选索引包。

适合推到**私有** Git 仓库，再在目标电脑部署。目录命名刻意中性，外人打开不易联想到具体题材。

## 目录一览

| 路径 | 用途 |
|------|------|
| `library/primary/` | A 向媒体（`asia` / `western` / `indie`） |
| `library/alternate/` | B 向媒体（`studios` / `western` / `indie`） |
| `library/_inbox/` | 待整理投递区 |
| `config/` | 服务配置；`config/providers/` 为元数据索引器落盘处 |
| `metadata/` `cache/` `blobs/` `generated/` | 运行时数据（默认不进 Git） |
| `presets/` | 双库路径与推荐设置说明 |
| `docs/` | 中文文档 |
| `scripts/` | 引导 / 启停 / 安装 providers / 自检 |

容器内媒体根路径为 **`/data`**：

- primary → `/data/primary`
- alternate → `/data/alternate`

## 快速开始（Windows + Docker）

```powershell
cd <本仓库路径>
.\scripts\bootstrap.ps1
.\scripts\first-run-checklist.ps1
.\scripts\start.ps1
.\scripts\sanity-check.ps1
```

浏览器打开：<http://localhost:9999>（端口可用 `.env` 中 `MV_HOST_PORT` 修改）

首次进入 Web UI 后，按 [`presets/libraries.json.example`](presets/libraries.json.example) 添加两个库路径，并阅读 [`presets/recommended-settings.md`](presets/recommended-settings.md)。

## 日常更新

```powershell
git pull
.\scripts\install-providers.ps1 -Profile all
docker compose pull
```

（更新镜像后可再执行 `.\scripts\start.ps1`。）

## 文档

| 文档 | 内容 |
|------|------|
| [docs/architecture.md](docs/architecture.md) | 架构边界：镜像 vs 本仓库 |
| [docs/setup.md](docs/setup.md) | 部署与双库配置 |
| [docs/naming.md](docs/naming.md) | 文件 / 目录命名规范 |
| [docs/providers.md](docs/providers.md) | 精选 providers（模糊检索词） |
| [docs/git-publish.md](docs/git-publish.md) | 推私有 GitHub |

## 常用命令

```powershell
.\scripts\start.ps1
.\scripts\stop.ps1
.\scripts\first-run-checklist.ps1
.\scripts\install-providers.ps1 -Profile all
.\scripts\install-providers.ps1 -Profile primary
.\scripts\install-providers.ps1 -Profile alternate
.\scripts\export-provider-list.ps1
.\scripts\sanity-check.ps1
```

## 原则

1. 元数据来自**资料站 / 厂牌官网 / 社区索引包**，不要用下载站页面当源。
2. 镜像名、上游环境变量键、Community 包路径在仓库中以 **Base64** 存放，由 `start.ps1` / `install-providers.ps1` 首次解码写入 gitignored 的 `.env` 或本地目录。
3. 对外统一称 **MediaVault / 本地媒体编目服务**。
