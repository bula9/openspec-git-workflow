# OpenSpec Git Workflow

基于 [OpenSpec](https://github.com/nicehash/openspec) 扩展的 Git + GitHub Flow 工作流工具包。

在一个命令中完成 **创建 change → 生成 artifacts → 创建分支 → 提交推送 → 版本发布 → 合并清理** 的完整闭环。

## 核心理念

```
一个 change = 一个 Git 分支 = 一次版本发布
```

| 命令 | 做什么 | 分支操作 | 版本号 |
|------|--------|---------|--------|
| `/opsx:propose` | 创建 change + artifacts + 分支 | checkout -b + push | — |
| `/opsx:apply` | 在分支上逐任务实现 | 多次 commit | — |
| `/opsx:release` | 归档 + SemVer 判定 + 合并 | merge → main → tag → 删分支 | bump |
| `/opsx:abort` | 放弃 change + 清理 | 切回 main → 删分支 | 不变 |

## 快速开始

### 前提条件

- 已安装 [openspec CLI](https://github.com/nicehash/openspec)
- 已安装 [Claude Code](https://claude.ai/code)
- 项目已初始化 Git 仓库

### 安装到已有项目

**macOS / Linux:**

```bash
curl -sSL https://raw.githubusercontent.com/bula9/openspec-git-workflow/main/install.sh | bash -s <项目路径>
```

**Windows (PowerShell):**

```powershell
iwr -useb https://raw.githubusercontent.com/bula9/openspec-git-workflow/main/install.ps1 | iex
```

**手动安装:**

```bash
git clone https://github.com/bula9/openspec-git-workflow.git
cp -r openspec-git-workflow/commands/opsx/* <项目>/.claude/commands/opsx/
cp -r openspec-git-workflow/skills/*         <项目>/.claude/skills/
cat openspec-git-workflow/templates/CLAUDE-git-workflow.md >> <项目>/CLAUDE.md
# 然后手动合并 openspec-git-workflow/templates/config.yaml 到 <项目>/openspec/config.yaml
```

### 安装后

1. 确保项目已初始化 Git：
   ```bash
   git init && git add -A && git commit -m "chore: 初始提交"
   git remote add origin <你的仓库> && git push -u origin main
   ```

2. 开始使用：
   ```
   /opsx:propose 新增用户登录功能
   /opsx:apply
   /opsx:release add-user-login
   ```

## 工作流详解

### 正常流程

```
/opsx:propose 新增词卡标签筛选
  → 创建 openspec/changes/add-flashcard-tag-filter/
  → 推断分支类型: feature
  → git checkout -b feature/add-flashcard-tag-filter
  → git push -u origin feature/add-flashcard-tag-filter
  → 生成 proposal/design/specs/tasks
  → git commit -m "propose: add-flashcard-tag-filter — ..."
  → git push

/opsx:apply
  → 在 feature/add-flashcard-tag-filter 上逐任务实现
  → 多次 git commit

/opsx:release add-flashcard-tag-filter
  → 执行标准 archive
  → AI 读取归档内容，判定: MINOR (有新功能)
  → 用户确认: 1.0.0 → 1.1.0
  → 更新 package.json / Cargo.toml / tauri.conf.json
  → git checkout main
  → git merge --no-ff feature/add-flashcard-tag-filter
  → git tag v1.1.0
  → git push origin main --tags
  → git branch -d feature/add-flashcard-tag-filter
  → git push origin --delete feature/add-flashcard-tag-filter
```

### 放弃流程

```
/opsx:abort add-oauth-login
  → 询问放弃原因
  → 归档到 openspec/changes/archive/YYYY-MM-DD-ABORTED-add-oauth-login/
  → 在 proposal.md 末尾追加放弃原因
  → git checkout main
  → git branch -D feature/add-oauth-login
  → git push origin --delete feature/add-oauth-login
```

## SemVer 版本判定

`/opsx:release` 会自动从归档内容推断版本变更类型：

| 触发条件 | 变更 |
|---------|------|
| proposal 含"移除/删除/不兼容/breaking"，spec delta 有 REMOVED | **MAJOR** (X.0.0) |
| proposal 含"新增/新功能"，spec delta 有 ADDED | **MINOR** (x.Y.0) |
| proposal 含"修复/优化/调整"，或无法判断 | **PATCH** (x.y.Z) |

每次发布前会展示推理过程并让用户确认，允许手动覆盖。

## 分支命名

| 用户描述关键词 | 分支前缀 |
|--------------|---------|
| 新增/添加/新功能/feature/new | `feature/` |
| 修复/fix/bug/修正 | `fix/` |
| 重构/移除/不兼容/breaking | `breaking/` |
| 以上都不匹配 | `change/` |

## 文件结构

```
openspec-git-workflow/
├── README.md
├── install.sh                    # macOS/Linux 安装脚本
├── install.ps1                   # Windows PowerShell 安装脚本
├── commands/opsx/
│   ├── propose.md                # 修改版: 含 Git 分支创建
│   ├── release.md                # 新增: 归档 + 版本 + 合并
│   └── abort.md                  # 新增: 放弃 + 清理
├── skills/
│   ├── openspec-propose/SKILL.md # 修改版
│   ├── release/SKILL.md          # 新增
│   └── abort/SKILL.md            # 新增
└── templates/
    ├── config.yaml               # openspec 配置追加内容
    ├── CLAUDE-git-workflow.md    # CLAUDE.md 追加内容
    └── gitignore                 # .gitignore 模板
```

## 版本号文件

`/opsx:release` 会自动同步以下 3 个文件（如存在）：

| 文件 | 字段 |
|------|------|
| `package.json` | `"version"` |
| `src-tauri/Cargo.toml` | `[package] version` |
| `src-tauri/tauri.conf.json` | `"version"` |

## License

MIT
