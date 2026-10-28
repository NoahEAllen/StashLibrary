# MediaVault

本地媒体编目脚手架：一个实例里用两个分区管理片库——**primary（A 向）** 与 **alternate（B 向）**。媒体只放在 `library/`，配置与元数据索引器在 `config/`。

适合：先推到自己的 Git 仓库，再在另一台机器用 Docker 拉起。文件夹对外看起来就是普通「媒体编目 / catalog」工程。

## 目录

| 路径 | 用途 |
|------|------|
| `library/primary/` | A 向媒体（asia / western / indie） |
| `library/alternate/` | B 向媒体（studios / western / indie） |
| `library/_inbox/` | 待整理投递区 |
| `config/` | 服务配置与 providers（元数据索引器） |
| `metadata/` `cache/` `blobs/` `generated/` | 运行时数据 |

容器内媒体根路径为 **`/data`**：

- primary → `/data/primary`
- alternate → `/data/alternate`

## 启动（Windows + Docker）

```powershell
cd <本仓库路径>
.\scripts\bootstrap.ps1
.\scripts\start.ps1
```

浏览器：<http://localhost:9999>

分步说明：[`docs/setup.md`](docs/setup.md) · 命名：[`docs/naming.md`](docs/naming.md) · 索引器：[`docs/providers.md`](docs/providers.md)

## 两个分区怎么用

- **primary（A 向）**：亚洲成片、欧美主流厂牌、独立/业余等 → `library/primary/...`
- **alternate（B 向）**：厂牌成片、欧美 alternate 线、独立/业余等 → `library/alternate/...`

建议在 Web UI 里建 **两个 Library 路径**，分别指向 `/data/primary` 与 `/data/alternate`。

## 元数据原则

- 用 **资料站 / 厂牌官网** 做编目（出品编号、厂牌页、社区元数据库等）。
- 不要用下载站页面当元数据源（人机验证、跳转页不稳定）。
- 推荐在 UI：**Settings → Metadata Providers → Community (stable)** 安装索引器。`scripts/install-providers.ps1` 仅作离线/手动备用。

## 常用命令

```powershell
.\scripts\start.ps1
.\scripts\stop.ps1
```

改端口：复制 `.env.example` 为 `.env`，修改 `MV_HOST_PORT`。

镜像技术名在 compose 中保留上游官方镜像；对外说明统一称 **MediaVault / 本地媒体编目服务**。

## 推送到私有仓库

见 [docs/git-publish.md](docs/git-publish.md)。本工作电脑只提交源码，部署放到目标机。

