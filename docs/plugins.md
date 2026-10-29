# 插件（Plugins）

与 **Metadata Providers / 刮削器** 不是同一套东西：

| | Plugins | Metadata Providers |
|--|---------|-------------------|
| 设置页 | Settings → **Plugins** | Settings → **Metadata Providers** |
| 作用 | 改 UI、钩子任务、监视磁盘、通知、找同类/缺片等 | 从资料站补标题/演员/封面 |
| 默认源 | Community (**stable**) | Community (stable) |

本页只谈 Plugins，以及「浏览 / 搜同类 / 识别分类 / 找相关与下载」所需的旁路服务（Whisparr、AI Server、Stash Sense）。刮削器仍见 [providers.md](providers.md)。

部署机上操作即可；本仓库只保存推荐清单、compose 示例与脚本，**不会**把上游插件源码 vendoring 进 Git。

## 插件源（Sources）

在 **Settings → Plugins → Available Plugins → Add Source** 按需添加：

| 源名称建议 | URL | 用途 |
|------------|-----|------|
| Community (stable) | `https://stashapp.github.io/CommunityScripts/stable/index.yml` | 默认源；hotCards、AI Overhaul、DupFileManager 等 |
| Carrot Waxxer | `https://carrotwaxr.github.io/stash-plugins/stable/index.yml` | Missing Scenes、Scene Matcher、Tag Manager |
| Stash Sense | `https://carrotwaxr.github.io/stash-sense/plugin/index.yml` | Stash Sense 插件（需另起 sidecar 容器） |

## 安装步骤

1. Web UI → **Settings → Plugins**
2. 确认已有上表所需源 → **Reload**
3. 用下表「UI 搜索词」查找 → **Install**
4. 需要时在 Installed 里启用；部分插件要在 **Tasks** 或插件配置里再开一次
5. 改完后如提示，**Reload** 插件

完整勾选表见 [`presets/recommended-plugins.md`](../presets/recommended-plugins.md)。

## 推荐落地顺序（浏览 / 同类 / 分类 / 找源下载）

按依赖从轻到重，建议按此推进（**不做 SFW 遮罩类插件**）：

| 阶段 | 做什么 | 对应条目 |
|------|--------|----------|
| **1. 底座** | 开 phash；配 StashDB / TPDB / FansDB；装浏览增强 | 下方「内置 phash」「资料站」「浏览增强」 |
| **2. 识别未刮削 + 缺片** | Scene Matcher、Tag Manager、Missing Scenes | Carrot 源 |
| **3. 找源下载闭环** | Whisparr + Stasharr（可选 Portal）；wishlist 可对接缺片 | [compose 示例](../docker-compose.whisparr.yml.example) |
| **4. AI 分类与同类推荐** | AI Overhaul + Stash-AIServer + media_ai_model_server（需 NVIDIA） | [compose 示例](../docker-compose.ai-overhaul.yml.example) |
| **5. 人脸与更深推荐** | Stash Sense sidecar（库大优先）；或轻量 Star Identifier | [compose 示例](../docker-compose.stash-sense.yml.example) |
| **6. 查重清理** | DupFileManager + 内置 Dupe / phash 工作流 | 下方「查重」 |

与本仓脚本：`watch-media` / `auto-scan` 继续负责「有新文件就扫」；插件负责 UI 内发现与推荐。

---

## 1. 底座：phash、查重、资料站

### 内置 perceptual hash（phash）

- **做什么**：扫描时算视觉指纹；可按相似 phash 找同类/重复，不依赖插件。
- **怎么开**：Settings → Tasks / Library 相关选项中启用生成 **phash**（具体勾选名以当前 UI 为准）；对已有库跑一次 Generate。
- **为何优先**：零插件、最稳的「搜同类 / 查重」底座；上 AI 之前先开。

### Dupe Checker / 重复检测（内置 + 插件）

- **内置**：Scenes 过滤与 Tools 里基于 phash 的重复视图（以当前 Stash 版本菜单名为准）。
- **插件 DupFileManager**（Community stable，搜 `DupFileManager`）：交互式重复文件管理（合并/删除更直观）。
- **建议**：先用 phash 扫一遍，再用 DupFileManager 处理确认重复。

### StashDB / ThePornDB（TPDB）/ FansDB

- **做什么**：stash-box 端点；Identify / Tagger 匹配作品、演员、工作室；Missing Scenes 等依赖它们。
- **哪里配**：Settings → **Metadata Providers**（不是 Plugins 页）→ 添加 stash-box 端点与 API Key。
- **注意**：本仓不写密钥；只在部署机本地配置。配好后再装 Scene Matcher / Missing Scenes。

---

## 2. 浏览增强（Community stable）

| UI 搜索词 | 作用 |
|-----------|------|
| `hotCards` | 场景卡片高亮/状态样式，浏览时更快扫一眼 |
| `ThumbPreviews` | 悬停预览缩略/动态预览 |
| `timestampTrade` | 时间戳/标记相关增强，方便跳看 |
| `TPDBMarkers` | 从 TPDB 拉章节标记，便于分段浏览 |
| `File Monitor` | 监视片库目录变化（可与 `watch-media` 并存） |
| `Stash Notifications` | Community 刮削器/插件更新提醒 |
| `Scene Marker Tags to Scene` / `markerTagToScene` | Marker 标签同步到场景 |

---

## 3. 识别分类与缺片（Carrot Waxxer 源）

先 Add Source：`https://carrotwaxr.github.io/stash-plugins/stable/index.yml`。

### Scene Matcher

- **做什么**：在 Tagger 里按标题/演员/工作室/时长对 stash-box 打分匹配未刮削场景。
- **UI 搜索词**：`Scene Matcher`
- **前置**：至少一个 stash-box 端点已配置。

### Tag Manager

- **做什么**：标签整理、模糊合并等（Python 依赖见上游 README，如 `thefuzz`）。
- **UI 搜索词**：`Tag Manager`
- **为何推荐**：分类体系乱时先理标签，再跑 AI 打标更干净。

### Missing Scenes

- **做什么**：按已关联的演员/工作室/标签，列出 StashDB（或其它 stash-box）上你还缺的作品；可选一键送 Whisparr。
- **UI 搜索词**：`Missing Scenes`
- **前置**：stash-box；演员/工作室需已链接到 stash-box。
- **与 wishlist**：本仓 [wishlist.md](wishlist.md) 偏「人工待寻」；Missing Scenes 偏「库内已有演员的自动缺片」。

---

## 4. 找相关资源 / 下载闭环

### Whisparr + Stasharr

- **Whisparr**：类 *arr 的索引器/下载编排（BT/Usenet → 落盘到你的扫描路径）。
- **Stasharr**：浏览器用户脚本/扩展，或自托管 [Stasharr Portal](https://github.com/enymawse/stasharr-portal)；在 StashDB/FansDB 页一键送 Whisparr，并对照本机 Stash 是否已有。
- **本仓示例**：[`docker-compose.whisparr.yml.example`](../docker-compose.whisparr.yml.example)（可选服务，**不要**默认并进主 `docker-compose.yml`）。
- **衔接**：Whisparr 下载目录应对准 `MV_MEDIA_*` 或 `_inbox`；再用 `watch-media` / Missing Scenes 的 Scan 任务入库。
- **密钥**：API Key 只写部署机本地 `.env` / Whisparr UI，勿提交 Git。

### 番号 → 资料站链接

本仓脚本：`scripts/code-search-links`（打印搜索 URL，不代替下载器）。

---

## 5. AI 分类与同类推荐（替代已废弃的 AI Tagger）

### ~~AI Tagger~~（已废弃）

- **状态**：**DEPRECATED**。官方社区路线已转向 **AI Overhaul** 插件平台 + 后端。
- **请勿再装** Community 里残留的旧 `AI Tagger` / 旧 Python 打标包作为新部署首选。
- 若历史环境已装：停用后按下方 Overhaul 迁移；不要两套并行打同一库。

### AI Overhaul + Stash-AIServer + media_ai_model_server

| 组件 | 作用 | 安装位置 |
|------|------|----------|
| **AI Overhaul** | Stash 内插件 UI：任务、Similar、Recommended、异步 AI 插件宿主 | Community stable，搜 `AI Overhaul` / `AIOverhaul` |
| **Stash-AIServer** | 后端任务与插件引擎 | 旁路 Docker，见 compose 示例 |
| **media_ai_model_server** | 视觉模型推理（打标签等） | 旁路 Docker；需按上游 release 构建/拉模型 |

- **硬件**：NVIDIA GPU（大致 1080 及以上）+ 主机 **NVIDIA Container Toolkit**（Windows 上走 Docker Desktop GPU）。CPU 极慢，正式库不推荐。
- **本仓示例**：[`docker-compose.ai-overhaul.yml.example`](../docker-compose.ai-overhaul.yml.example) — 仅骨架与端口约定；**完整安装以** [Stash-AIServer](https://github.com/skier233/Stash-AIServer) / [media_ai_model_server](https://github.com/skier233/media_ai_model_server) **上游 README / Wiki 为准**。
- **建议**：等阶段 1–3 稳定、且确认有 GPU 后再装；先小样本再全库。

---

## 6. 人脸识别与更深推荐

### Stash Sense（优先，库大时）

- **做什么**：人脸识别演员、比 phash 更广的重复检测、推荐仪表盘、上游元数据变更提示。
- **形态**：sidecar 容器 + 插件源 `https://carrotwaxr.github.io/stash-sense/plugin/index.yml`。
- **前置**：场景已生成 **sprite sheets**；sidecar 可访问 Stash URL + API Key。
- **本仓示例**：[`docker-compose.stash-sense.yml.example`](../docker-compose.stash-sense.yml.example)。
- **磁盘**：人脸库约 1.5GB + 模型约 220MB（在插件 Settings 内下载，不进本 Git 仓）。

### Star Identifier（轻量备选）

- **做什么**：用**本库已有演员图**做人脸匹配标场景。
- **UI 搜索词**：`starIdentifier` / `Star Identifier`（Community stable）。
- **对比**：不依赖外部人脸大库；演员图少时效果有限。库大、要跨 stash-box 识别时优先 Sense。

---

## 可选：更重 / 慎用

### 第三方重命名（renamer）

- **常见名**：`renamerOnUpdate` / `RenameFile` / UI 搜 `renamer`；**以 Community 当前包名为准**。
- **风险**：改磁盘文件名。务必备份或先副本试跑；模板确认前关闭不可逆批量。
- **与本仓命名**：优先遵循 [naming.md](naming.md)。

### stashAI / stashtag

- 走外部推理/ Hugging Face 一类路径时，帧可能出网；正式库优先本地 AI Overhaul / Sense。

---

## 与本仓脚本 / compose 的分工

| 需求 | 更合适的方式 |
|------|----------------|
| 三目录有新片就扫 | `scripts/watch-media` + `auto-scan`（不带 Rescan） |
| 只盯投递区 | `scripts/watch-inbox` |
| 浏览增强 + 缺片 + 匹配 | 本页插件（Community + Carrot） |
| 索引下载闭环 | Whisparr compose 示例 + Stasharr / Missing Scenes |
| AI 打标 / Similar | AI Overhaul compose 示例（GPU） |
| 人脸 / 深推荐 | Stash Sense compose 示例 |
| 番号 → 资料站链接 | `scripts/code-search-links` |
| 演员待寻片单 | [wishlist.md](wishlist.md) |

部署机：`git pull` 后按本页阶段装插件；需要旁路服务时复制对应 `docker-compose.*.yml.example` 为本地 compose（可 gitignore 或放部署机私有目录），**不要把含密钥的实文件提交**。脚本用法见 [setup.md](setup.md)。
