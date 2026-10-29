# 推荐 Plugins 勾选表

目标：**浏览更爽、搜同类、识别分类、找相关与下载**（不做 SFW 遮罩）。  
说明与依赖见 [docs/plugins.md](../docs/plugins.md)。

## 插件源

| 源 | URL |
|----|-----|
| Community (stable) | `https://stashapp.github.io/CommunityScripts/stable/index.yml` |
| Carrot Waxxer | `https://carrotwaxr.github.io/stash-plugins/stable/index.yml` |
| Stash Sense | `https://carrotwaxr.github.io/stash-sense/plugin/index.yml` |

（Metadata Providers / stash-box 端点在 **Settings → Metadata Providers**，不在本表。）

## 勾选表（按落地阶段）

| 阶段 | 优先级 | UI 搜索词（约） | 源 | 作用 | 必装？ |
|------|--------|-----------------|-----|------|--------|
| 1 底座 | — | （内置）phash Generate | 核心 | 视觉指纹，同类/查重底座 | **建议先开** |
| 1 底座 | — | StashDB / TPDB / FansDB 端点 | Metadata Providers | Identify / Tagger / 缺片依赖 | **建议** |
| 1 浏览 | 1 | `hotCards` | Community | 卡片高亮浏览 | 建议 |
| 1 浏览 | 1 | `ThumbPreviews` | Community | 悬停预览 | 建议 |
| 1 浏览 | 1 | `timestampTrade` | Community | 时间戳/跳看增强 | 建议 |
| 1 浏览 | 1 | `TPDBMarkers` | Community | TPDB 章节标记 | 可选 |
| 1 运维 | 1 | `File Monitor` | Community | 监视目录变化 | 建议 |
| 1 运维 | 1 | `Stash Notifications` | Community | 插件/刮削器更新提醒 | 建议 |
| 1 运维 | 1 | `Scene Marker Tags to Scene` / `markerTagToScene` | Community | Marker 标签→场景 | 建议 |
| 2 识别 | 2 | `Scene Matcher` | Carrot | 未刮削场景对 stash-box 打分匹配 | 建议 |
| 2 识别 | 2 | `Tag Manager` | Carrot | 标签整理/合并 | 可选 |
| 2 缺片 | 2 | `Missing Scenes` | Carrot | 演员/工作室在 stash-box 上的缺片；可接 Whisparr | 建议 |
| 3 下载 | 2 | Whisparr + Stasharr（旁路，非 Plugins 列表） | compose / 用户脚本 | 搜种下载→入库 | 有索引器再上 |
| 4 AI | 3 | `AI Overhaul` / `AIOverhaul` | Community | AI 平台：打标、Similar、Recommended | 有 GPU 后装 |
| 4 AI | 3 | Stash-AIServer + media_ai_model_server | 旁路 Docker | Overhaul 后端与模型 | 随 Overhaul |
| 4 AI | — | ~~`AI Tagger`~~ | — | **已废弃**，勿新装 | 禁止新装 |
| 5 人脸 | 3 | `Stash Sense` | Stash Sense 源 | 人脸、深查重、推荐仪表盘 | 库大可选 |
| 5 人脸 | 3 | `starIdentifier` / `Star Identifier` | Community | 本库演员脸匹配（轻量） | Sense 未上时可选 |
| 6 查重 | 2 | `DupFileManager` | Community | 交互式重复清理 | 建议 |
| 其它 | 2 | `VideoScrollWheel` | Community | 滚轮调进度/音量 | 可选 |
| 其它 | 2 | `Video Chapter Markers` / `videoChapterMarkers` | Community | 片内章节→Markers | 可选 |
| 其它 | 2 | `Stats` | Community | 仪表盘统计 | 可选 |
| 其它 | 2 | `Scene Cover Cropper` / `sceneCoverCropper` | Community | 裁封面 | 可选 |
| 慎用 | 4 | `renamer` / `renamerOnUpdate` / `RenameFile` | Community | 按元数据改文件名 | 可选，**慎用** |

## 旁路 compose（本仓示例，不默认启动）

| 文件 | 用途 |
|------|------|
| [`docker-compose.whisparr.yml.example`](../docker-compose.whisparr.yml.example) | Whisparr（下载闭环） |
| [`docker-compose.ai-overhaul.yml.example`](../docker-compose.ai-overhaul.yml.example) | Stash-AIServer 骨架 + GPU 备注 |
| [`docker-compose.stash-sense.yml.example`](../docker-compose.stash-sense.yml.example) | Stash Sense sidecar |

复制为本地文件并填端口/路径/密钥后再 `docker compose -f ... up -d`；实文件勿提交密钥。
