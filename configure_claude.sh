#!/bin/bash

# Claude Code API Key 配置脚本
# 支持：curl ... | bash （交互式）
# 自动检测 Claude Code 配置位置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 前置条件检查
check_prerequisites() {
    local all_ok=true

    echo "🔍 检查前置条件..."
    echo ""

    # 1. 检查 jq
    if command -v jq &> /dev/null; then
        echo -e "  ✅ jq: $(jq --version 2>&1 | head -1)"
    else
        echo -e "  ${RED}❌ jq: 未安装${NC}"
        echo ""
        echo -e "  ${YELLOW}安装方法：${NC}"
        echo "    macOS:  brew install jq"
        echo "    Ubuntu/Debian:  sudo apt update && sudo apt install jq"
        echo "    CentOS/RHEL:  sudo yum install jq"
        echo "    Alpine:  apk add jq"
        all_ok=false
    fi

    # 2. 检查 bash
    if [ -n "$BASH_VERSION" ]; then
        echo -e "  ✅ bash: $BASH_VERSION"
    else
        echo -e "  ${RED}❌ bash: 当前不是 bash 环境${NC}"
        all_ok=false
    fi

    # 3. 检查 Claude Code 配置文件（可选）
    local config_found=false
    local config_paths=(
        "$HOME/.claude/settings.json"
        "$HOME/.claude/settings.local.json"
        "/root/.claude/settings.json"
    )

    for cfg in "${config_paths[@]}"; do
        if [ -f "$cfg" ]; then
            echo -e "  ✅ Claude 配置: $cfg"
            config_found=true
            break
        fi
    done

    if [ "$config_found" = false ]; then
        echo -e "  ${YELLOW}⚠️  Claude 配置: 未找到${NC}"
        echo ""
        echo -e "  ${BLUE}提示：${NC}"
        echo "    - 如果 Claude Code 未运行过，这是正常的"
        echo "    - 脚本将在配置时创建配置文件"
        echo "    - 或使用 -c 参数指定配置文件路径"
    fi

    echo ""

    if [ "$all_ok" = false ]; then
        echo -e "${RED}❌ 前置条件检查失败，请解决上述问题后重试${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ 所有必需条件检查通过！${NC}"
    echo ""
}

# 查找配置文件
find_config_file() {
    # 如果用户通过 -c 指定了配置，优先使用
    if [ -n "$CLAUDE_CONFIG" ] && [ -f "$CLAUDE_CONFIG" ]; then
        echo "$CLAUDE_CONFIG"
        return 0
    fi

    # 检查常见位置
    local candidates=(
        "$HOME/.claude/settings.json"
        "$HOME/.claude/settings.local.json"
        "/root/.claude/settings.json"
    )

    for cfg in "${candidates[@]}"; do
        if [ -f "$cfg" ]; then
            echo "$cfg"
            return 0
        fi
    done

    # 默认使用 settings.json（即使不存在）
    echo "$HOME/.claude/settings.json"
    return 0
}

# 创建基础配置（如果不存在）
create_base_config() {
    local config_file="$1"

    # 确保目录存在
    local config_dir
    config_dir="$(dirname "$config_file")"
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
        echo "📁 创建配置目录: $config_dir"
    fi

    # 创建基础配置
    cat > "$config_file" << 'EOF'
{
  "env": {},
  "model": "claude-3-5-sonnet-20241022",
  "statusLine": {
    "type": "command",
    "command": "echo Claude Code"
  },
  "enabledPlugins": {},
  "extraKnownMarketplaces": {}
}
EOF
    echo "✅ 已创建基础配置文件: $config_file"
    echo ""
}

# ========== 主程序开始 ==========

# 1. 检查前置条件
check_prerequisites

# 2. 确定配置文件
CONFIG_FILE="$(find_config_file 2>/dev/null || true)"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠️  配置文件不存在，将自动创建${NC}"
    create_base_config "$CONFIG_FILE"
fi

echo "📁 使用配置文件: $CONFIG_FILE"
echo ""

# 验证配置文件是有效的 JSON
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${RED}❌ 配置文件不是有效的 JSON: $CONFIG_FILE${NC}"
    exit 1
fi

# 3. 菜单
echo "=========================================="
echo "  Claude Code 配置 - 设置 API Key"
echo "=========================================="
echo ""
echo "请选择 API 提供商："
echo "  1) Anthropic 官方（推荐）"
echo "  2) OpenRouter（多模型，价格优化）"
echo "  3) StepFun（思道思）"
echo "  4) 自定义端点"
echo ""

# 4. 读取选择（使用 /dev/tty 支持管道执行）
CHOICE=""
while true; do
    printf "请输入数字 [1-4]: "
    if read -r CHOICE </dev/tty 2>/dev/null; then
        case "$CHOICE" in
            1|2|3|4) break ;;
            *) echo "无效输入，请输入 1、2、3 或 4" ;;
        esac
    else
        echo ""
        echo -e "${RED}❌ 无法读取输入${NC}"
        echo "请勿使用 'curl ... | bash' 方式，应先下载脚本再运行："
        echo "  curl -O <脚本URL>"
        echo "  bash configure_claude.sh"
        exit 1
    fi
done

echo ""

# 5. 根据选择获取配置信息
case "$CHOICE" in
    1)
        PROVIDER="anthropic"
        PROMPT="请输入 Anthropic API Key (sk-ant-...): "
        DEFAULT_MODEL="claude-3-5-sonnet-20241022"
        BASE_URL="https://api.anthropic.com"
        ;;
    2)
        PROVIDER="openrouter"
        PROMPT="请输入 OpenRouter API Key (sk-or-...): "
        DEFAULT_MODEL="claude-3-5-sonnet"
        BASE_URL="https://openrouter.ai/api/v1"
        ;;
    3)
        PROVIDER="stepfun"
        PROMPT="请输入 StepFun API Key: "
        DEFAULT_MODEL="step-1"
        BASE_URL="https://api.stepfun.com/v1"
        ;;
    4)
        PROVIDER="custom"
        read -p "请输入自定义 API 端点 URL: " CUSTOM_BASE_URL </dev/tty
        PROMPT="请输入 API Key: "
        DEFAULT_MODEL=""
        BASE_URL="$CUSTOM_BASE_URL"
        ;;
esac

# 6. 读取 API Key
API_KEY=""
while true; do
    printf "%s" "$PROMPT"
    if read -r API_KEY </dev/tty 2>/dev/null; then
        if [ -n "$API_KEY" ]; then
            break
        else
            echo "API Key 不能为空，请重新输入"
        fi
    else
        echo ""
        echo -e "${RED}❌ 无法读取输入${NC}"
        echo "请先下载脚本再运行"
        exit 1
    fi
done

# 7. 读取模型名称（如果不是自定义）
if [ "$PROVIDER" != "custom" ] && [ -n "$DEFAULT_MODEL" ]; then
    read -p "模型名称 [默认: $DEFAULT_MODEL]: " MODEL_NAME </dev/tty
    MODEL_NAME="${MODEL_NAME:-$DEFAULT_MODEL}"
else
    read -p "请输入模型名称: " MODEL_NAME </dev/tty
fi

# 8. 备份配置
echo ""
echo "📦 正在备份配置文件..."
cp "$CONFIG_FILE" "$CONFIG_FILE.bak.$(date +%Y%m%d%H%M%S)"
echo "   备份文件: $CONFIG_FILE.bak.*"
echo ""

# 9. 应用配置
echo "⚙️  正在配置 Claude Code..."

# 使用 jq 更新配置
case "$PROVIDER" in
    anthropic)
        jq --arg token "$API_KEY" \
           --arg base_url "$BASE_URL" \
           --arg model "$MODEL_NAME" \
           '.env.ANTHROPIC_AUTH_TOKEN = $token |
            .env.ANTHROPIC_BASE_URL = $base_url |
            .model = $model' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        ;;
    openrouter)
        jq --arg token "$API_KEY" \
           --arg base_url "$BASE_URL" \
           --arg model "$MODEL_NAME" \
           '.env.ANTHROPIC_AUTH_TOKEN = $token |
            .env.ANTHROPIC_BASE_URL = $base_url |
            .model = $model |
            .statusLine.type = "command" |
            .statusLine.command = "echo OpenRouter: \($model)"' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        ;;
    stepfun)
        jq --arg token "$API_KEY" \
           --arg base_url "$BASE_URL" \
           --arg model "$MODEL_NAME" \
           '.env.ANTHROPIC_AUTH_TOKEN = $token |
            .env.ANTHROPIC_BASE_URL = $base_url |
            .model = $model |
            .statusLine.type = "command" |
            .statusLine.command = "echo StepFun: \($model)"' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        ;;
    custom)
        jq --arg token "$API_KEY" \
           --arg base_url "$BASE_URL" \
           --arg model "$MODEL_NAME" \
           '.env.ANTHROPIC_AUTH_TOKEN = $token |
            .env.ANTHROPIC_BASE_URL = $base_url |
            .model = $model |
            .statusLine.type = "command" |
            .statusLine.command = "echo Custom: \($model)"' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        ;;
esac

echo -e "  ${GREEN}✅ Claude Code 配置已更新${NC}"
echo ""
echo "=========================================="
echo -e "${GREEN}✨ 配置完成！${NC}"
echo "=========================================="
echo ""
echo "📝 配置文件: $CONFIG_FILE"
echo "📦 备份文件: $CONFIG_FILE.bak.*"
echo ""
echo "⚙️  当前配置："
echo "   提供商: $(case "$PROVIDER" in anthropic) echo "Anthropic 官方" ;; openrouter) echo "OpenRouter" ;; stepfun) echo "StepFun" ;; custom) echo "自定义" ;; esac)"
echo "   API Key: ${API_KEY:0:10}..."
echo "   端点: $BASE_URL"
echo "   模型: $MODEL_NAME"
echo ""
echo "⚠️  重要：请重启 Claude Code 使配置生效"
echo ""
echo "获取 API Key："
case "$PROVIDER" in
    anthropic) echo "  Anthropic: https://console.anthropic.com/settings/keys" ;;
    openrouter) echo "  OpenRouter: https://openrouter.ai/keys" ;;
    stepfun) echo "  StepFun: https://platform.stepfun.com/console/apikeys" ;;
    custom) echo "  请在您的服务提供商处获取 API Key" ;;
esac
echo ""
