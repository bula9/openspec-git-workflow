---
name: "OPSX: Abort"
description: "Abandon a change — archive as ABORTED, delete branch, switch back to main"
allowed-tools: Bash(openspec:*, git:*), Edit, Read, Glob, Grep, AskUserQuestion
category: "Workflow"
tags: ["workflow", "abort", "cleanup", "git"]
---

Abandon an in-progress change. Archives the OpenSpec change directory as ABORTED (preserving the thinking), deletes the Git branch (local + remote), and switches back to main.

**Input**: Optionally specify a change name after `/opsx:abort` (e.g., `/opsx:abort add-oauth-login`). If omitted:
- Infer from the current git branch (strip the `feature/`/`fix/`/`breaking/`/`change/` prefix)
- If on main/master and no name given → list active changes and prompt for selection
- If ambiguous, prompt for available active changes

**Steps**

1. **Identify the change to abort**

   If a name is provided, use it. Otherwise:
   - Run `git branch --show-current` to get the current branch
   - If the branch matches `<prefix>/<name>`, extract `<name>` as the change name
   - If on `main` or `master`, list active changes via `openspec list --json` and prompt
   - Announce: "放弃 change: `<name>`（分支: `<branch>`）"

2. **Ask for abort reason (optional but recommended)**

   Present preset options via `AskUserQuestion`:
   - "方向错误，需求理解有偏差"
   - "技术方案不可行"
   - "被其他 change 替代了"
   - "暂时搁置，以后可能继续"
   - "其他（手动输入）"
   - "不记录原因"

   Having a reason helps future you understand why this path was abandoned.

3. **Final confirmation**

   Display a warning and use `AskUserQuestion` for final confirmation:

   ```
   ⚠️ 此操作不可逆！

   将执行:
   - 归档 change 目录 → openspec/changes/archive/YYYY-MM-DD-ABORTED-<name>/
   - 删除本地分支: <branch>
   - 删除远程分支: origin/<branch>
   - 切换到 main 分支
   - 分支上未合并的更改将丢失

   选项: [确认放弃] [取消]
   ```

   If the user cancels, stop immediately.

4. **Archive the change as ABORTED**

   Find the change directory. Run `openspec list --json` to get `changeRoot` and `planningHome`.

   a. Append the abort reason to `proposal.md`:
      ```
      ## Abort Reason (2026-08-XX)
      <reason selected by user>
      ```

   b. Move the change to archive with ABORTED prefix:
      ```bash
      mkdir -p "<planningHome.changesDir>/archive"
      mv "<changeRoot>" "<planningHome.changesDir>/archive/YYYY-MM-DD-ABORTED-<name>"
      ```

   If the change directory doesn't exist (manually deleted), skip the archive step and only do git cleanup.

5. **Git cleanup**

   a. Stash or discard any uncommitted changes on the branch:
      - If there are uncommitted changes → ask: "分支上有未提交的更改。处理方式: [git stash 暂存] [直接丢弃] [取消放弃]"
      - If "git stash" → `git stash`
      - If "直接丢弃" → `git checkout -- . && git clean -fd`

   b. Switch to main:
      ```bash
      git checkout main
      ```

   c. Delete local branch:
      ```bash
      git branch -D "<branch-name>"
      ```

   d. Delete remote branch:
      ```bash
      git push origin --delete "<branch-name>"
      ```
      If push fails (no remote, auth error), warn but continue — local cleanup is already done.

   **Edge cases:**
   - If not in a git repo → skip all git operations, only archive the change
   - If the branch doesn't exist locally → skip local delete, still try remote delete
   - If the branch doesn't exist remotely → skip remote delete, warn
   - If on main and no branch to delete → only archive the change

6. **Display summary**

   ```
   ## Change Aborted

   **Change:** <change-name>
   **Archive:** openspec/changes/archive/YYYY-MM-DD-ABORTED-<name>/
   **Reason:** <reason>
   **Git:**
   - ✅ Switched to main
   - ✅ Deleted local branch: <branch>
   - ✅ Deleted remote branch: origin/<branch>
   **Status:** 项目已回到 main 分支，可以开始新的 change。
   ```

**Output On Success**

```
## Change Aborted

**Change:** add-oauth-login
**Archive:** openspec/changes/archive/2026-08-12-ABORTED-add-oauth-login/
**Reason:** 技术方案不可行 — OAuth 服务商不支持桌面应用授权模式
**Git:**
- ✅ Switched to main
- ✅ Deleted local branch: feature/add-oauth-login
- ✅ Deleted remote branch: origin/feature/add-oauth-login
**Status:** 项目已回到 main 分支，可以开始新的 change。使用 /opsx:propose 创建新 change。
```

**Output On Error (Uncommitted Changes)**

If there are uncommitted changes and the user hasn't decided how to handle them, pause and ask before proceeding.

**Guardrails**
- Never delete a branch without explicit user confirmation
- Always append the abort reason to proposal.md — don't overwrite existing content
- Use `ABORTED-` prefix (all caps) to distinguish from normal archives
- Never force-push to main
- If the change has been partially or fully merged to main already, warn: "⚠️ 此 change 可能已有提交合并到 main。删除分支不会撤销已合并的提交。"
- Handle the case where the change directory was already manually deleted (graceful skip)
- If on a branch that doesn't match the change name pattern, confirm: "当前分支 `<branch>` 似乎与 change `<name>` 不匹配。确定要删除这个分支吗？"
