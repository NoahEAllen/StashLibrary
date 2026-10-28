# 推送到私有 Git 仓库

本机（工作电脑）只做源码整理，不要 `docker compose up`。目标电脑再部署。

## 1. 本地已完成首提交时

```powershell
cd D:\desktopfiles\MediaVault
git status
```

## 2. 在 GitHub 建**私有**空仓库

浏览器新建 Private 仓库，不要勾选自动加 README（本地已有）。

## 3. 关联并推送

把下面 URL 换成你的：

```powershell
cd D:\desktopfiles\MediaVault
git remote add origin https://github.com/<you>/<repo>.git
git branch -M main
git push -u origin main
```

SSH 亦可：

```powershell
git remote add origin git@github.com:<you>/<repo>.git
git push -u origin main
```

## 4. 目标电脑

```powershell
git clone <私有仓库 URL>
cd <目录>
.\scripts\bootstrap.ps1
.\scripts\start.ps1
```

然后按 `setup.md` 加 `/data/primary` 与 `/data/alternate`，并设置 Scrapers Path 为 `/root/.stash/providers`（与本仓库 `config/providers` 对应）。

## 注意

- 仓库务必 **Private**。
- 不要提交 `.env`、媒体文件、`metadata/` 等（已在 `.gitignore`）。
- 目录与文档使用中性名；首次 `start.ps1` 才会在本地写出运行所需环境变量。
