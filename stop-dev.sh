#!/bin/bash

################################################################################
# DataEase v2.9 开发环境停止脚本
#
# 功能说明：
# 1. 停止前端服务
# 2. 停止后端服务
# 3. 清理 PID 文件
#
# 使用方法：
#   chmod +x stop-dev.sh
#   ./stop-dev.sh
#
# 作者：Claude
# 日期：2026-01-13
################################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置参数
WORKSPACE_DIR="$HOME/dataease-workspace"
PID_DIR="$WORKSPACE_DIR/pids"

echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}DataEase v2.9 开发环境停止${NC}"
echo -e "${YELLOW}================================${NC}"

STOPPED=0

# 停止后端服务
if [ -f "$PID_DIR/backend.pid" ]; then
    BACKEND_PID=$(cat "$PID_DIR/backend.pid")
    if ps -p "$BACKEND_PID" > /dev/null 2>&1; then
        echo -e "\n${YELLOW}停止后端服务 (PID: $BACKEND_PID)...${NC}"
        kill "$BACKEND_PID"

        # 等待进程结束
        for i in {1..10}; do
            if ! ps -p "$BACKEND_PID" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ 后端服务已停止${NC}"
                STOPPED=1
                break
            fi
            sleep 1
        done

        # 如果进程还未结束，强制终止
        if ps -p "$BACKEND_PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}强制终止后端服务...${NC}"
            kill -9 "$BACKEND_PID"
            echo -e "${GREEN}✓ 后端服务已强制停止${NC}"
            STOPPED=1
        fi
    else
        echo -e "\n${YELLOW}后端服务未运行${NC}"
    fi
    rm -f "$PID_DIR/backend.pid"
else
    echo -e "\n${YELLOW}后端服务未运行 (PID 文件不存在)${NC}"
fi

# 停止前端服务
if [ -f "$PID_DIR/frontend.pid" ]; then
    FRONTEND_PID=$(cat "$PID_DIR/frontend.pid")
    if ps -p "$FRONTEND_PID" > /dev/null 2>&1; then
        echo -e "\n${YELLOW}停止前端服务 (PID: $FRONTEND_PID)...${NC}"
        kill "$FRONTEND_PID"

        # 等待进程结束
        for i in {1..10}; do
            if ! ps -p "$FRONTEND_PID" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ 前端服务已停止${NC}"
                STOPPED=1
                break
            fi
            sleep 1
        done

        # 如果进程还未结束，强制终止
        if ps -p "$FRONTEND_PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}强制终止前端服务...${NC}"
            kill -9 "$FRONTEND_PID"
            echo -e "${GREEN}✓ 前端服务已强制停止${NC}"
            STOPPED=1
        fi
    else
        echo -e "\n${YELLOW}前端服务未运行${NC}"
    fi
    rm -f "$PID_DIR/frontend.pid"
else
    echo -e "\n${YELLOW}前端服务未运行 (PID 文件不存在)${NC}"
fi

# 额外检查：通过端口查找并停止相关进程
echo -e "\n${YELLOW}检查端口占用情况...${NC}"

# 检查 8100 端口 (后端)
BACKEND_PORT_PID=$(lsof -ti:8100 2>/dev/null)
if [ -n "$BACKEND_PORT_PID" ]; then
    echo -e "${YELLOW}发现 8100 端口被占用 (PID: $BACKEND_PORT_PID)，正在停止...${NC}"
    kill "$BACKEND_PORT_PID" 2>/dev/null
    sleep 2
    if lsof -ti:8100 > /dev/null 2>&1; then
        kill -9 "$BACKEND_PORT_PID" 2>/dev/null
    fi
    echo -e "${GREEN}✓ 8100 端口已释放${NC}"
    STOPPED=1
fi

# 检查 9528 端口 (前端)
FRONTEND_PORT_PID=$(lsof -ti:9528 2>/dev/null)
if [ -n "$FRONTEND_PORT_PID" ]; then
    echo -e "${YELLOW}发现 9528 端口被占用 (PID: $FRONTEND_PORT_PID)，正在停止...${NC}"
    kill "$FRONTEND_PORT_PID" 2>/dev/null
    sleep 2
    if lsof -ti:9528 > /dev/null 2>&1; then
        kill -9 "$FRONTEND_PORT_PID" 2>/dev/null
    fi
    echo -e "${GREEN}✓ 9528 端口已释放${NC}"
    STOPPED=1
fi

# 完成
echo -e "\n${GREEN}================================${NC}"
if [ $STOPPED -eq 1 ]; then
    echo -e "${GREEN}服务已全部停止${NC}"
else
    echo -e "${GREEN}没有运行中的服务${NC}"
fi
echo -e "${GREEN}================================${NC}"
