# 部署指南

## 前置条件

- Windows（或可跑 PowerShell 的环境）+ Docker Desktop / Docker Engine
- 可选：`git`（`install-providers.ps1` 优先用 git；没有则自动下 zip）

## 步骤

### 1. 取得本仓库

从私有 Git 克隆，或解压分发包到目标目录（例如 `D:\desktopfiles\MediaVault`）。

### 2. 引导目录

```powershell
cd <MediaVault 根目录>
.\scripts\bootstrap.ps1
```

可选：打印首次勾选清单（不启动 Docker）：

```powershell
.\scripts\first-run-checklist.ps1
.\scripts\first-run-checklist.ps1 -OpenDocs   # 用记事本打开本文档
```

### 3. 启动

```powershell
.\scripts\start.ps1
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

子目录约定见 [naming.md](naming.md)。

### 6. 配置 providers 路径与推荐项

见 [`presets/recommended-settings.md`](../presets/recommended-settings.md)。  
在 Settings 中将 **Providers Path** 指向配置家目录下的 `providers`（与本仓库 `config/providers` 对应）。

日常安装索引器：UI → Settings → Metadata Providers → **Community (stable)**，按 [providers.md](providers.md) 的模糊关键词搜索安装。

离线 / 批量备用（按分区）：

```powershell
.\scripts\install-providers.ps1                  # 默认 -Profile all
.\scripts\install-providers.ps1 -Profile primary
.\scripts\install-providers.ps1 -Profile alternate
```

缺失包会跳过，日志写入 `config/providers/_skip-log.txt`（已 gitignore，勿提交）。

安装后在 UI 中 **Reload** providers，再对两个库执行 **Scan**。

### 7. 自检

```powershell
.\scripts\sanity-check.ps1
```

## 日常更新

```powershell
git pull
.\scripts\install-providers.ps1 -Profile all
docker compose pull
.\scripts\start.ps1
```

## 停止

```powershell
.\scripts\stop.ps1
```

## 改端口

编辑 `.env` 中 `MV_HOST_PORT`，再 `start.ps1`。
