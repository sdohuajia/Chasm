#!/bin/bash

# 系统更新和 Docker 安装
echo "正在更新系统..."
sudo apt-get update

# 检查是否已安装 Docker
if ! command -v docker &> /dev/null; then
    echo "正在安装 Docker..."
    sudo apt-get install docker.io
else
    echo "Docker 已安装，跳过安装步骤。"
fi

# 定义安装节点的函数
function install_node() {
    # 询问用户输入 SCOUT_UID、WEBHOOK_API_KEY 和 GROQ_API_KEY
    echo "请输入 SCOUT_UID：(第一次填写后可不填，多开的继续填写)"
    read SCOUT_UID

    echo "请输入 WEBHOOK_API_KEY：(第一次填写后可不填)"
    read WEBHOOK_API_KEY

    echo "请输入 GROQ_API_KEY：(第一次填写后可不填)"
    read GROQ_API_KEY

    # 获取当前系统的公网 IP 地址
    ip=$(curl -s4 ifconfig.me/ip)

    # 提示用户输入端口号
    read -p "请输入端口号（默认为3001）：" PORT
    PORT=${PORT:-3001}  # 如果用户没有输入，则使用默认值3001

    # 创建 scout 目录（如果不存在）
    mkdir -p ~/scout

    # 切换到 scout 目录
    cd ~/scout || {
        echo "切换到 scout 目录失败。请检查目录是否存在或权限设置。"
        exit 1
    }

    # 使用 tee 命令将内容写入 .env 文件
    tee .env > /dev/null <<EOF
    PORT=$PORT
    LOGGER_LEVEL=debug
    
    # Chasm
    ORCHESTRATOR_URL=https://orchestrator.chasm.net
    SCOUT_NAME=myscout
    SCOUT_UID=$SCOUT_UID
    WEBHOOK_API_KEY=$WEBHOOK_API_KEY
    # Scout Webhook Url, update based on your server's IP and Port
    # e.g. http://$ip:$PORT/
    WEBHOOK_URL=http://$ip:$PORT/

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
    echo "是否退出？填写no可下一步 (yes/no)"
    read answer

    if [ "$answer" != "no" ]; then
        echo "查看完毕，退出脚本。"
        exit 1
    fi

    # 设置防火墙规则允许新输入的端口号
    echo "设置防火墙规则允许端口 $PORT..."
    sudo ufw allow $PORT
    sudo ufw allow $PORT/tcp

    # 拉取 Docker 镜像并运行
    if docker pull johnsonchasm/chasm-scout; then
        docker run -d --restart=always --env-file ./.env -p $PORT:$PORT --name scout johnsonchasm/chasm-scout
    else
        echo "拉取 Docker 镜像失败，请检查网络或稍后重试。"
        exit 1
    fi

    # 从 .env 文件中加载环境变量
    source ./.env

    # 输出消息
    echo "节点安装完成。"
}

# 发送 POST 请求到 webhook 的函数
function send_webhook_request() {
    source ./.env

    # 使用 curl 发送 POST 请求到 webhook
    cd ~/scout || {
        echo "切换到 scout 目录失败。请检查目录是否存在或权限设置。"
        exit 1
    }
    curl -X POST \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $WEBHOOK_API_KEY" \
         -d '{"body":"{\"model\":\"gemma2-9b-it\",\"messages\":[{\"role\":\"system\",\"content\":\"You are a helpful assistant.\"}]}"}' \
         "$WEBHOOK_URL"
}

# 查看 scout 日志函数
function view_scout_logs() {
    echo "查看 scout 容器日志..."
    docker logs scout -f --tail 100
}

# 重启节点函数
function restart_node() {
    # 切换到 scout 目录
    cd ~/scout || {
        echo "切换到 scout 目录失败。请检查目录是否存在或权限设置。"
        exit 1
    }

    # 停止和删除旧的 Docker 容器
    echo "停止和删除旧的 Docker 容器..."
    docker stop scout
    docker rm scout

    # 拉取 Docker 镜像并重新运行
    if docker pull johnsonchasm/chasm-scout; then
        docker run -d --restart=always --env-file ./.env -p 3001:3001 --name scout johnsonchasm/chasm-scout
        echo "节点已成功重启。"
    else
        echo "拉取 Docker 镜像失败，请检查网络或稍后重试。"
        exit 1
    fi
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
        echo "3. 查看 Scout 日志"
        echo "4. 重启节点"
        read -p "请输入选项（1-4）: " OPTION

        case $OPTION in
        1) install_node ;;
        2) send_webhook_request ;;
        3) view_scout_logs ;;
        4) restart_node ;;
        *) echo "无效选项，请重新输入。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 显示主菜单
main_menu
