# Claude Key Setup

快速配置 Claude Code 的 API Key 和端点设置。

## 特性

- ✅ 支持 4 个 API 提供商（Anthropic、OpenRouter、StepFun、自定义）
- ✅ 自动检测 Claude Code 配置位置
- ✅ 自动创建基础配置文件（如果不存在）
- ✅ 前置条件检查（jq、bash、配置）
- ✅ 交互式菜单，简单易用
- ✅ 自动备份原配置

## 快速开始

### 一键配置（交互式）
```bash
curl -fsSL https://raw.githubusercontent.com/Zgh332358/claude-key-setup/main/configure_claude.sh | bash
```

### 下载后运行
```bash
curl -fsSL https://raw.githubusercontent.com/Zgh332358/claude-key-setup/main/configure_claude.sh -o configure_claude.sh
chmod +x configure_claude.sh
bash configure_claude.sh
```

## 支持提供商

| 选项 | 提供商 | API Key 获取地址 |
|------|--------|-----------------|
| 1 | Anthropic 官方 | https://console.anthropic.com/settings/keys |
| 2 | OpenRouter | https://openrouter.ai/keys |
| 3 | StepFun | https://platform.stepfun.com/console/apikeys |
| 4 | 自定义端点 | 手动输入 |

## 前置条件

### 必需
- **jq** - JSON 处理工具
  - macOS: `brew install jq`
  - Ubuntu/Debian: `sudo apt install jq`
  - CentOS/RHEL: `sudo yum install jq`

- **bash** - 脚本运行环境

- **Claude Code** - 已安装 CLI 工具

### 可选
- **配置文件** - 如果不存在，脚本会自动创建

## 使用示例

```bash
# 交互式配置
curl -fsSL https://raw.githubusercontent.com/Zgh332358/claude-key-setup/main/configure_claude.sh | bash

# 选择 1 (Anthropic 官方)
# 输入 API Key: sk-ant-xxx
# 模型名称: claude-3-5-sonnet-20241022 (或回车使用默认)
```

## 配置文件位置

脚本会按顺序检查：
1. `~/.claude/settings.json` (推荐)
2. `~/.claude/settings.local.json`
3. `/root/.claude/settings.json`

如果都不存在，会在 `~/.claude/settings.json` 创建新配置。

## 配置结构

脚本会修改 `settings.json` 的以下字段：
- `env.ANTHROPIC_AUTH_TOKEN` - API Key
- `env.ANTHROPIC_BASE_URL` - API 端点
- `model` - 默认模型

## License

MIT License
