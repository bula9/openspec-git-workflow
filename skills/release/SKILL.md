---
name: release
description: Archive a completed change with automatic SemVer versioning, Git merge to main, tag, and push. Use when the user wants to finalize a change, release a new version, and sync to GitHub.
allowed-tools: Bash(openspec:*, git:*), Edit, Read, Glob, Grep, AskUserQuestion
license: MIT
compatibility: Requires openspec CLI and git repository.
metadata:
  author: project
  version: "1.0"
---

Archive a completed change with automatic SemVer versioning, Git merge to main, tag, and push.

**Input**: Optionally specify a change name (e.g., `/opsx:release add-auth`). If omitted, infer from conversation context or the current git branch. If vague or ambiguous, prompt for available changes.

**Steps**

1. **Run the standard archive workflow**

   Execute the full `openspec-archive-change` workflow for the selected change. This handles:
   - Selecting the change
   - Checking artifact and task completion
   - Delta spec sync assessment and execution
   - Moving the change to `openspec/changes/archive/`

   **IMPORTANT**: Do not proceed beyond this step unless the archive completes successfully.

2. **Analyze the archived change for version impact**

   Read the archived artifacts from the archive directory:
   - `<archive-dir>/proposal.md` — focus on "What Changes" and "Impact" sections
   - `<archive-dir>/design.md` — check for breaking technical decisions (if exists)
   - `<archive-dir>/specs/*/spec.md` — check delta spec headers (ADDED/MODIFIED/REMOVED/RENAMED)
   - `<archive-dir>/tasks.md` — scan task descriptions for feature/fix/refactor keywords

   Then apply the SemVer judgment rules below.

3. **Determine SemVer bump type**

   Read the current version from `package.json` first.

   ```
   MAJOR (X.0.0) — trigger if ANY of:
     □ proposal mentions "移除/删除/废弃/不兼容/breaking/rewrite/重构架构/重新设计"
     □ spec delta contains REMOVED or RENAMED requirement headers
     □ design.md mentions database schema incompatible migration
     □ design.md mentions API/command signature breaking changes
     □ design.md mentions config format changes (old configs won't load)

   MINOR (x.Y.0) — trigger if ANY of (and NO MAJOR triggers):
     □ proposal mentions "新增/添加/新功能/feature/new/add"
     □ spec delta contains ADDED requirement headers
     □ New pages, components, Tauri commands, or API endpoints added
     □ New database tables added (existing tables unchanged)
     □ tasks.md contains "新增/创建/实现" type tasks

   PATCH (x.y.Z) — DEFAULT when neither MAJOR nor MINOR triggers:
     □ proposal mentions "修复/fix/bug/优化/改进/调整/patch"
     □ spec delta MODIFIED headers with wording/clarification changes only
     □ Internal refactor, performance optimization, style fixes
     □ When uncertain → default to PATCH (most conservative)
   ```

   **Tiebreaker**: MAJOR > MINOR > PATCH. If multiple levels trigger, take the highest.

4. **Present analysis and get user confirmation**

   Display:
   - Current version (read from package.json)
   - Proposed new version with bump type label
   - Evidence: quote specific sentences from proposal/specs that led to this decision

   Use `AskUserQuestion` to let the user choose:
   - "确认 (Recommended)" — accept the suggested version
   - "改为 PATCH" — force PATCH bump
   - "改为 MINOR" — force MINOR bump
   - "改为 MAJOR" — force MAJOR bump
   - "手动输入版本号" — enter a custom version string
   - "跳过版本更新" — archive only, no version change

5. **Update version files**

   If confirmed (not skipped), update all three files to the same version string:

   - `package.json` → `"version"` field
   - `src-tauri/Cargo.toml` → `[package] version` field
   - `src-tauri/tauri.conf.json` → `"version"` field

   Use the Edit tool for precise in-place updates. Verify all three match after editing.

6. **Git merge, tag, and push**

   Determine the feature branch name from the change name. Use:
   ```bash
   git branch --list "*<change-name>" --format="%(refname:short)"
   ```
   to find the actual branch (it could be `feature/<name>`, `fix/<name>`, `breaking/<name>`, or `change/<name>`).

   If the branch is found:
   ```bash
   git checkout main
   git merge --no-ff "<feature-branch>" -m "release: v<new-version> — <change-name>"
   git tag -a "v<new-version>" -m "Release v<new-version>: <change-name>"
   git push origin main
   git push origin "v<new-version>"
   git branch -d "<feature-branch>"
   git push origin --delete "<feature-branch>"
   ```

   **Edge cases:**
   - If not in a git repo → skip all git operations, warn: "⚠️ 项目未初始化 Git 仓库，跳过 Git 操作。"
   - If the branch is not found → assume already on main, commit version files directly
   - If merge conflicts → stop and instruct user to resolve manually
   - If `git push` fails (no remote) → commit and tag locally, warn: "⚠️ 未配置远程仓库，提交和标签仅保存在本地。"
   - If already on main → commit version files on main, tag, push

7. **Display summary**

   ```
   ## Release Complete

   **Change:** <change-name>
   **Version:** <old-version> → <new-version> (<BUMP-TYPE>)
   **Reason:** <one-line reasoning with evidence>
   **Archive:** openspec/changes/archive/<date>-<name>/
   **Git:**
   - ✅ Merged <branch> → main
   - ✅ Tagged v<new-version>
   - ✅ Pushed to origin
   - ✅ Branch <branch> deleted
   ```

**Guardrails**
- Never skip user confirmation before changing version files
- All three version files must receive the identical version string
- If the archive step fails, stop entirely — do not bump version or merge
- Read current version from package.json fresh before editing (don't cache from earlier reads)
- Use `git merge --no-ff` to preserve branch history
- Always show the reasoning behind the SemVer decision with concrete evidence
- If the feature branch cannot be found, still commit version files on current branch
- Never force-push — if push is rejected, report the error and stop
