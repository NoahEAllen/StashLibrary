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
日常安装索引器：UI → Settings → Metadata Providers → **Community (stable)**，按 [providers.md](providers.md) 的模糊关键词搜索安装。

离线批量备用：

```powershell
.\scripts\install-providers.ps1
```

### 7. 自检

```powershell
.\scripts\sanity-check.ps1
```

## 停止

```powershell
.\scripts\stop.ps1
```

## 改端口

编辑 `.env` 中 `MV_HOST_PORT`，再 `start.ps1`。
