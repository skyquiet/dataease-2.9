#!/bin/bash

################################################################################
# DataEase v2.9 状态查看脚本
#
# 功能说明：
# 查看 DataEase 服务运行状态、端口占用、日志等信息
#
# 使用方法：
#   chmod +x status.sh
#   ./status.sh
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
DEPLOY_DIR="/Users/sun/dataease2.0"
PID_FILE="$DEPLOY_DIR/dataease.pid"
LOG_DIR="$DEPLOY_DIR/logs"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}DataEase v2.9 状态信息${NC}"
echo -e "${GREEN}================================${NC}"

# 1. 检查服务状态
echo -e "\n${BLUE}[服务状态]${NC}"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "状态: ${GREEN}运行中${NC}"
        echo -e "PID: ${YELLOW}$PID${NC}"

        # 显示进程信息
        PS_INFO=$(ps -p "$PID" -o pid,ppid,%cpu,%mem,vsz,rss,start,time,comm | tail -n 1)
        echo -e "进程信息: ${YELLOW}$PS_INFO${NC}"

        # 显示运行时间
        UPTIME=$(ps -p "$PID" -o etime= | xargs)
        echo -e "运行时间: ${YELLOW}$UPTIME${NC}"
    else
        echo -e "状态: ${RED}已停止${NC}"
        echo -e "PID 文件存在但进程不存在，可能异常退出"
    fi
else
    echo -e "状态: ${RED}未运行${NC}"
fi

# 2. 检查端口占用
echo -e "\n${BLUE}[端口信息]${NC}"
PORT_8100=$(lsof -i :8100 -P -n 2>/dev/null | grep LISTEN || echo "")
if [ -n "$PORT_8100" ]; then
    echo -e "8100 端口: ${GREEN}已监听${NC}"
    echo -e "$PORT_8100"
else
    echo -e "8100 端口: ${RED}未监听${NC}"
fi

# 3. 检查配置文件
echo -e "\n${BLUE}[配置文件]${NC}"
CONFIG_FILE="$DEPLOY_DIR/config/application.yml"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "配置文件: ${GREEN}存在${NC}"
    echo -e "路径: ${YELLOW}$CONFIG_FILE${NC}"

    # 显示数据库配置
    DB_URL=$(grep -A 1 "datasource:" "$CONFIG_FILE" | grep "url:" | awk '{print $2}')
    if [ -n "$DB_URL" ]; then
        echo -e "数据库: ${YELLOW}$DB_URL${NC}"
    fi
else
    echo -e "配置文件: ${RED}不存在${NC}"
fi

# 4. 检查日志
echo -e "\n${BLUE}[日志信息]${NC}"
if [ -d "$LOG_DIR" ]; then
    echo -e "日志目录: ${GREEN}$LOG_DIR${NC}"

    # 显示最近的日志文件
    echo -e "\n最近的日志文件:"
    ls -lht "$LOG_DIR" 2>/dev/null | head -n 6

    # 显示最后 10 行日志
    CONSOLE_LOG="$LOG_DIR/console.log"
    if [ -f "$CONSOLE_LOG" ]; then
        echo -e "\n${YELLOW}最近 10 行日志:${NC}"
        tail -n 10 "$CONSOLE_LOG"
    fi
else
    echo -e "日志目录: ${RED}不存在${NC}"
fi

# 5. 检查磁盘空间
echo -e "\n${BLUE}[磁盘空间]${NC}"
df -h "$DEPLOY_DIR" 2>/dev/null || df -h /

# 6. 显示快捷命令
echo -e "\n${BLUE}[快捷命令]${NC}"
echo -e "查看实时日志: ${YELLOW}tail -f $LOG_DIR/console.log${NC}"
echo -e "停止服务:     ${YELLOW}./stop.sh${NC}"
echo -e "启动服务:     ${YELLOW}./start.sh${NC}"
echo -e "重启服务:     ${YELLOW}./restart.sh${NC}"
echo -e "访问地址:     ${YELLOW}http://localhost:8100${NC}"
