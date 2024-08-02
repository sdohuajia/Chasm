安装教程：铸造NFT以获取SCOUT_UID 和 WEBHOOK_API_KEY，你的钱包中需要有0.1个Mantle链的MNT作为GAS

打开https://scout.chasm.net/private-mint
点击_mint(scout)

点击Setup my scouts，复制这里的内容粘贴到服务器上

注册groq 账户,获取api key
https://console.groq.com/keys
创建API Key

保存好获得的api key，在服务器中输入

GROQ_API_KEY=你得到的APIKEY



执行脚本 
wget -O Chasm.sh https://raw.githubusercontent.com/sdohuajia/Chasm/main/Chasm.sh && chmod +x Chasm.sh && ./Chasm.sh

照脚本的提示操作：包括安装 Docker、设置环境变量、拉取 Docker 镜像等步骤
