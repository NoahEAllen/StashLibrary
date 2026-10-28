# 元数据索引器（providers）

优先用 UI 安装：

**Settings → Metadata Providers → Available → Community (stable)**

下面只写「搜什么 / 干什么」。具体包名在 `scripts/install-providers.ps1` 里编码存放，避免仓库目录一眼可读。

---

## primary（A 向）

### 亚洲成片资料

Community 搜索：`Library`、`Bus`、`DB`、`Database`、`r18`、`asia`  
用途：按出品编号补全标题、演职、封面。

### 通用目录 / 元数据库

| 搜索关键词 | 用途 |
|------------|------|
| IAFD | 国际影片资料交叉核对 |
| Empire | 目录页（注意区分 A/B 向不同包） |
| TPDB / 社区 API | 需自行配置 token 的元数据 API |
| box | Metadata Providers 里配置远程 box，批量匹配 |

### 欧美厂牌

按你实际收藏的厂牌名在 Community 搜索安装；也可用脚本一次装入精选包。

---

## alternate（B 向）

### 索引

| 搜索关键词 | 用途 |
|------------|------|
| GEVI | 大型 B 向影片索引（演职 / 单集 / 整片） |
| Empire、Wire | B 向目录站相关包 |

### 厂牌

按收藏厂牌名搜索安装。精选列表见 `install-providers.ps1`（编码），用到哪个装哪个。

---

## 双线备注

主分区为 **primary + alternate**。若有双线厂牌，在 Community 搜对应厂牌名，用标签区分即可，不必第三套 Library。

---

## 使用提示

1. **优先 URL**：厂牌官网或资料站页面填进条目后再拉取。
2. **亚洲成片靠出品编号**：文件名带标准编号，再用 asia 资料源。
3. **不要用下载站当元数据源**：人机验证与跳转页易失败。
4. 装完在 UI **重新加载** providers；脚本类包报错时看容器日志与该包说明。
