# 部署指南

## 前置条件

- Docker Desktop / Docker Engine
- **Windows**：PowerShell 5.1+（用 `scripts/*.ps1`）
- **Linux / macOS**：bash（用 `scripts/*.sh`，先 `chmod +x scripts/*.sh`）
- 可选：`git`（`install-providers` 优先用 git；没有则自动下 zip）
- 自动扫描可选：`curl`（Linux）或 PowerShell `Invoke-RestMethod`

## 步骤

### 1. 取得本仓库

从私有 Git 克隆，或解压分发包到目标目录。

### 2. 引导目录

Windows：

```powershell
cd <MediaVault 根目录>
.\scripts\bootstrap.ps1
.\scripts\first-run-checklist.ps1
.\scripts\first-run-checklist.ps1 -OpenDocs
```

Linux / macOS：

```bash
cd <MediaVault 根目录>
./scripts/bootstrap.sh
./scripts/first-run-checklist.sh
./scripts/first-run-checklist.sh --OpenDocs
```

### 3. 启动

```powershell
.\scripts\start.ps1
```

```bash
./scripts/start.sh
```

脚本会：

1. 若无 `.env`，从 `.env.example` 复制；
2. 解码写入 `MV_IMAGE`、`MV_CONFIG_HOME` 及上游路径类环境变量（**不出现在仓库明文**）；
3. 执行 `docker compose up -d`。

### 4. 打开 UI

浏览器访问 `http://localhost:9999`（或你在 `.env` 设的 `MV_HOST_PORT`）。

### 5. 添加两个 Library

参考 [`presets/libraries.json.example`](../presets/libraries.json.example)：

| 显示名建议 | 路径 |
|------------|------|
| Primary | `/data/primary` |
| Alternate | `/data/alternate` |

子目录约定见 [naming.md](naming.md)。视频与**图册**可放在同一 Library 下：图片放 `primary/albums` 或 `alternate/albums`（子文件夹或 zip）。

扫描时在 UI 勾选 **Images**；并开启「从含图片的文件夹创建图册」。也可用空文件 `.forcegallery` 强制某文件夹成册。

### 6. 配置 providers 路径与推荐项

见 [`presets/recommended-settings.md`](../presets/recommended-settings.md)。  
在 Settings 中将 **Providers Path** 指向配置家目录下的 `providers`（与本仓库 `config/providers` 对应）。

日常安装索引器：UI → Settings → Metadata Providers → **Community (stable)**，按 [providers.md](providers.md) 的模糊关键词搜索安装。

离线 / 批量备用（按分区；包名读自 `presets/provider-list.b64.txt`）：

```powershell
.\scripts\install-providers.ps1                  # 默认 -Profile all
.\scripts\install-providers.ps1 -Profile primary
.\scripts\install-providers.ps1 -Profile alternate
```

```bash
./scripts/install-providers.sh -Profile all
./scripts/install-providers.sh -Profile primary
./scripts/install-providers.sh -Profile alternate
```

本地自定义骨架（亚洲作品编号，`asia-catalog`）：

```powershell
.\scripts\install-local-providers.ps1
```

```bash
./scripts/install-local-providers.sh
```

缺失包会跳过，日志写入 `config/providers/_skip-log.txt`（已 gitignore，勿提交）。

安装后在 UI 中 **Reload** providers，再对两个库执行 **Scan**（或用下方自动扫描）。

### 7. 自检

```powershell
.\scripts\sanity-check.ps1
```

```bash
./scripts/sanity-check.sh
```

## 自动扫描（GraphQL）

不必每次打开 UI 点 Scan。编目服务提供 GraphQL mutation `metadataScan`。

### 7.1 生成 API Key 并写入 `.env`

1. 打开 Web UI → **Settings → Security / Authentication**（以你安装的版本菜单为准）。
2. 生成 **API Key**，复制。
3. 编辑仓库根目录 `.env`（若无则先跑一次 `start`），增加或修改：

```env
MV_API_KEY=粘贴你的密钥
# 可选；默认按 MV_HOST_PORT 拼 localhost
# MV_GRAPHQL_URL=http://localhost:9999/graphql
```

`.env` 已被 gitignore，不要提交密钥。

### 7.2 手动触发扫描

```powershell
.\scripts\auto-scan.ps1
.\scripts\auto-scan.ps1 -Paths "/data/primary,/data/alternate"
.\scripts\auto-scan.ps1 -Paths "/data/_inbox" -Rescan
```

```bash
./scripts/auto-scan.sh
./scripts/auto-scan.sh --Paths /data/primary,/data/alternate
./scripts/auto-scan.sh --Paths /data/_inbox --Rescan
```

成功时响应里会有 `metadataScan` 返回的 job id。

### 7.3 监视投递区（可选）

把新媒体丢进 `library/_inbox/`，脚本轮询后只扫容器路径 `/data/_inbox`：

```powershell
.\scripts\watch-inbox.ps1 -Interval 60
.\scripts\watch-inbox.ps1 -Once
```

```bash
./scripts/watch-inbox.sh --Interval 60
./scripts/watch-inbox.sh --Once
```

### 7.4 计划任务 / cron / Task Scheduler（中性示例）

**Linux crontab**（每小时整点扫一次全库；请先写好 `MV_API_KEY`）：

```cron
0 * * * * cd /path/to/MediaVault && ./scripts/auto-scan.sh >> cache/auto-scan.log 2>&1
```

持续监视 inbox（建议用 systemd user service 或 screen/tmux；下面为每分钟检查一次的简化 cron）：

```cron
* * * * * cd /path/to/MediaVault && ./scripts/watch-inbox.sh --Once >> cache/watch-inbox.log 2>&1
```

**Windows 任务计划程序**：操作选「启动程序」，程序填 `powershell.exe`，参数示例：

```text
-NoProfile -ExecutionPolicy Bypass -File "D:\path\to\MediaVault\scripts\auto-scan.ps1"
```

触发器可设为每小时或登录后。

## 日常更新

一键（`git pull` + providers + `compose pull` + `up -d`）：

```powershell
.\scripts\update.ps1
.\scripts\update.ps1 -SkipProviders
```

```bash
./scripts/update.sh
./scripts/update.sh -SkipProviders
```

仅升级官方运行时镜像：

```bash
docker compose pull
./scripts/start.sh
```

## 停止

```powershell
.\scripts\stop.ps1
```

```bash
./scripts/stop.sh
```

## 改端口

编辑 `.env` 中 `MV_HOST_PORT`，再执行对应平台的 `start` 脚本。

## 插件（Plugins）

与 Metadata Providers 不同。安装说明见 [plugins.md](plugins.md)；勾选表见 [`presets/recommended-plugins.md`](../presets/recommended-plugins.md)。

建议优先：`File Monitor`、`Stash Notifications`、`Scene Marker Tags to Scene`。  
可选较重：`AI Tagger`、第三方 renamer（慎用，见 plugins 文档）。

## 增量监视三目录

配置 `.env` 中 `MV_MEDIA_TEMP` / `MV_MEDIA_CLOUD` / `MV_MEDIA_DL` 后：

```powershell
.\scripts\watch-media.ps1
.\scripts\watch-media.ps1 -IncludeInbox -Once
```

```bash
./scripts/watch-media.sh
./scripts/watch-media.sh --IncludeInbox --Once
```

仍可用 `watch-inbox` 只盯 `_inbox`。`auto-scan` 支持 `-MinModTime "<24h"`（或 `--MinModTime`）只扫近期修改的文件。

## 番号搜索链接与 Wish list

```powershell
.\scripts\code-search-links.ps1 "ABCD-123"
.\scripts\wishlist-list.ps1
```

说明：[wishlist.md](wishlist.md)。

