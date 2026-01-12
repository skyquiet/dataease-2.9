#!/bin/bash

################################################################################
# DataEase v2.9 重启脚本
#
# 功能说明：
# 先停止服务，然后重新启动
#
# 使用方法：
#   chmod +x restart.sh
#   ./restart.sh
#
# 作者：Claude
# 日期：2026-01-13
################################################################################

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}DataEase v2.9 重启脚本${NC}"
echo -e "${GREEN}================================${NC}"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 停止服务
echo -e "\n${YELLOW}步骤 1: 停止服务${NC}"
bash "$SCRIPT_DIR/stop.sh"

# 等待 2 秒
echo -e "\n${YELLOW}等待 2 秒...${NC}"
sleep 2

# 启动服务
echo -e "\n${YELLOW}步骤 2: 启动服务${NC}"
bash "$SCRIPT_DIR/start.sh"
