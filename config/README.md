# config/

运行时配置目录，挂载到容器内配置家目录（路径由 `scripts/start.ps1` 写入 `.env` 的 `MV_CONFIG_HOME`，不在仓库明文出现）。

- `providers/`：元数据索引器文件落盘处（由 UI Community 安装或 `scripts/install-providers.ps1` 填充）。
- 其它 `*.yml` / sqlite 由服务首次启动生成，默认被 `.gitignore` 忽略。
