# 插件（Plugins）

与 **Metadata Providers / 刮削器** 不是同一套东西：

| | Plugins | Metadata Providers |
|--|---------|-------------------|
| 设置页 | Settings → **Plugins** | Settings → **Metadata Providers** |
| 作用 | 改 UI、钩子任务、监视磁盘、通知等 | 从资料站补标题/演员/封面 |
| 默认源 | Community (**stable**) | Community (stable) |

本页只谈 Plugins。刮削器仍见 [providers.md](providers.md)。

## 安装步骤

1. Web UI → **Settings → Plugins**
2. Available Plugins 确认有 **Community (stable)**  
   源地址一般为：`https://stashapp.github.io/CommunityScripts/stable/index.yml`
3. 用下表「UI 搜索词」查找 → **Install**
4. 需要时在 Installed 里启用；部分插件要在 **Tasks** 或插件自己的配置里再开一次
5. 改完后如提示，**Reload** 插件

部署机（如 `E:\stashLibrary`）上操作即可；本仓库只保存推荐清单与脚本，**不会**把上游插件源码 vendoring 进 Git。

## 推荐清单（优先装）

完整勾选表见 [`presets/recommended-plugins.md`](../presets/recommended-plugins.md)。

### File Monitor

- **做什么**：监视片库目录变化，有新文件时触发扫描相关流程（具体行为以插件说明为准）。
- **为何推荐**：减少手动点 Scan；与仓库的 `watch-media` / `auto-scan` 可并存——插件偏「服务内」，脚本偏「宿主机/API」。
- **注意**：大目录首次索引可能较忙；确认监视路径覆盖你实际挂载的 media 根，而不是误监视 `cache/` / `generated/`。

### Stash Notifications

- **做什么**：提醒 Community 刮削器/插件有更新，避免多台机器漏更。
- **为何推荐**：你有双机（工作区改仓、部署机跑服务），版本漂移时很有用。

### Scene Marker Tags to Scene

- **做什么**：把标记点（Markers）上用到的标签同步到场景，方便以后按标签筛选。
- **为何推荐**：打点多了以后，不必再给场景手工补同一套标签。

## 可选：更重的工具

### AI Tagger

- **做什么**：用视觉/模型给场景自动打标签（识别内容特征）。
- **安装**：仍在 Plugins → Community (stable) 搜 `AI Tagger`（或当前包显示名）。
- **依赖**：多为 **Python 插件**，可能要额外模型文件、足够内存/可选 GPU；以插件自带 README 为准。
- **隐私**：分析在你配置的运行环境里完成（本机或你指定的后端）。上线前先在小样本上试，确认效果与资源占用再全库跑。
- **建议**：等增量扫描与刮削稳定后再装；不是整理片库的前提。

### 第三方重命名（renamer）

- **常见名**：社区常提到 `renamerOnUpdate` 一类「场景元数据更新后按模板改文件名」的插件；**以 Community 源里当前仍维护的包名为准**（UI 搜 `renamer` / `rename`）。
- **风险**：改的是磁盘上的文件名。务必：
  1. 先备份或先在副本目录试；
  2. 模板确认后再对全库启用；
  3. 关闭「不可逆批量」直到你检查过若干条结果。
- **与本仓命名**：优先遵循 [naming.md](naming.md)。重命名插件是可选增强，不是默认工作流。

## 与本仓脚本的分工

| 需求 | 更合适的方式 |
|------|----------------|
| 三目录（TEMP/云盘/下载）有新片就扫 | `scripts/watch-media` + `auto-scan`（不带 Rescan） |
| 只盯投递区 | `scripts/watch-inbox` |
| 插件监视 + 通知 | 本页三个推荐插件 |
| 番号 → 资料站搜索链接 | `scripts/code-search-links` |
| 演员想下但未入库的片名 | [wishlist.md](wishlist.md) |

部署机应用：`git pull` 后按本页装插件；脚本用法见 [setup.md](setup.md)「自动扫描 / 监视」一节。
