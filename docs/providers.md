# 精选 Providers（模糊检索指南）

本页**不写**上游包的完整技术文件名。安装时在 UI 的 Community 源里用下表「搜索词」查找；或运行：

```powershell
# Windows
.\scripts\install-providers.ps1 -Profile all
.\scripts\install-providers.ps1 -Profile primary
.\scripts\install-providers.ps1 -Profile alternate
```

```bash
# Linux / macOS
./scripts/install-providers.sh -Profile all
./scripts/install-providers.sh -Profile primary
./scripts/install-providers.sh -Profile alternate
```

包名以 Base64 保存在 [`presets/provider-list.b64.txt`](../presets/provider-list.b64.txt)（ps1 / sh 共用；脚本内另有嵌入回退）。缺失则跳过并记入 `config/providers/_skip-log.txt`（gitignore）。

## primary（A 向）— 元数据站 / 目录

| 用途 | UI 搜索词（模糊） |
|------|-------------------|
| 亚洲资料站 A | `Library` + 亚洲编码站常见拼写首段 |
| 亚洲资料站 B | `Bus` |
| 亚洲资料站 C | `db`（注意大小写变体） |
| 亚洲资料站 D | `Database` |
| 亚洲官方目录 | `R18` 或 `r18` + `.dev` |
| 欧美演员/作品总目 | `IAFD` |
| 欧美碟片/数字目录 | `Empire`（选 A 向目录那一项） |

## primary — 厂牌示例

| 厂牌 | UI 搜索词 |
|------|-----------|
| Brazzers | `Brazzers` |
| BangBros | `BangBros` |
| Time 网络 | `Time`（选网络版包） |
| FakeHub | `FakeHub` |
| EvilAngel | `EvilAngel` |
| DigitalPlayground | `DigitalPlayground` |

## alternate（B 向）— 索引

| 用途 | UI 搜索词 |
|------|-----------|
| 经典索引 | `GEVI` |
| Empire 目录（B） | `Empire`（选 B 向那一项） |
| Wire 网络 | `Wire` |

## alternate — 厂牌

| 厂牌 | UI 搜索词 |
|------|-----------|
| FalconStudios | `Falcon` |
| HelixStudios | `Helix` |
| CockyBoys | `Cocky` |
| SeanCody | `SeanCody` |
| NextDoorStudios | `NextDoor` |
| HotHouse | `HotHouse` |
| Kink 线（Men） | `KinkMen` 或 `Kink` |
| Staxus | `Staxus` |
| Bromo | `Bromo` |
| ChaosMen | `Chaos` |
| ActiveDuty | `ActiveDuty` |
| CzechHunter | `CzechHunter` |
| BoyNapped | `BoyNapped` |
| BlackMaleMe | `BlackMale` |
| Men 系站点 | `Men`（注意勿装错同名） |

## 可选

| 用途 | UI 搜索词 | 所属 Profile |
|------|-----------|--------------|
| 双线厂牌 | `Biphoria` | primary（随 `-Profile primary` / `all`） |

## 安装方式优先级

1. **推荐**：Web UI → Settings → Metadata Providers → Community (stable) → 按上表搜索安装。
2. **备用**：`install-providers`（`.ps1` / `.sh`）`-Profile …`（clone/zip 社区库后按编码清单复制到 `config/providers`）。
3. 安装后在 UI 中 **Reload** providers，再 **Scan**。

导出编码清单到共享文件（仍为 Base64）：

```powershell
.\scripts\export-provider-list.ps1
```


## 本地骨架：asia-catalog

本仓自带轻量自定义 provider（亚洲作品编号解析 + URL 模板），**不是**第三方中文扩展的源码移植。

源码目录：`config/providers-src/asia-catalog/`  
安装到运行时目录：

```powershell
.\scripts\install-local-providers.ps1
```

```bash
./scripts/install-local-providers.sh
```

然后在 UI 中 **Reload** providers。说明见该目录下 `README.md` 与 [architecture.md](architecture.md)。


## 图册 / 图片元数据（albums）

Community (stable) 中不少包同时支持 **gallery**（图册）与 **image** 刮削（按 URL 或已有片段匹配）。安装后：

1. UI → Metadata Providers → Reload
2. 打开某本图册 → Edit → Scrape / 粘贴来源 URL

本地 `asia-catalog` 骨架目前偏作品编号（成片）；图册优先用 Community 包。若你指定资料站，可再在 `config/providers-src/` 加 album 骨架。
