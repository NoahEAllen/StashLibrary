# 分步安装

前提：本机已装 Docker Desktop（或 Docker Engine + Compose）。

## 1. 准备目录

```powershell
cd <本仓库路径>
.\scripts\bootstrap.ps1
```

会检查并补齐 `library`、`config`、`metadata` 等目录。

## 2. 启动 MediaVault

```powershell
.\scripts\start.ps1
```

等价于：`docker compose up -d`。

稍等后打开：<http://localhost:9999>

按向导完成基础设置即可（生成路径等已由环境变量指向容器内目录）。

## 3. 添加两个媒体库路径

在 Web UI 的 Library 设置中：

1. 添加 `/data/primary` — A 向（primary）
2. 添加 `/data/alternate` — B 向（alternate）

对应本机：

- `.\library\primary` → `/data/primary`
- `.\library\alternate` → `/data/alternate`

`_inbox` 建议先不加入 Library，整理后再挪入分区。

## 4. 安装元数据索引器（providers）

**推荐（UI）：**

1. **Settings → Metadata Providers**
2. 使用 **Community (stable)** 源
3. 按 [`providers.md`](providers.md) 搜索安装所需包
4. 安装后执行 **重新加载 / Reload**（若界面有该按钮）

**备用（脚本）：**

```powershell
.\scripts\install-providers.ps1
```

将精选包写入 `config\providers`，缺失项会跳过并打印。

然后在 UI：**Settings → System → Application Paths**，把 Scrapers Path 设为 `/root/.stash/providers`（对应宿主机 `config\providers`），再 Reload providers。

## 5. 放入媒体并扫描

1. 按 [`naming.md`](naming.md) 放入 `library\primary\...` 或 `library\alternate\...`
2. 在 UI 执行 **Scan**
3. 对条目用对应 provider（按文件名片段或 URL）补全封面、演职、厂牌

## 6. 日常

```powershell
.\scripts\start.ps1
.\scripts\stop.ps1
```

升级：

```powershell
docker compose pull
docker compose up -d
```

## 端口

默认 `9999`。复制 `.env.example` → `.env`，设置 `MV_HOST_PORT`，再启动。

