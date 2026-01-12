#!/bin/bash

################################################################################
# DataEase v2.9 开发环境状态检查脚本
#
# 功能说明：
# 1. 检查后端服务状态
# 2. 检查前端服务状态
# 3. 显示端口占用情况
# 4. 显示日志文件位置
#
# 使用方法：
#   chmod +x status-dev.sh
#   ./status-dev.sh
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
LOG_DIR="$HOME/dataease-logs"
PID_DIR="$WORKSPACE_DIR/pids"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}DataEase v2.9 开发环境状态${NC}"
echo -e "${BLUE}================================${NC}"

# 检查后端服务
echo -e "\n${YELLOW}【后端服务】${NC}"
if [ -f "$PID_DIR/backend.pid" ]; then
    BACKEND_PID=$(cat "$PID_DIR/backend.pid")
    if ps -p "$BACKEND_PID" > /dev/null 2>&1; then
        # 获取进程运行时间
        ETIME=$(ps -p "$BACKEND_PID" -o etime= | tr -d ' ')
        echo -e "状态: ${GREEN}运行中${NC}"
        echo -e "PID: ${GREEN}$BACKEND_PID${NC}"
        echo -e "运行时间: ${GREEN}$ETIME${NC}"
        echo -e "端口: ${GREEN}8100${NC}"
        echo -e "日志文件: ${BLUE}$LOG_DIR/backend.log${NC}"
        echo -e "查看日志: ${YELLOW}tail -f $LOG_DIR/backend.log${NC}"

        # 检查端口
        if lsof -ti:8100 > /dev/null 2>&1; then
            echo -e "端口状态: ${GREEN}正常监听${NC}"
            # 测试 HTTP 访问
            if curl -s http://localhost:8100/ -o /dev/null -w "%{http_code}" | grep -q "200"; then
                echo -e "HTTP 测试: ${GREEN}响应正常${NC}"
            else
                echo -e "HTTP 测试: ${YELLOW}无响应或错误${NC}"
            fi
        else
            echo -e "端口状态: ${RED}未监听${NC}"
        fi
    else
        echo -e "状态: ${RED}已停止${NC} (PID 文件存在但进程不存在)"
        echo -e "PID 文件: $PID_DIR/backend.pid"
    fi
else
    echo -e "状态: ${RED}未启动${NC}"
    echo -e "PID 文件不存在"

    # 检查端口是否被其他进程占用
    BACKEND_PORT_PID=$(lsof -ti:8100 2>/dev/null)
    if [ -n "$BACKEND_PORT_PID" ]; then
        echo -e "${YELLOW}警告: 8100 端口被其他进程占用 (PID: $BACKEND_PORT_PID)${NC}"
    fi
fi

# 检查前端服务
echo -e "\n${YELLOW}【前端服务】${NC}"
if [ -f "$PID_DIR/frontend.pid" ]; then
    FRONTEND_PID=$(cat "$PID_DIR/frontend.pid")
    if ps -p "$FRONTEND_PID" > /dev/null 2>&1; then
        # 获取进程运行时间
        ETIME=$(ps -p "$FRONTEND_PID" -o etime= | tr -d ' ')
        echo -e "状态: ${GREEN}运行中${NC}"
        echo -e "PID: ${GREEN}$FRONTEND_PID${NC}"
        echo -e "运行时间: ${GREEN}$ETIME${NC}"
        echo -e "端口: ${GREEN}9528${NC}"
        echo -e "日志文件: ${BLUE}$LOG_DIR/frontend.log${NC}"
        echo -e "查看日志: ${YELLOW}tail -f $LOG_DIR/frontend.log${NC}"

        # 检查端口
        if lsof -ti:9528 > /dev/null 2>&1; then
            echo -e "端口状态: ${GREEN}正常监听${NC}"
            # 测试 HTTP 访问
            if curl -s http://localhost:9528/ -o /dev/null -w "%{http_code}" | grep -q "200"; then
                echo -e "HTTP 测试: ${GREEN}响应正常${NC}"
            else
                echo -e "HTTP 测试: ${YELLOW}无响应或错误${NC}"
            fi
        else
            echo -e "端口状态: ${RED}未监听${NC}"
        fi
    else
        echo -e "状态: ${RED}已停止${NC} (PID 文件存在但进程不存在)"
        echo -e "PID 文件: $PID_DIR/frontend.pid"
    fi
else
    echo -e "状态: ${RED}未启动${NC}"
    echo -e "PID 文件不存在"

    # 检查端口是否被其他进程占用
    FRONTEND_PORT_PID=$(lsof -ti:9528 2>/dev/null)
    if [ -n "$FRONTEND_PORT_PID" ]; then
        echo -e "${YELLOW}警告: 9528 端口被其他进程占用 (PID: $FRONTEND_PORT_PID)${NC}"
    fi
fi

# 访问地址
echo -e "\n${YELLOW}【访问地址】${NC}"
if ps -p "$(cat "$PID_DIR/backend.pid" 2>/dev/null)" > /dev/null 2>&1 && \
   ps -p "$(cat "$PID_DIR/frontend.pid" 2>/dev/null)" > /dev/null 2>&1; then
    echo -e "前端界面: ${GREEN}http://localhost:9528${NC}"
    echo -e "后端 API: ${GREEN}http://localhost:8100${NC}"
    echo -e "API 文档: ${GREEN}http://localhost:8100/doc.html${NC}"
    echo -e "默认账号: ${YELLOW}admin / DataEase@123456${NC}"
else
    echo -e "${YELLOW}服务未完全启动，无法访问${NC}"
fi

# 数据库连接
echo -e "\n${YELLOW}【数据库连接】${NC}"
if command -v mysql > /dev/null 2>&1; then
    if mysql -h localhost -P 3306 -uroot -p123456 -e "SELECT 1" > /dev/null 2>&1; then
        echo -e "MySQL 连接: ${GREEN}正常${NC}"
        # 检查数据库
        DB_COUNT=$(mysql -h localhost -P 3306 -uroot -p123456 -se "SHOW DATABASES LIKE 'dataease%'" 2>/dev/null | wc -l)
        echo -e "DataEase 数据库: ${GREEN}$DB_COUNT 个${NC}"
    else
        echo -e "MySQL 连接: ${RED}失败${NC}"
    fi
else
    echo -e "MySQL 客户端: ${YELLOW}未安装${NC}"
fi

# 磁盘空间
echo -e "\n${YELLOW}【磁盘空间】${NC}"
if [ -d "$WORKSPACE_DIR" ]; then
    WORKSPACE_SIZE=$(du -sh "$WORKSPACE_DIR" 2>/dev/null | awk '{print $1}')
    echo -e "工作目录: ${BLUE}$WORKSPACE_DIR${NC} (${GREEN}$WORKSPACE_SIZE${NC})"
fi
if [ -d "$LOG_DIR" ]; then
    LOG_SIZE=$(du -sh "$LOG_DIR" 2>/dev/null | awk '{print $1}')
    echo -e "日志目录: ${BLUE}$LOG_DIR${NC} (${GREEN}$LOG_SIZE${NC})"
fi

# 可用操作
echo -e "\n${YELLOW}【可用操作】${NC}"
if ps -p "$(cat "$PID_DIR/backend.pid" 2>/dev/null)" > /dev/null 2>&1 || \
   ps -p "$(cat "$PID_DIR/frontend.pid" 2>/dev/null)" > /dev/null 2>&1; then
    echo -e "停止服务: ${YELLOW}./stop-dev.sh${NC}"
    echo -e "重启服务: ${YELLOW}./stop-dev.sh && ./start-dev.sh${NC}"
else
    echo -e "启动服务: ${YELLOW}./start-dev.sh${NC}"
fi

echo -e "\n${BLUE}================================${NC}"
