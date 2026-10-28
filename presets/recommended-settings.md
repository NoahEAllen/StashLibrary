# 推荐设置（UI 对照表）

以下键名按上游 Web UI 常见英文标签描述；**具体配置家目录路径不在此明文写出**，由 `scripts/start.ps1 / start.sh` 解码写入 `.env` 的 `MV_CONFIG_HOME`，compose 再挂载 `./config` → 该路径。

## Library

| 项 | 建议值 |
|----|--------|
| Library 1 | `/data/primary` |
| Library 2 | `/data/alternate` |
| 扫描 | 首次 Full Scan；之后按需 |

## Metadata Providers

| 项 | 建议 |
|----|------|
| Providers 目录 | 配置家目录下的 `providers` 子目录（与本仓库 `config/providers` 对应） |
| 来源 | Community (stable) |
| 安装集合 | 见 [docs/providers.md](../docs/providers.md)；或 `install-providers.ps1 / .sh -Profile primary|alternate|all` |

## 生成与缓存

| 卷 | 宿主机 | 容器 |
|----|--------|------|
| 元数据 DB 等 | `./metadata` | `/metadata` |
| 缓存 | `./cache` | `/cache` |
| 生成预览等 | `./generated` | `/generated` |
| 二进制 blob | `./blobs` | `/blobs` |

（上游环境变量键名同样由 `start.ps1` / `start.sh` 以 Base64 写入 `.env`，勿手抄进文档。）

## 区域

- 容器 `TZ=Asia/Shanghai`（已在 compose 中设置）。

## 安全

- 若服务暴露到局域网，请自行加反代鉴权或防火墙；默认假设仅本机访问。
