# 演员 Wish List（待寻片单）

Stash **不会**把资料站上「该演员全部作品」自动列进库。库里只有已扫描的本地文件。  
若要用**标准片名**去下载站搜索，把还没入库的条目记在 wish list 里。

## 文件

| 文件 | 说明 |
|------|------|
| [`presets/performer-wishlist.csv.example`](../presets/performer-wishlist.csv.example) | 模板；复制为仓库根或 `cache/performer-wishlist.csv`（后者已在 gitignore 习惯下更适合放私有清单） |
| `scripts/wishlist-list` | 列出 `status=pending` 的行，便于复制片名 |

推荐私有清单路径（勿提交真实清单）：

```text
cache/performer-wishlist.csv
```

从 example 复制：

```powershell
Copy-Item presets\performer-wishlist.csv.example cache\performer-wishlist.csv
```

```bash
cp presets/performer-wishlist.csv.example cache/performer-wishlist.csv
```

## 列含义

| 列 | 含义 |
|----|------|
| `performer` | 演员名（与库内一致更好） |
| `title_or_code` | 标准片名或作品编号（搜索关键字段） |
| `notes` | 备注（清晰度、是否系列等） |
| `status` | `pending` / `have` / `skip` |
| `source_url` | 资料站条目链接（可选） |

## 推荐流程

1. 在 Stash 打开演员页 → 刮削补全 → 点开外站作品列表。
2. 对照库内已有场景，把**没有的片子**的标准名/番号写入 CSV，`status=pending`。
3. 用 `title_or_code` 在下载站搜索；下完放进 TEMP/云盘/下载（或 `_inbox`）。
4. 跑增量扫描：`auto-scan` 或 `watch-media`（不要开 Rescan）。
5. 入库并刮削成功后，把该行改成 `status=have`。

查 pending：

```powershell
.\scripts\wishlist-list.ps1
.\scripts\wishlist-list.ps1 -Csv cache\performer-wishlist.csv
```

```bash
./scripts/wishlist-list.sh
./scripts/wishlist-list.sh --Csv cache/performer-wishlist.csv
```
