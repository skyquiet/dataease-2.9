# DataEase v2.9 自动化脚本使用说明

本目录提供了一套完整的自动化脚本，用于简化 DataEase v2.9 的编译、启动、停止等操作。

## 脚本列表

| 脚本名称 | 功能说明 | 使用场景 |
|---------|---------|---------|
| `build.sh` | 自动编译项目 | 首次部署或代码更新后 |
| `start.sh` | 启动服务 | 启动 DataEase 服务 |
| `stop.sh` | 停止服务 | 停止运行中的服务 |
| `restart.sh` | 重启服务 | 更新配置或代码后 |
| `status.sh` | 查看状态 | 查看服务运行状态和日志 |

## 快速开始

### 1. 首次部署

```bash
# 1. 进入项目目录
cd /Users/sun/c-space/dataease-2.9

# 2. 确保脚本有执行权限
chmod +x *.sh

# 3. 编译项目
./build.sh

# 4. 配置数据库连接（如果还没配置）
# 编辑 ~/dataease2.0/config/application.yml
# 修改数据库连接信息

# 5. 启动服务
./start.sh
```

### 2. 日常使用

```bash
# 查看服务状态
./status.sh

# 停止服务
./stop.sh

# 启动服务
./start.sh

# 重启服务
./restart.sh
```

## 详细说明

### build.sh - 编译脚本

**功能**：
1. 检查编译环境（JDK 21, Maven）
2. 自动下载并安装缺失的依赖包（calcite-core, calcite-linq4j）
3. 编译整个项目
4. 编译后端服务
5. 复制编译产物到部署目录

**使用**：
```bash
./build.sh
```

**输出**：
- 编译后的 JAR 包：`~/dataease2.0/CoreApplication.jar`
- 编译日志显示在控制台

**常见问题**：
- 如果编译失败，检查 JDK 版本是否为 21
- 如果依赖下载失败，检查网络连接

---

### start.sh - 启动脚本

**功能**：
1. 检查运行环境（JDK, 配置文件, 数据库）
2. 自动修复 Flyway 迁移问题
3. 后台启动 DataEase 服务
4. 等待服务启动并验证

**使用**：
```bash
./start.sh
```

**启动参数**：
- JVM 内存：`-Xmx4g -Xms2g`
- 垃圾回收器：G1GC
- 配置文件：`~/dataease2.0/config/application.yml`

**日志输出**：
- 控制台日志：`~/dataease2.0/logs/console.log`
- 实时查看：`tail -f ~/dataease2.0/logs/console.log`

**常见问题**：
- 如果启动失败，查看 `~/dataease2.0/logs/console.log`
- 如果端口 8100 被占用，检查其他进程
- 如果数据库连接失败，检查 `application.yml` 配置

---

### stop.sh - 停止脚本

**功能**：
1. 优雅停止服务（发送 SIGTERM）
2. 等待进程退出（最多 30 秒）
3. 如果进程未退出，强制终止（SIGKILL）

**使用**：
```bash
./stop.sh
```

---

### restart.sh - 重启脚本

**功能**：
先调用 `stop.sh` 停止服务，然后调用 `start.sh` 重新启动。

**使用**：
```bash
./restart.sh
```

**适用场景**：
- 修改配置文件后
- 更新代码重新编译后
- 服务异常需要重启

---

### status.sh - 状态查看脚本

**功能**：
1. 显示服务运行状态（进程、PID、运行时间）
2. 显示端口监听情况
3. 显示配置文件路径和数据库配置
4. 显示最近的日志
5. 显示磁盘空间使用情况

**使用**：
```bash
./status.sh
```

**输出示例**：
```
================================
DataEase v2.9 状态信息
================================

[服务状态]
状态: 运行中
PID: 12345
运行时间: 01:23:45

[端口信息]
8100 端口: 已监听

[配置文件]
配置文件: 存在
数据库: jdbc:mysql://localhost:3306/dataeaseV2demo

[日志信息]
最近 10 行日志:
...
```

---

## 配置文件说明

### application.yml 模板

创建 `~/dataease2.0/config/application.yml`：

```yaml
server:
  tomcat:
    connection-timeout: 70000

spring:
  servlet:
    multipart:
      max-file-size: 500MB
      max-request-size: 500MB
  datasource:
    url: jdbc:mysql://localhost:3306/dataeaseV2demo?autoReconnect=false&useUnicode=true&characterEncoding=UTF-8&characterSetResults=UTF-8&zeroDateTimeBehavior=convertToNull&useSSL=false&allowPublicKeyRetrieval=true
    username: root
    password: YOUR_PASSWORD  # 修改为实际密码
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true
    baseline-version: 0
    validate-on-migrate: false
    out-of-order: true
    ignore-missing-migrations: true
  main:
    allow-circular-references: true
  quartz:
    job-store-type: memory
    auto-startup: true

logging:
  level:
    org.springframework: INFO
    org.quartz: INFO

dataease:
  version: 2.9.0
```

---

## 目录结构

```
/Users/sun/c-space/dataease-2.9/    # 源码目录
├── build.sh                         # 编译脚本
├── start.sh                         # 启动脚本
├── stop.sh                          # 停止脚本
├── restart.sh                       # 重启脚本
├── status.sh                        # 状态脚本
├── scripts-README.md                # 本文档
└── core/                            # 核心代码

/Users/sun/dataease2.0/             # 运行目录
├── CoreApplication.jar              # 运行的 JAR 包
├── config/
│   └── application.yml              # 配置文件
├── logs/
│   └── console.log                  # 日志文件
└── dataease.pid                     # 进程 ID 文件
```

---

## 常见问题

### Q1: 编译失败，提示 JDK 版本不对
**A**: 确保使用 JDK 21，检查 `JAVA_HOME` 环境变量。

### Q2: 启动失败，提示数据库连接错误
**A**: 检查 `application.yml` 中的数据库配置，确保 MySQL 服务运行正常。

### Q3: 启动后无法访问 http://localhost:8100
**A**:
1. 检查服务是否真的启动成功：`./status.sh`
2. 查看日志：`tail -f ~/dataease2.0/logs/console.log`
3. 检查端口是否被占用：`lsof -i :8100`

### Q4: Flyway 迁移失败
**A**:
1. 查看失败记录：`mysql -u root -p -e "SELECT * FROM dataeaseV2demo.flyway_schema_history WHERE success = 0;"`
2. 删除失败记录：启动脚本会自动提示清理
3. 或手动执行：`mysql -u root -p dataeaseV2demo -e "DELETE FROM flyway_schema_history WHERE success = 0;"`

### Q5: 如何修改 JVM 内存配置
**A**: 编辑 `start.sh`，修改 `JVM_OPTS` 变量：
```bash
JVM_OPTS="-Xmx8g -Xms4g"  # 调整为需要的内存大小
```

---

## 进阶使用

### 开机自启动

可以使用 `launchd` (macOS) 或 `systemd` (Linux) 配置开机自启动。

#### macOS 示例

创建 `~/Library/LaunchAgents/com.dataease.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.dataease</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/sun/c-space/dataease-2.9/start.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
```

加载配置：
```bash
launchctl load ~/Library/LaunchAgents/com.dataease.plist
```

---

## 更新日志

- **2026-01-13**: 初始版本
  - 创建编译、启动、停止、重启、状态脚本
  - 自动处理 Flyway 迁移问题
  - 自动下载缺失的依赖包

---

## 联系与支持

如有问题，请参考：
- 官方文档：https://dataease.io/docs/
- GitHub：https://github.com/dataease/dataease
- 本地文档：`DataEase_v2.9_编译运行文档.md`
