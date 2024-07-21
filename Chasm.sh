#!/bin/bash

# 询问用户输入 SCOUT_UID 和 WEBHOOK_API_KEY
echo "请输入 SCOUT_UID："
read SCOUT_UID

echo "请输入 WEBHOOK_API_KEY："
read WEBHOOK_API_KEY

echo "请输入 GROQ_API_KEY："
read GROQ_API_KEY

# 定义安装节点的函数
function install_node() {
    # 检查是否已安装 Docker
    if ! command -v docker &> /dev/null; then
        echo "安装 Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
    else
        echo "Docker 已安装，跳过安装步骤。"
    fi

    # 获取当前系统的公网 IP 地址
    ip=$(curl -s4 ifconfig.me/ip)

    # 构建 webhook 的 URL
    WEBHOOK_URL="http://$ip:3001/"

    # 输出 webhook URL
    echo "Webhook URL: $WEBHOOK_URL"

    # 切换到用户的主目录并创建 scout 目录
    cd ~ || exit 1  # 如果切换失败则退出脚本
    mkdir -p scout
    cd scout || exit 1  # 如果切换失败则退出脚本

    # 使用 tee 命令将内容写入 .env 文件
    tee .env > /dev/null <<EOF
    PORT=3001
    LOGGER_LEVEL=debug
    
    # Chasm
    ORCHESTRATOR_URL=https://orchestrator.chasm.net
    SCOUT_NAME=myscout
    SCOUT_UID=$SCOUT_UID
    WEBHOOK_API_KEY=$WEBHOOK_API_KEY
    # Scout Webhook Url, update based on your server's IP and Port
    # e.g. http://123.123.123.123:3001/
    WEBHOOK_URL=$WEBHOOK_URL

    # Chosen Provider (groq, openai)
    PROVIDERS=groq
    MODEL=gemma2-9b-it
    GROQ_API_KEY=$GROQ_API_KEY

    # Optional
    OPENROUTER_API_KEY=$OPENROUTER_API_KEY
    OPENAI_API_KEY=$OPENAI_API_KEY
EOF

    # 输出 .env 文件内容，用于验证
    echo "Contents of .env file:"
    cat .env

    # 提示用户是否退出脚本
    echo "是否退出？填写no下一步 (yes/no)"
    read answer

    if [ "$answer" != "yes" ]; then
        echo "查看完毕，退出脚本。"
        exit 1
    fi

    # 设置防火墙规则允许端口 3001
    echo "设置防火墙规则允许端口 3001..."
    sudo ufw allow 3001
    sudo ufw allow 3001/tcp

    # 拉取 Docker 镜像并运行
    if docker pull johnsonchasm/chasm-scout; then
        docker run -d --restart=always --env-file ./.env -p 3001:3001 --name scout johnsonchasm/chasm-scout
    else
        echo "拉取 Docker 镜像失败，请检查网络或稍后重试。"
        exit 1
    fi

    # 从 .env 文件中加载环境变量
    source ./.env

    # 输出消息
    echo "请求已发送，退出脚本。"
    exit 0
}

# 发送 POST 请求到 webhook 的函数
function send_webhook_request() {
    # 切换到 scout 目录
    cd scout || exit 1  # 如果切换失败则退出脚本

    # 加载环境变量
    source ./.env

    # 使用 curl 发送 POST 请求到 webhook
    curl -X POST \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $WEBHOOK_API_KEY" \
         -d '{"body":"{\"model\":\"gemma2-9b-it\",\"messages\":[{\"role\":\"system\",\"content\":\"You are a helpful assistant.\"}]}"}' \
         "$WEBHOOK_URL"
}


# 主菜单
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "特别鸣谢 Silent ⚛| validator"
        echo "================================================================"
        echo "节点社区 Telegram 群组:https://t.me/niuwuriji"
        echo "节点社区 Telegram 频道:https://t.me/niuwuriji"
        echo "节点社区 Discord 社群:https://discord.gg/GbMV5EcNWF"
        echo "退出脚本，请按键盘ctrl c退出即可"
        echo "请选择要执行的操作:"
        echo "1. 安装节点"
        echo "2. 测试LLM"
        read -p "请输入选项（1-2）: " OPTION

        case $OPTION in
        1) install_node ;;
        2) send_webhook_request ;;
        *) echo "无效选项，请重新输入。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 显示主菜单
main_menu
