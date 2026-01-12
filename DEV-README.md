# DataEase v2.9 开发环境快速指南

## 概述

本指南提供了 DataEase v2.9 开发环境的快速启动方法，包括一键启动脚本和常见问题解决方案。

## 前置条件

确保已安装以下软件：
- **JDK 21**
- **Maven 3.9.6+**
- **Node.js 18.x**
- **MySQL 8.0+**
- **Git**

## 快速开始

### 1. 编译项目

```bash
# 首次运行需要先编译
./build.sh
```

### 2. 启动开发环境

```bash
# 一键启动前后端服务
./start-dev.sh
```

启动后可以访问：
- **前端界面**: http://localhost:9528
- **后端 API**: http://localhost:8100
- **API 文档**: http://localhost:8100/doc.html

默认账号密码：`admin / DataEase@123456`

### 3. 查看服务状态

```bash
# 查看运行状态
./status-dev.sh
```

### 4. 停止服务

```bash
# 停止所有服务
./stop-dev.sh
```

## 脚本说明

### start-dev.sh
**功能**：一键启动开发环境
- 自动创建必要的工作目录
- 配置缓存和日志路径
- 启动后端服务 (端口 8100)
- 启动前端服务 (端口 9528)
- 自动检查依赖和编译产物

**使用场景**：
- 首次启动开发环境
- 每天开始开发工作时
- 系统重启后

### stop-dev.sh
**功能**：停止所有开发服务
- 优雅停止后端服务
- 优雅停止前端服务
- 清理进程和释放端口
- 如果优雅停止失败，会强制终止

**使用场景**：
- 结束开发工作时
- 切换分支或更新代码前
- 重启服务前

### status-dev.sh
**功能**：查看服务运行状态
- 显示前后端服务状态
- 显示进程 ID 和运行时间
- 检查端口占用情况
- 测试 HTTP 连接
- 显示数据库连接状态
- 显示磁盘使用情况

**使用场景**：
- 检查服务是否正常运行
- 排查启动问题
- 查看日志文件位置

## 目录结构

```
dataease-2.9/
├── start-dev.sh          # 启动脚本
├── stop-dev.sh           # 停止脚本
├── status-dev.sh         # 状态检查脚本
├── build.sh              # 编译脚本
├── core/
│   ├── core-backend/     # 后端代码
│   └── core-frontend/    # 前端代码
└── ...

~/dataease-workspace/     # 工作目录
├── cache/                # 缓存目录
├── config/               # 配置文件
│   └── ehcache.xml      # 缓存配置
├── data/                 # 数据目录
└── pids/                 # 进程 ID 文件

~/dataease-logs/          # 日志目录
├── backend.log           # 后端日志
└── frontend.log          # 前端日志
```

## 常见问题

### 1. 端口已被占用

**症状**：启动失败，提示端口被占用

**解决**：
```bash
# 查看端口占用
lsof -i :8100
lsof -i :9528

# 停止占用端口的进程
./stop-dev.sh
```

### 2. 前端依赖未安装

**症状**：前端启动失败，提示 `vite: command not found`

**解决**：
```bash
cd core/core-frontend
npm install
```

### 3. 日志目录权限错误

**症状**：后端启动失败，提示无法创建日志文件

**解决**：脚本会自动创建在用户目录下的日志文件，无需手动处理

### 4. 缓存目录创建失败

**症状**：后端启动失败，EhcacheException

**解决**：脚本会自动创建并配置缓存目录，无需手动处理

### 5. 页面加载慢

**症状**：首次访问页面加载时间长

**原因**：
- 开发环境未压缩代码
- 实时编译 TypeScript
- ESLint 代码检查
- 大量独立模块请求

**说明**：这是正常现象，后续刷新会利用缓存快很多

### 6. 数据库连接失败

**症状**：后端启动失败，无法连接数据库

**检查**：
```bash
# 测试数据库连接
mysql -h localhost -P 3306 -uroot -p123456 -e "SHOW DATABASES LIKE 'dataease%'"
```

**解决**：
- 确保 MySQL 服务已启动
- 检查数据库配置（用户名/密码）
- 确认数据库已创建

## 查看日志

### 实时查看后端日志
```bash
tail -f ~/dataease-logs/backend.log
```

### 实时查看前端日志
```bash
tail -f ~/dataease-logs/frontend.log
```

### 查看最近的错误
```bash
# 后端错误
grep ERROR ~/dataease-logs/backend.log | tail -20

# 前端错误
grep ERROR ~/dataease-logs/frontend.log | tail -20
```

## 开发工作流

### 典型的一天

```bash
# 1. 启动服务
./start-dev.sh

# 2. 开发代码...

# 3. 如需查看状态
./status-dev.sh

# 4. 结束工作
./stop-dev.sh
```

### 代码更新后重启

```bash
# 1. 停止服务
./stop-dev.sh

# 2. 更新代码
git pull

# 3. 重新编译（如果需要）
./build.sh

# 4. 重新启动
./start-dev.sh
```

### 切换分支

```bash
# 1. 停止服务
./stop-dev.sh

# 2. 切换分支
git checkout feature-branch

# 3. 重新安装前端依赖（如果 package.json 有变化）
cd core/core-frontend
npm install
cd ../..

# 4. 重新编译
./build.sh

# 5. 启动服务
./start-dev.sh
```

## 性能优化建议

### 前端开发优化

1. **使用本地缓存**：首次加载后，浏览器会缓存大部分资源
2. **禁用 ESLint**（可选）：
   ```bash
   cd core/core-frontend
   ESLINT_DISABLE=true npm run dev -- --port 9528
   ```
3. **关闭不需要的浏览器扩展**：某些扩展会影响页面加载速度

### 后端开发优化

1. **增加 JVM 内存**（如果需要）：
   编辑 `start-dev.sh`，修改启动参数：
   ```bash
   java -Xmx4g -Xms2g -jar ...
   ```

2. **使用 IDE 调试模式**：
   可以直接在 IntelliJ IDEA 中运行 `CoreApplication`，而不使用脚本

## 生产环境构建

开发完成后，构建生产版本：

```bash
# 构建前端
cd core/core-frontend
npm run build:base

# 构建后端
cd ../core-backend
mvn clean package -Pstandalone -DskipTests

# 生成的文件
# 后端：core/core-backend/target/CoreApplication.jar
# 前端：core/core-frontend/dist/
```

## 更多信息

详细的编译和运行文档请参考：
- [DataEase_v2.9_编译运行文档.md](./DataEase_v2.9_编译运行文档.md)

## 技术支持

如遇问题，请查看：
1. 日志文件：`~/dataease-logs/`
2. 官方文档：https://dataease.io/docs/
3. 社区支持：https://github.com/dataease/dataease

---

**最后更新**: 2026-01-13
