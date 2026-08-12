
## Git 工作流

本项目采用 GitHub Flow + OpenSpec 集成：

- **分支命名**: `<type>/<change-name>`，其中 type ∈ {feature, fix, breaking, change}
- **版本号**: SemVer，3 文件同步 (`package.json`, `src-tauri/Cargo.toml`, `src-tauri/tauri.conf.json`)
- **Commit**: Conventional Commits 格式 (`feat:`, `fix:`, `chore:`, `release:`, `propose:`)
- **禁止直接在 main 上开发**: 所有改动必须通过 `/opsx:propose` 创建分支

### 命令

| 命令 | 用途 |
|------|------|
| `/opsx:propose` | 创建 change + artifacts + Git 分支 + 首次提交 |
| `/opsx:apply` | 在分支上逐任务实现 |
| `/opsx:release` | 归档 + SemVer 版本 bump + merge 到 main + tag + 删除分支 |
| `/opsx:abort` | 放弃 change，归档为 ABORTED，删除分支，切回 main |

### 首次使用前

确保已执行（一次性操作）:
```bash
cd 项目根目录
git init
git add -A
git commit -m "chore: 初始提交"
git branch -M main
git remote add origin <github-repo-url>
git push -u origin main
```

### 版本号文件

发布新版本时，以下文件须同步更新为同一个版本号：

| 文件 | 字段 |
|------|------|
| `package.json` | `"version"` |
| `src-tauri/Cargo.toml` | `[package] version` |
| `src-tauri/tauri.conf.json` | `"version"` |
