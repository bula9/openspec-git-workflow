# OpenSpec Git Workflow — 安装脚本 (Windows PowerShell)
# 用法: .\install.ps1 [-TargetPath <项目路径>]
# 默认安装到当前目录

param(
    [string]$TargetPath = "."
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OpenSpec Git Workflow 安装" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 转到绝对路径
$TargetPath = (Resolve-Path $TargetPath).Path
Write-Host "目标项目: $TargetPath"
Write-Host ""

# 检查目标项目是否存在
if (-not (Test-Path $TargetPath)) {
    Write-Host "❌ 目标目录不存在: $TargetPath" -ForegroundColor Red
    exit 1
}

# 获取脚本所在目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- 1. 创建目录结构 ----
Write-Host "📁 创建 .claude 目录结构..." -ForegroundColor Yellow
$null = New-Item -ItemType Directory -Force -Path "$TargetPath\.claude\commands\opsx"
$null = New-Item -ItemType Directory -Force -Path "$TargetPath\.claude\skills"

# ---- 2. 复制命令文件 ----
Write-Host "📋 复制命令文件..." -ForegroundColor Yellow
Copy-Item "$ScriptDir\commands\opsx\propose.md" "$TargetPath\.claude\commands\opsx\" -Force
Copy-Item "$ScriptDir\commands\opsx\release.md" "$TargetPath\.claude\commands\opsx\" -Force
Copy-Item "$ScriptDir\commands\opsx\abort.md"   "$TargetPath\.claude\commands\opsx\" -Force
Write-Host "  ✅ propose.md (含 Git 分支创建)" -ForegroundColor Green
Write-Host "  ✅ release.md (归档 + 版本 + 合并)" -ForegroundColor Green
Write-Host "  ✅ abort.md   (放弃 + 清理)" -ForegroundColor Green

# ---- 3. 复制 skill 文件 ----
Write-Host "📋 复制 skill 文件..." -ForegroundColor Yellow
Copy-Item "$ScriptDir\skills\openspec-propose" "$TargetPath\.claude\skills\" -Recurse -Force
Copy-Item "$ScriptDir\skills\release"           "$TargetPath\.claude\skills\" -Recurse -Force
Copy-Item "$ScriptDir\skills\abort"             "$TargetPath\.claude\skills\" -Recurse -Force
Write-Host "  ✅ openspec-propose (已更新)" -ForegroundColor Green
Write-Host "  ✅ release" -ForegroundColor Green
Write-Host "  ✅ abort" -ForegroundColor Green

# ---- 4. 更新 openspec/config.yaml ----
Write-Host "📋 更新 openspec 配置..." -ForegroundColor Yellow
$configPath = "$TargetPath\openspec\config.yaml"
if (Test-Path $configPath) {
    $configContent = Get-Content $configPath -Raw
    if ($configContent -match "Git 工作流") {
        Write-Host "  ⚠️  openspec/config.yaml 已包含 Git 工作流配置，跳过" -ForegroundColor Yellow
    } else {
        $templateConfig = Get-Content "$ScriptDir\templates\config.yaml" -Raw
        # 提取 context 部分（从 context: 开始）
        $contextPart = ($templateConfig -split "context: \|", 2)[1]
        if ($contextPart) {
            Add-Content $configPath "`n$contextPart"
            Write-Host "  ✅ 已追加版本管理和 Git 工作流上下文" -ForegroundColor Green
        }
    }
} else {
    $null = New-Item -ItemType Directory -Force -Path "$TargetPath\openspec"
    Copy-Item "$ScriptDir\templates\config.yaml" $configPath -Force
    Write-Host "  ✅ 已创建 openspec/config.yaml" -ForegroundColor Green
}

# ---- 5. 更新 CLAUDE.md ----
Write-Host "📋 更新 CLAUDE.md..." -ForegroundColor Yellow
$claudePath = "$TargetPath\CLAUDE.md"
if (Test-Path $claudePath) {
    $claudeContent = Get-Content $claudePath -Raw
    if ($claudeContent -match "Git 工作流") {
        Write-Host "  ⚠️  CLAUDE.md 已包含 Git 工作流章节，跳过" -ForegroundColor Yellow
    } else {
        $claudeAppendix = Get-Content "$ScriptDir\templates\CLAUDE-git-workflow.md" -Raw
        Add-Content $claudePath "`n$claudeAppendix"
        Write-Host "  ✅ 已追加 Git 工作流章节" -ForegroundColor Green
    }
} else {
    Copy-Item "$ScriptDir\templates\CLAUDE-git-workflow.md" $claudePath -Force
    Write-Host "  ✅ 已创建 CLAUDE.md" -ForegroundColor Green
}

# ---- 6. 检查 .gitignore ----
Write-Host "📋 检查 .gitignore..." -ForegroundColor Yellow
$gitignorePath = "$TargetPath\.gitignore"
if (-not (Test-Path $gitignorePath)) {
    Copy-Item "$ScriptDir\templates\gitignore" $gitignorePath -Force
    Write-Host "  ✅ 已创建 .gitignore" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  .gitignore 已存在，跳过（可手动参考 templates/gitignore）" -ForegroundColor Yellow
}

# ---- 7. 检查 Git 仓库状态 ----
Write-Host ""
Write-Host "----------------------------------------"
Write-Host "  Git 仓库检查"
Write-Host "----------------------------------------"
Push-Location $TargetPath
try {
    if (Test-Path ".git") {
        Write-Host "✅ Git 仓库已初始化" -ForegroundColor Green
        $remotes = git remote -v 2>$null
        if ($remotes -match "origin") {
            Write-Host "✅ Git 远程仓库已配置" -ForegroundColor Green
        } else {
            Write-Host "⚠️  未配置 Git 远程仓库。请执行:" -ForegroundColor Yellow
            Write-Host "   git remote add origin <你的仓库 URL>"
            Write-Host "   git push -u origin main"
        }
    } else {
        Write-Host "⚠️  项目未初始化 Git 仓库。请执行:" -ForegroundColor Yellow
        Write-Host "   git init"
        Write-Host "   git add -A"
        Write-Host '   git commit -m "chore: 初始提交"'
        Write-Host "   git branch -M main"
        Write-Host "   git remote add origin <你的仓库 URL>"
        Write-Host "   git push -u origin main"
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ 安装完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "可用命令:"
Write-Host "  /opsx:propose <描述>   → 创建 change + 分支"
Write-Host "  /opsx:apply             → 在分支上实现"
Write-Host "  /opsx:release <名称>    → 归档 + 版本 + 合并"
Write-Host "  /opsx:abort <名称>      → 放弃 + 清理"
Write-Host ""
Write-Host "详细文档: https://github.com/bula9/openspec-git-workflow"
