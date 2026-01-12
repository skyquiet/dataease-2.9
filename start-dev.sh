#!/bin/bash

################################################################################
# DataEase v2.9 开发环境启动脚本
#
# 功能说明：
# 1. 检查并创建必要的工作目录
# 2. 启动后端服务 (端口 8100)
# 3. 启动前端服务 (端口 9528)
# 4. 显示访问地址和日志位置
#
# 使用方法：
#   chmod +x start-dev.sh
#   ./start-dev.sh
#
# 作者：Claude
# 日期：2026-01-13
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置参数
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$HOME/dataease-workspace"
CACHE_DIR="$WORKSPACE_DIR/cache"
LOG_DIR="$HOME/dataease-logs"
BACKEND_DIR="$PROJECT_DIR/core/core-backend"
FRONTEND_DIR="$PROJECT_DIR/core/core-frontend"
PID_DIR="$WORKSPACE_DIR/pids"

# 日志文件
BACKEND_LOG="$LOG_DIR/backend.log"
FRONTEND_LOG="$LOG_DIR/frontend.log"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}DataEase v2.9 开发环境启动${NC}"
echo -e "${GREEN}================================${NC}"

# 1. 检查服务是否已运行
echo -e "\n${YELLOW}[1/6] 检查服务状态...${NC}"
if [ -f "$PID_DIR/backend.pid" ]; then
    BACKEND_PID=$(cat "$PID_DIR/backend.pid")
    if ps -p "$BACKEND_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}后端服务已在运行 (PID: $BACKEND_PID)${NC}"
        echo -e "如需重启，请先执行: ${YELLOW}./stop-dev.sh${NC}"
        exit 0
    fi
fi

if [ -f "$PID_DIR/frontend.pid" ]; then
    FRONTEND_PID=$(cat "$PID_DIR/frontend.pid")
    if ps -p "$FRONTEND_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}前端服务已在运行 (PID: $FRONTEND_PID)${NC}"
        echo -e "如需重启，请先执行: ${YELLOW}./stop-dev.sh${NC}"
        exit 0
    fi
fi

# 2. 创建必要目录
echo -e "\n${YELLOW}[2/6] 创建工作目录...${NC}"
mkdir -p "$WORKSPACE_DIR/cache"
mkdir -p "$WORKSPACE_DIR/config"
mkdir -p "$WORKSPACE_DIR/data/map"
mkdir -p "$WORKSPACE_DIR/data/static-resource"
mkdir -p "$LOG_DIR"
mkdir -p "$PID_DIR"
echo -e "${GREEN}✓ 工作目录已创建${NC}"

# 3. 创建 ehcache 配置文件
echo -e "\n${YELLOW}[3/6] 检查缓存配置...${NC}"
EHCACHE_CONFIG="$WORKSPACE_DIR/config/ehcache.xml"
if [ ! -f "$EHCACHE_CONFIG" ]; then
    echo -e "${YELLOW}创建 ehcache 配置文件...${NC}"
    cp "$BACKEND_DIR/src/main/resources/ehcache/ehcache.xml" "$EHCACHE_CONFIG"
    # 替换缓存目录路径
    sed -i '' "s|/opt/dataease2.0/cache|$CACHE_DIR|g" "$EHCACHE_CONFIG" 2>/dev/null || \
    sed -i "s|/opt/dataease2.0/cache|$CACHE_DIR|g" "$EHCACHE_CONFIG"
    echo -e "${GREEN}✓ ehcache 配置已创建${NC}"
else
    echo -e "${GREEN}✓ ehcache 配置已存在${NC}"
fi

# 4. 检查编译产物
echo -e "\n${YELLOW}[4/6] 检查编译产物...${NC}"
if [ ! -f "$BACKEND_DIR/target/CoreApplication.jar" ]; then
    echo -e "${RED}错误: 后端未编译，请先运行: ./build.sh${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 后端 JAR 文件存在${NC}"

# 检查前端依赖
if [ ! -d "$FRONTEND_DIR/node_modules" ]; then
    echo -e "${YELLOW}前端依赖未安装，正在安装...${NC}"
    cd "$FRONTEND_DIR"
    npm install
    echo -e "${GREEN}✓ 前端依赖安装完成${NC}"
else
    echo -e "${GREEN}✓ 前端依赖已安装${NC}"
fi

# 5. 启动后端服务
echo -e "\n${YELLOW}[5/6] 启动后端服务...${NC}"
cd "$BACKEND_DIR"

# 启动后端
nohup java -jar target/CoreApplication.jar \
  --spring.profiles.active=standalone \
  --logging.file.path="$LOG_DIR" \
  --spring.cache.jcache.config="file:$EHCACHE_CONFIG" \
  > "$BACKEND_LOG" 2>&1 &

BACKEND_PID=$!
echo $BACKEND_PID > "$PID_DIR/backend.pid"
echo -e "${GREEN}✓ 后端服务已启动 (PID: $BACKEND_PID)${NC}"

# 等待后端启动
echo -e "${YELLOW}等待后端启动...${NC}"
for i in {1..30}; do
    sleep 2
    if grep -q "Started CoreApplication" "$BACKEND_LOG" 2>/dev/null; then
        echo -e "${GREEN}✓ 后端启动成功！${NC}"
        break
    fi
    if ! ps -p "$BACKEND_PID" > /dev/null 2>&1; then
        echo -e "${RED}后端启动失败！${NC}"
        echo -e "请查看日志: ${YELLOW}$BACKEND_LOG${NC}"
        rm -f "$PID_DIR/backend.pid"
        exit 1
    fi
    echo -n "."
done
echo ""

# 6. 启动前端服务
echo -e "\n${YELLOW}[6/6] 启动前端服务...${NC}"
cd "$FRONTEND_DIR"

# 启动前端
nohup npm run dev -- --port 9528 > "$FRONTEND_LOG" 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > "$PID_DIR/frontend.pid"
echo -e "${GREEN}✓ 前端服务已启动 (PID: $FRONTEND_PID)${NC}"

# 等待前端启动
echo -e "${YELLOW}等待前端启动...${NC}"
for i in {1..20}; do
    sleep 2
    if grep -q "ready in" "$FRONTEND_LOG" 2>/dev/null; then
        echo -e "${GREEN}✓ 前端启动成功！${NC}"
        break
    fi
    if ! ps -p "$FRONTEND_PID" > /dev/null 2>&1; then
        echo -e "${RED}前端启动失败！${NC}"
        echo -e "请查看日志: ${YELLOW}$FRONTEND_LOG${NC}"
        rm -f "$PID_DIR/frontend.pid"
        exit 1
    fi
    echo -n "."
done
echo ""

# 完成
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}DataEase 开发环境启动完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "前端访问地址: ${BLUE}http://localhost:9528${NC}"
echo -e "后端 API 地址: ${BLUE}http://localhost:8100${NC}"
echo -e "API 文档地址: ${BLUE}http://localhost:8100/doc.html${NC}"
echo -e ""
echo -e "默认账号: ${YELLOW}admin / DataEase@123456${NC}"
echo -e ""
echo -e "后端日志: ${YELLOW}tail -f $BACKEND_LOG${NC}"
echo -e "前端日志: ${YELLOW}tail -f $FRONTEND_LOG${NC}"
echo -e ""
echo -e "停止服务: ${YELLOW}./stop-dev.sh${NC}"
echo -e "查看状态: ${YELLOW}./status-dev.sh${NC}"
