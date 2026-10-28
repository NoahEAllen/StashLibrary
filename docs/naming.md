# 命名规范

目标：目录与文件名**中性、可分享到私有 Git**，同时方便编目与刮削匹配。

## 分区

| 分区 | 相对路径 | 说明 |
|------|----------|------|
| A 向 | `library/primary/asia` | 亚洲成片、有稳定出品编号的内容优先 |
| A 向 | `library/primary/western` | 欧美主流厂牌 |
| A 向 | `library/primary/indie` | 独立 / 业余 / 未归厂 |
| B 向 | `library/alternate/studios` | 明确厂牌成片 |
| B 向 | `library/alternate/western` | 欧美 alternate 线 |
| B 向 | `library/alternate/indie` | 独立 / 业余 |
| 投递 | `library/_inbox` | 尚未决定分区时暂存 |

## 文件名建议

1. **有出品编号**：`厂牌或系列代码-编号` + 可选标题短句，例如 `ABCD-123 Title Words.mp4`。
2. **厂牌场景盘**：`StudioName - Scene Title (YYYY-MM-DD).mp4`。
3. 避免空格过多时可用 `_` 或 `.`；保持 ASCII 为主，便于跨系统。
4. 不要在文件名里写下载站域名、分辨率堆砌无意义前缀（可放在后面：`... 1080p.mp4`）。

## 标签（Tags）建议

在 UI 里用中性标签区分分区策略，例如：

- `zone:primary` / `zone:alternate`
- `region:asia` / `region:western`
- `type:studio` / `type:indie`

## 禁止事项（仓库文本）

提交前跑 `scripts/sanity-check.ps1`。不要在**文件名、文件夹名、README 标题、compose 服务名**中使用敏感题材词；上游技术名只允许以 Base64 出现在脚本中。
