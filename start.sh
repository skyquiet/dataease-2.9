#!/bin/bash

################################################################################
# DataEase v2.9 自动启动脚本
#
# 功能说明：
# 1. 检查运行环境（JDK, MySQL, 配置文件）
# 2. 检查并修复数据库 Flyway 迁移问题
# 3. 启动 DataEase 服务
#
# 使用方法：
#   chmod +x start.sh
#   ./start.sh
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
DEPLOY_DIR="/Users/sun/dataease2.0"
JAR_FILE="$DEPLOY_DIR/CoreApplication.jar"
CONFIG_FILE="$DEPLOY_DIR/config/application.yml"
LOG_DIR="$DEPLOY_DIR/logs"
PID_FILE="$DEPLOY_DIR/dataease.pid"

# MySQL 配置（从配置文件读取，这里是默认值）
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="dataeaseV2demo"
DB_USER="root"
DB_PASS="123456"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}DataEase v2.9 启动脚本${NC}"
echo -e "${GREEN}================================${NC}"

# 1. 检查服务是否已运行
echo -e "\n${YELLOW}[1/6] 检查服务状态...${NC}"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}服务已在运行 (PID: $PID)${NC}"
        echo -e "如需重启，请先执行: ${YELLOW}./stop.sh${NC}"
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

# 2. 检查环境
echo -e "\n${YELLOW}[2/6] 检查运行环境...${NC}"

# 检查 JDK
if [ -z "$JAVA_HOME" ]; then
    echo -e "${RED}错误: JAVA_HOME 环境变量未设置${NC}"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [ "$JAVA_VERSION" != "21" ]; then
    echo -e "${RED}错误: 需要 JDK 21，当前版本: $JAVA_VERSION${NC}"
    exit 1
fi
echo -e "${GREEN}✓ JDK 21 检查通过${NC}"

# 检查 JAR 文件
if [ ! -f "$JAR_FILE" ]; then
    echo -e "${RED}错误: JAR 文件不存在: $JAR_FILE${NC}"
    echo -e "请先运行编译脚本: ${YELLOW}./build.sh${NC}"
    exit 1
fi
echo -e "${GREEN}✓ JAR 文件存在${NC}"

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}错误: 配置文件不存在: $CONFIG_FILE${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 配置文件存在${NC}"

# 检查 MySQL 连接
if ! command -v mysql &> /dev/null; then
    echo -e "${YELLOW}警告: MySQL 客户端未安装，跳过数据库检查${NC}"
else
    if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME" 2>/dev/null; then
        echo -e "${GREEN}✓ MySQL 连接正常${NC}"
    else
        echo -e "${RED}错误: 无法连接到 MySQL 数据库${NC}"
        echo -e "数据库: ${YELLOW}$DB_NAME${NC}"
        echo -e "主机: ${YELLOW}$DB_HOST:$DB_PORT${NC}"
        exit 1
    fi
fi

# 3. 检查并修复 Flyway 迁移问题
echo -e "\n${YELLOW}[3/6] 检查数据库迁移状态...${NC}"

if command -v mysql &> /dev/null; then
    # 检查是否有失败的迁移记录
    FAILED_COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" \
        -se "SELECT COUNT(*) FROM flyway_schema_history WHERE success = 0" 2>/dev/null || echo "0")

    if [ "$FAILED_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}发现 $FAILED_COUNT 条失败的迁移记录${NC}"
        echo -e "${YELLOW}是否清理失败的迁移记录？(y/n)${NC}"
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" \
                -e "DELETE FROM flyway_schema_history WHERE success = 0"
            echo -e "${GREEN}✓ 已清理失败的迁移记录${NC}"
        fi
    else
        echo -e "${GREEN}✓ 没有失败的迁移记录${NC}"
    fi

    # 检查 de_standalone_version 表是否存在
    TABLE_EXISTS=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" \
        -se "SHOW TABLES LIKE 'de_standalone_version'" 2>/dev/null || echo "")

    if [ -z "$TABLE_EXISTS" ]; then
        echo -e "${YELLOW}创建缺失的 de_standalone_version 表...${NC}"
        mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
CREATE TABLE IF NOT EXISTS \`de_standalone_version\` (
  \`id\` bigint NOT NULL AUTO_INCREMENT,
  \`version\` varchar(255) DEFAULT NULL COMMENT '版本号',
  \`create_time\` bigint DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (\`id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='数据库版本变更记录表';
EOF
        echo -e "${GREEN}✓ de_standalone_version 表创建成功${NC}"
    fi
fi

# 4. 创建日志目录
echo -e "\n${YELLOW}[4/6] 准备日志目录...${NC}"
mkdir -p "$LOG_DIR"
echo -e "${GREEN}✓ 日志目录: $LOG_DIR${NC}"

# 5. 设置 JVM 参数
echo -e "\n${YELLOW}[5/6] 配置 JVM 参数...${NC}"
JVM_OPTS="-Xmx4g -Xms2g"
JVM_OPTS="$JVM_OPTS -XX:+UseG1GC"
JVM_OPTS="$JVM_OPTS -XX:MaxGCPauseMillis=200"
JVM_OPTS="$JVM_OPTS -Djava.awt.headless=true"
JVM_OPTS="$JVM_OPTS -Dfile.encoding=UTF-8"
echo -e "${GREEN}✓ JVM 参数: $JVM_OPTS${NC}"

# 6. 启动服务
echo -e "\n${YELLOW}[6/6] 启动 DataEase 服务...${NC}"

cd "$DEPLOY_DIR"

# 启动命令
START_CMD="java $JVM_OPTS -jar $JAR_FILE"
START_CMD="$START_CMD --spring.config.location=config/application.yml"
START_CMD="$START_CMD --logging.config=config/logback-spring.xml"

echo -e "${BLUE}启动命令: $START_CMD${NC}"

# 后台启动并记录 PID
nohup $START_CMD > "$LOG_DIR/console.log" 2>&1 &
PID=$!
echo $PID > "$PID_FILE"

echo -e "${GREEN}✓ 服务已启动 (PID: $PID)${NC}"

# 等待服务启动
echo -e "\n${YELLOW}等待服务启动...${NC}"
for i in {1..30}; do
    sleep 2
    if grep -q "Started CoreApplication" "$LOG_DIR/console.log" 2>/dev/null; then
        echo -e "${GREEN}✓ 服务启动成功！${NC}"
        break
    fi
    if ! ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${RED}服务启动失败！${NC}"
        echo -e "请查看日志: ${YELLOW}$LOG_DIR/console.log${NC}"
        rm -f "$PID_FILE"
        exit 1
    fi
    echo -n "."
done

# 完成
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}DataEase 启动完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "访问地址: ${BLUE}http://localhost:8100${NC}"
echo -e "API 文档: ${BLUE}http://localhost:8100/doc.html${NC}"
echo -e "默认账号: ${YELLOW}admin / DataEase@123456${NC}"
echo -e "\n日志文件: ${YELLOW}$LOG_DIR/console.log${NC}"
echo -e "实时日志: ${YELLOW}tail -f $LOG_DIR/console.log${NC}"
echo -e "停止服务: ${YELLOW}./stop.sh${NC}"
