# 架构说明

## 一句话

**运行时 = 官方容器镜像；本仓库 = 目录布局 + providers 子集清单 + 本地 provider 骨架 + 运维脚本。**  
本仓库**不包含**上游应用的 Go（或其它语言）源码，也不做 fork。

## 为何不 vendoring upstream 上游源码

| 原因 | 说明 |
|------|------|
| 许可证与体积 | 上游是完整 Go 工程，vendoring 会让私有仓膨胀，且升级成本高。 |
| 升级路径清晰 | 官方镜像已含 Web UI、扫描、编目库与 GraphQL；用 `docker compose pull` 即可跟进。 |
| 本仓职责 | 双分区片库、精选 Community 包安装、本地自定义 provider、API 自动扫描脚本。 |

### 如何升级运行时

```bash
# Linux / macOS（或用 update.sh，内部已含 compose pull）
docker compose pull
./scripts/start.sh

# 一键（推荐）
./scripts/update.sh
./scripts/update.sh -SkipProviders
```

```powershell
docker compose pull
.\scripts\start.ps1
.\scripts\update.ps1
```

`update` 脚本顺序：`git pull` →（可选）装 providers → `compose pull` → `start`。  
镜像名仍由 `start` 写入 gitignored 的 `.env`，仓库内无明文镜像字符串。

## 分层

```
┌─────────────────────────────────────────────┐
│  MediaVault 仓库（本工程）                    │
│  · library/primary + library/alternate      │
│  · config/providers 落盘约定                 │
│  · config/providers-src（本地 provider 源）  │
│  · scripts（bootstrap / start / auto-scan…）│
│  · docs + presets                           │
└──────────────────┬──────────────────────────┘
                   │ docker compose
                   ▼
┌─────────────────────────────────────────────┐
│  官方运行时镜像（名称经 Base64 注入 .env）     │
│  · Web UI / 扫描 / 编目数据库 / GraphQL       │
│  · 读取 /data/primary 与 /data/alternate    │
└─────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  社区元数据仓库（URL 经 Base64；按需拉取子集） │
│  + 本仓 asia-catalog 等本地 provider 骨架    │
└─────────────────────────────────────────────┘
```

## 双分区模型

| 分区 | 目录 | 容器路径 | 用途（中性表述） |
|------|------|----------|------------------|
| primary | `library/primary/` | `/data/primary` | A 向片库 |
| alternate | `library/alternate/` | `/data/alternate` | B 向片库 |
| inbox | `library/_inbox/` | `/data/_inbox` | 未分类投递（可不建库） |

建议在 UI 中创建**两个 Library**，便于标签、厂牌与扫描策略分开。

## 本地 provider 骨架（asia-catalog）

路径：`config/providers-src/asia-catalog/`。

- **定位**：面向亚洲出品**作品编号**解析与资料站 URL 模板的轻量自定义 provider（YAML + 可选 Python）。
- **不是**某中文社区编目扩展的源码搬运，而是同一类需求的**可维护骨架**：编号提取 → 填入 URL 模板 → 返回场景片段占位，便于你后续接真实解析。
- 安装：`scripts/install-local-providers` 拷到 `config/providers/asia-catalog/`，再在 UI 中 Reload。

详见 `config/providers-src/asia-catalog/README.md` 与 [providers.md](providers.md)。

## 自动扫描进库

不必每次都打开 UI 点 Scan：

1. 在 UI 生成 **API Key**，写入 `.env` 的 `MV_API_KEY`。
2. `scripts/auto-scan` 调用 GraphQL `metadataScan`（默认 `http://localhost:9999/graphql`）。
3. 可选 `scripts/watch-inbox` 轮询 `_inbox`，发现新媒体后触发扫描。

详见 [setup.md](setup.md)「自动扫描」一节。

## 本仓库明确不做的事

- 不 vendoring / 不编译上游源码（升级靠官方镜像 `compose pull`）。
- 不做完整第三方中文扩展的源码移植；只提供本地编号解析骨架。
- 不在 Git 中存放媒体文件、运行时库、`.env` 明文镜像名。
- 不在文档或文件名中暴露敏感题材关键词（见 `sanity-check`）。

## 图册与图片

运行时原生支持图片与图册（文件夹成册、zip、`.forcegallery`）。本仓库在 `library/*/albums` 提供约定路径；刮削走 Community gallery/image providers，与成片 providers 同一套安装通道。
