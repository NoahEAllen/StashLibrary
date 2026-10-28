# asia-catalog（本地 provider 骨架）

面向**亚洲出品作品编号**的轻量元数据 provider，供 MediaVault 在官方运行时中加载。

## 定位

- 从文件名 / 查询串中提取常见作品编号（如 `ABC-123`、`ABCD-001`）。
- 用 **URL 模板**拼出若干资料站详情 / 搜索链接（模板在 Python 内以 Base64 存放）。
- 向编目服务返回场景片段占位（`title` / `code` / `urls`），便于你在 UI 里点选或继续手写解析。

这是常见中文社区编目扩展思路的**轻量替代**，**不是**其源码移植，也未捆绑任何下载站。

## 文件

| 文件 | 作用 |
|------|------|
| `asia-catalog.yml` | 注册 sceneByName / sceneByFragment 等，动作为 `script` |
| `asia_catalog.py` | 编号解析 + URL 拼装（stdin JSON → stdout JSON） |

## 安装

在仓库根目录：

```powershell
.\scripts\install-local-providers.ps1
```

```bash
./scripts/install-local-providers.sh
```

会复制到 `config/providers/asia-catalog/`。然后在 Web UI：**Reload** providers。

也可与 Community 精选包一起：先 `install-providers`，再 `install-local-providers`。

## 扩展

1. 在 `asia_catalog.py` 的模板列表中增加 / 替换 Base64 URL 模板（含 `{code}` / `{code_lower}` / `{code_compact}`）。
2. 若需真实抓取 HTML/JSON，在 `fetch_detail` 占位函数中自行实现（注意站点 ToS 与频率限制）。
3. 修改后重新运行 `install-local-providers` 并 Reload。

## 依赖

容器内需能执行 `python` / `python3`（官方镜像一般自带）。本骨架仅用标准库。
