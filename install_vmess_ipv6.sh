#!/bin/sh
echo "Starting Xray VMess WS Installer..."
set -e

# 自动修复 Windows 换行
if file "$0" | grep -qi CRLF; then
  echo "Fixing CRLF format..."
  sed -i 's/\r$//' "$0"
fi

XRAY_VERSION="1.8.24"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip"

# 你的 IPv6 地址
SERVER_IP6="2001:41d0:303:3e79:be24:11ff:feff:ac09"

WS_PORT=8080
WS_PATH="/ws"
UUID=$(cat /proc/sys/kernel/random/uuid)

echo "📦 安装依赖..."
apk update
apk add --no-cache curl unzip bash openrc

echo "📥 下载 Xray..."
mkdir -p /usr/local/xray
cd /usr/local/xray
curl -L -o xray.zip $XRAY_URL
unzip xray.zip
chmod +x xray

echo "⚙️ 写入 Xray 配置..."
mkdir -p /etc/xray

cat > /etc/xray/config.json <<EOF
{
  "inbounds":[
    {
      "listen": "::",
      "port": ${WS_PORT},
      "protocol": "vmess",
      "settings":{
        "clients":[{"id":"${UUID}"}]
      },
      "streamSettings":{
        "network":"ws",
        "wsSettings":{
          "path":"${WS_PATH}"
        }
      }
    }
  ],
  "outbounds":[
    {
      "protocol":"freedom",
      "settings":{}
    }
  ]
}
EOF

echo "🛠 创建 Alpine OpenRC 服务..."
cat > /etc/init.d/xray <<EOF
#!/sbin/openrc-run

name="xray"
command="/usr/local/xray/xray"
command_args="run -c /etc/xray/config.json"
command_background=true
pidfile="/run/\${RC_SVCNAME}.pid"

depend() {
  need net
}
EOF

chmod +x /etc/init.d/xray
rc-update add xray default

echo "🚀 启动 Xray 服务..."
rc-service xray restart

echo ""
echo "🎉 安装成功！！下面是你的客户端信息："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "服务器地址 : [${SERVER_IP6}]"
echo "端口       : ${WS_PORT}"
echo "UUID       : ${UUID}"
echo "协议       : VMess"
echo "传输方式   : WebSocket"
echo "WS路径     : ${WS_PATH}"
echo "TLS        : 关闭"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📌 注意："
echo "在客户端填写 IPv6 时，地址要加中括号："
echo "例如： [${SERVER_IP6}]"
