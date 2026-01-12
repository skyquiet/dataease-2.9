#!/bin/bash

################################################################################
# DataEase v2.9 停止脚本
#
# 功能说明：
# 1. 检查服务运行状态
# 2. 优雅停止服务
# 3. 强制终止（如果必要）
#
# 使用方法：
#   chmod +x stop.sh
#   ./stop.sh
#
# 作者：Claude
# 日期：2026-01-13
################################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置参数
DEPLOY_DIR="/Users/sun/dataease2.0"
PID_FILE="$DEPLOY_DIR/dataease.pid"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}DataEase v2.9 停止脚本${NC}"
echo -e "${GREEN}================================${NC}"

# 检查 PID 文件
if [ ! -f "$PID_FILE" ]; then
    echo -e "${YELLOW}服务未运行（PID 文件不存在）${NC}"
    exit 0
fi

# 读取 PID
PID=$(cat "$PID_FILE")

# 检查进程是否存在
if ! ps -p "$PID" > /dev/null 2>&1; then
    echo -e "${YELLOW}服务未运行（进程不存在）${NC}"
    rm -f "$PID_FILE"
    exit 0
fi

echo -e "${YELLOW}正在停止服务 (PID: $PID)...${NC}"

# 尝试优雅停止
kill "$PID"

# 等待进程退出
for i in {1..30}; do
    if ! ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 服务已停止${NC}"
        rm -f "$PID_FILE"
        exit 0
    fi
    sleep 1
    echo -n "."
done

echo ""
echo -e "${YELLOW}服务未响应，尝试强制终止...${NC}"

# 强制终止
kill -9 "$PID" 2>/dev/null

if ps -p "$PID" > /dev/null 2>&1; then
    echo -e "${RED}无法停止服务 (PID: $PID)${NC}"
    exit 1
else
    echo -e "${GREEN}✓ 服务已强制停止${NC}"
    rm -f "$PID_FILE"
    exit 0
fi
