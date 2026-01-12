#!/bin/bash

################################################################################
# DataEase v2.9 自动编译脚本
#
# 功能说明：
# 1. 检查环境（JDK 21, Maven）
# 2. 自动下载并安装缺失的依赖包（calcite-core, calcite-linq4j）
# 3. 编译后端项目
# 4. 复制编译产物到运行目录
#
# 使用方法：
#   chmod +x build.sh
#   ./build.sh
#
# 作者：Claude
# 日期：2026-01-13
################################################################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_DIR="/Users/sun/c-space/dataease-2.9"
DEPLOY_DIR="/Users/sun/dataease2.0"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}DataEase v2.9 自动编译脚本${NC}"
echo -e "${GREEN}================================${NC}"

# 1. 检查环境
echo -e "\n${YELLOW}[1/5] 检查编译环境...${NC}"

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

# 检查 Maven
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}错误: Maven 未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Maven 检查通过${NC}"

# 2. 下载并安装缺失的依赖
echo -e "\n${YELLOW}[2/5] 检查并安装缺失的依赖...${NC}"

cd "$PROJECT_DIR"

# 检查 calcite-core 是否已安装
if ! mvn dependency:get -Dartifact=org.apache.calcite:calcite-core:1.35.12:jar:de -q 2>/dev/null; then
    echo -e "${YELLOW}下载 calcite-core:1.35.12:de...${NC}"
    curl -f -o /tmp/calcite-core-1.35.12-de.jar \
        "https://repository.fit2cloud.com/repository/fit2cloud-public/org/apache/calcite/calcite-core/1.35.12/calcite-core-1.35.12-de.jar"

    echo -e "${YELLOW}安装 calcite-core 到本地仓库...${NC}"
    mvn install:install-file \
        -Dfile=/tmp/calcite-core-1.35.12-de.jar \
        -DgroupId=org.apache.calcite \
        -DartifactId=calcite-core \
        -Dversion=1.35.12 \
        -Dclassifier=de \
        -Dpackaging=jar \
        -q

    rm -f /tmp/calcite-core-1.35.12-de.jar
    echo -e "${GREEN}✓ calcite-core 安装成功${NC}"
else
    echo -e "${GREEN}✓ calcite-core 已存在${NC}"
fi

# 检查 calcite-linq4j 是否已安装
if ! mvn dependency:get -Dartifact=org.apache.calcite:calcite-linq4j:1.0.1 -q 2>/dev/null; then
    echo -e "${YELLOW}下载 calcite-linq4j:1.0.1...${NC}"
    curl -f -o /tmp/calcite-linq4j-1.0.1.jar \
        "https://repository.fit2cloud.com/repository/fit2cloud-public/org/apache/calcite/calcite-linq4j/1.0.1/calcite-linq4j-1.0.1.jar"

    echo -e "${YELLOW}安装 calcite-linq4j 到本地仓库...${NC}"
    mvn install:install-file \
        -DgroupId=org.apache.calcite \
        -DartifactId=calcite-linq4j \
        -Dversion=1.0.1 \
        -Dpackaging=jar \
        -Dfile=/tmp/calcite-linq4j-1.0.1.jar \
        -q

    rm -f /tmp/calcite-linq4j-1.0.1.jar
    echo -e "${GREEN}✓ calcite-linq4j 安装成功${NC}"
else
    echo -e "${GREEN}✓ calcite-linq4j 已存在${NC}"
fi

# 3. 编译项目
echo -e "\n${YELLOW}[3/5] 开始编译项目...${NC}"

cd "$PROJECT_DIR"
echo -e "${YELLOW}执行: mvn clean install -Dmaven.test.skip=true${NC}"
mvn clean install -Dmaven.test.skip=true

if [ $? -ne 0 ]; then
    echo -e "${RED}编译失败！${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 项目编译成功${NC}"

# 4. 编译后端服务
echo -e "\n${YELLOW}[4/5] 编译后端服务...${NC}"

cd "$PROJECT_DIR/core"
echo -e "${YELLOW}执行: mvn clean package -Pstandalone -U -Dmaven.test.skip=true${NC}"
mvn clean package -Pstandalone -U -Dmaven.test.skip=true

if [ $? -ne 0 ]; then
    echo -e "${RED}后端编译失败！${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 后端编译成功${NC}"

# 5. 复制编译产物
echo -e "\n${YELLOW}[5/5] 复制编译产物到部署目录...${NC}"

# 创建部署目录
mkdir -p "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/config"
mkdir -p "$DEPLOY_DIR/logs"

# 复制 JAR 包
JAR_FILE="$PROJECT_DIR/core/core-backend/target/CoreApplication.jar"
if [ -f "$JAR_FILE" ]; then
    cp "$JAR_FILE" "$DEPLOY_DIR/"
    echo -e "${GREEN}✓ JAR 包已复制到: $DEPLOY_DIR/CoreApplication.jar${NC}"
else
    echo -e "${RED}错误: 找不到编译产物: $JAR_FILE${NC}"
    exit 1
fi

# 检查配置文件
if [ ! -f "$DEPLOY_DIR/config/application.yml" ]; then
    echo -e "${YELLOW}警告: 配置文件不存在，请手动创建: $DEPLOY_DIR/config/application.yml${NC}"
fi

# 完成
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}编译完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "部署目录: ${GREEN}$DEPLOY_DIR${NC}"
echo -e "JAR 文件: ${GREEN}$DEPLOY_DIR/CoreApplication.jar${NC}"
echo -e "\n下一步："
echo -e "1. 确保已配置 ${YELLOW}$DEPLOY_DIR/config/application.yml${NC}"
echo -e "2. 运行 ${YELLOW}./start.sh${NC} 启动服务"
