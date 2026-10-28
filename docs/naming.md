# 命名规范

目标：文件名便于元数据索引器识别，减少手工改名。

## primary — 亚洲成片（`library/primary/asia/`）

优先用 **出品编号**，常见写法保留连字符：

```
ABCD-001.mp4
WXYZ-123.mp4
```

可选：编号后附加标题：

```
ABCD-001_Title.mp4
```

避免：无意义前缀、多部挤在一个文件名、随意删掉连字符（部分索引器能容错，但不稳）。

## primary — 欧美 / 独立（`western/` `indie/`）

```
Studio - YYYY-MM-DD - Scene Title.mp4
Studio - Scene Title.mp4
```

有官方场景页时，在编目 UI 填 URL 再拉取元数据，通常比纯文件名更准。

## alternate — 厂牌成片（`library/alternate/studios/` 等）

```
Studio - YYYY-MM-DD - Title.mp4
Studio - Title.mp4
```

整部作品：

```
Studio - Movie Title (YYYY).mp4
```

索引器多依赖 **URL** 或「厂牌 + 日期 + 标题」；文件名带齐这三项可提高命中率。

## 投递区 `_inbox/`

下载完成后先放这里，**整理进 primary/ 或 alternate/ 后再扫描**，避免半成品进库。

## 通用

- 一场景一文件；合集请拆开或标明分集。
- 避开 `? * < > |` 等特殊字符。
- 扩展名小写：`.mp4` `.mkv`。
