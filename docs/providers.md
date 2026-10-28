# 精选 Providers（模糊检索指南）

本页**不写**上游包的完整技术文件名。安装时在 UI 的 Community 源里用下表「搜索词」查找；或运行：

```powershell
.\scripts\install-providers.ps1 -Profile all
.\scripts\install-providers.ps1 -Profile primary
.\scripts\install-providers.ps1 -Profile alternate
```

包名以 Base64 保存在脚本的 `$PrimaryB64` / `$AlternateB64` 数组中；缺失则跳过并记入 `config/providers/_skip-log.txt`（gitignore）。

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
2. **备用**：`.\scripts\install-providers.ps1 -Profile …`（clone/zip 社区库后按编码清单复制到 `config/providers`）。
3. 安装后在 UI 中 **Reload** providers，再 **Scan**。

导出当前脚本内编码清单（仍为 Base64，不含明文包名文件）：

```powershell
.\scripts\export-provider-list.ps1
```
