#!/bin/bash
# OpenSpec Git Workflow — 安装脚本 (macOS / Linux)
# 用法: ./install.sh [目标项目路径]
# 默认安装到当前目录

set -e

TARGET="${1:-.}"

# 转为绝对路径
TARGET="$(cd "$TARGET" && pwd)"

echo "========================================"
echo "  OpenSpec Git Workflow 安装"
echo "========================================"
echo ""
echo "目标项目: $TARGET"
echo ""

# 检查目标项目是否存在
if [ ! -d "$TARGET" ]; then
    echo "❌ 目标目录不存在: $TARGET"
    exit 1
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---- 1. 创建目录结构 ----
echo "📁 创建 .claude 目录结构..."
mkdir -p "$TARGET/.claude/commands/opsx"
mkdir -p "$TARGET/.claude/skills"

# ---- 2. 复制命令文件 ----
echo "📋 复制命令文件..."
cp "$SCRIPT_DIR/commands/opsx/propose.md" "$TARGET/.claude/commands/opsx/"
cp "$SCRIPT_DIR/commands/opsx/release.md" "$TARGET/.claude/commands/opsx/"
cp "$SCRIPT_DIR/commands/opsx/abort.md"   "$TARGET/.claude/commands/opsx/"
echo "  ✅ propose.md (含 Git 分支创建)"
echo "  ✅ release.md (归档 + 版本 + 合并)"
echo "  ✅ abort.md   (放弃 + 清理)"

# ---- 3. 复制 skill 文件 ----
echo "📋 复制 skill 文件..."
cp -r "$SCRIPT_DIR/skills/openspec-propose" "$TARGET/.claude/skills/"
cp -r "$SCRIPT_DIR/skills/release"           "$TARGET/.claude/skills/"
cp -r "$SCRIPT_DIR/skills/abort"             "$TARGET/.claude/skills/"
echo "  ✅ openspec-propose (已更新)"
echo "  ✅ release"
echo "  ✅ abort"

# ---- 4. 更新 openspec/config.yaml ----
echo "📋 更新 openspec 配置..."
if [ -f "$TARGET/openspec/config.yaml" ]; then
    # 检查是否已经包含 Git 工作流配置
    if grep -q "Git 工作流" "$TARGET/openspec/config.yaml" 2>/dev/null; then
        echo "  ⚠️  openspec/config.yaml 已包含 Git 工作流配置，跳过"
    else
        # 追加 context 内容
        cat "$SCRIPT_DIR/templates/config.yaml" | grep -A999 "context:" | tail -n +2 >> "$TARGET/openspec/config.yaml"
        echo "  ✅ 已追加版本管理和 Git 工作流上下文"
    fi
else
    # 创建完整的 config.yaml
    cp "$SCRIPT_DIR/templates/config.yaml" "$TARGET/openspec/config.yaml"
    echo "  ✅ 已创建 openspec/config.yaml"
fi

# ---- 5. 更新 CLAUDE.md ----
echo "📋 更新 CLAUDE.md..."
if [ -f "$TARGET/CLAUDE.md" ]; then
    if grep -q "Git 工作流" "$TARGET/CLAUDE.md" 2>/dev/null; then
        echo "  ⚠️  CLAUDE.md 已包含 Git 工作流章节，跳过"
    else
        cat "$SCRIPT_DIR/templates/CLAUDE-git-workflow.md" >> "$TARGET/CLAUDE.md"
        echo "  ✅ 已追加 Git 工作流章节"
    fi
else
    cp "$SCRIPT_DIR/templates/CLAUDE-git-workflow.md" "$TARGET/CLAUDE.md"
    echo "  ✅ 已创建 CLAUDE.md"
fi

# ---- 6. 检查 .gitignore ----
echo "📋 检查 .gitignore..."
if [ ! -f "$TARGET/.gitignore" ]; then
    cp "$SCRIPT_DIR/templates/gitignore" "$TARGET/.gitignore"
    echo "  ✅ 已创建 .gitignore"
else
    echo "  ⚠️  .gitignore 已存在，跳过（可手动参考 templates/gitignore）"
fi

# ---- 7. 检查 Git 仓库状态 ----
echo ""
echo "----------------------------------------"
echo "  Git 仓库检查"
echo "----------------------------------------"
cd "$TARGET"
if [ -d ".git" ]; then
    echo "✅ Git 仓库已初始化"
    if git remote -v 2>/dev/null | grep -q origin; then
        echo "✅ Git 远程仓库已配置"
    else
        echo "⚠️  未配置 Git 远程仓库。请执行:"
        echo "   git remote add origin <你的仓库 URL>"
        echo "   git push -u origin main"
    fi
else
    echo "⚠️  项目未初始化 Git 仓库。请执行:"
    echo "   git init"
    echo "   git add -A"
    echo "   git commit -m \"chore: 初始提交\""
    echo "   git branch -M main"
    echo "   git remote add origin <你的仓库 URL>"
    echo "   git push -u origin main"
fi

echo ""
echo "========================================"
echo "  ✅ 安装完成!"
echo "========================================"
echo ""
echo "可用命令:"
echo "  /opsx:propose <描述>   → 创建 change + 分支"
echo "  /opsx:apply             → 在分支上实现"
echo "  /opsx:release <名称>    → 归档 + 版本 + 合并"
echo "  /opsx:abort <名称>      → 放弃 + 清理"
echo ""
echo "详细文档: https://github.com/bula9/openspec-git-workflow"
