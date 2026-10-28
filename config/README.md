# config — MediaVault 配置目录

挂载为容器内应用配置根目录。首次 `docker compose up` 后会自动生成配置文件与数据库，一般无需手写。

## 元数据索引器（providers）

- 路径：`config/providers/`
- **推荐**：Web UI → **Settings → Metadata Providers → Community (stable)** 搜索安装
- **备用**：仓库根目录运行 `scripts/install-providers.ps1`，再在 UI 中 Reload

安装后刷新 providers 列表即可（多数情况不必重启容器）。
