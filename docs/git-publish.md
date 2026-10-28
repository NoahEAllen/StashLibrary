# 推送到私有 GitHub

## 建议

1. 仓库可见性设为 **Private**。
2. 确认 `.env`、媒体文件、`config/providers/**` 已被 `.gitignore` 排除。
3. 推送前运行：

```powershell
.\scripts\sanity-check.ps1
```

## 首次推送示例

```powershell
cd <MediaVault 根目录>
git init   # 若尚未初始化
git add .
git status   # 确认没有 .env / 媒体 / providers 实体文件
git commit -m "init MediaVault catalog scaffold"
git branch -M main
git remote add origin https://github.com/<你>/<私有仓库>.git
git push -u origin main
```

## 目标电脑拉取

```powershell
git clone https://github.com/<你>/<私有仓库>.git MediaVault
cd MediaVault
.\scripts\bootstrap.ps1
.\scripts\start.ps1
```

## 注意

- 不要把填好的 `.env` 提交上去（内含解码后的镜像名与路径键）。
- `install-providers.ps1` 拉取的社区包落在 `config/providers/`，默认忽略；目标机再装一次即可。
