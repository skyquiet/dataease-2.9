# DataEase v2.9 自动化脚本 - 快速参考

## 一键命令速查

```bash
# 【首次部署】完整流程
./build.sh              # 1. 编译项目
./start.sh              # 2. 启动服务

# 【日常使用】
./status.sh             # 查看状态
./stop.sh               # 停止服务
./restart.sh            # 重启服务

# 【查看日志】
tail -f ~/dataease2.0/logs/console.log

# 【访问地址】
http://localhost:8100
```

## 脚本功能

| 脚本 | 功能 | 执行时间 |
|-----|------|---------|
| `build.sh` | 编译整个项目 | ~5-10 分钟 |
| `start.sh` | 启动服务 | ~20-30 秒 |
| `stop.sh` | 停止服务 | ~5 秒 |
| `restart.sh` | 重启服务 | ~30 秒 |
| `status.sh` | 查看状态 | 立即 |

## 问题排查

### 启动失败？
```bash
# 1. 查看详细日志
tail -100 ~/dataease2.0/logs/console.log

# 2. 检查数据库连接
mysql -h localhost -u root -p123456 dataeaseV2demo -e "SELECT 1"

# 3. 清理失败的 Flyway 记录（启动脚本会自动提示）
```

### 端口被占用？
```bash
# 查看 8100 端口
lsof -i :8100

# 杀死占用进程
kill -9 <PID>
```

### 重新编译？
```bash
./stop.sh               # 停止服务
./build.sh              # 重新编译
./start.sh              # 启动服务
```

## 详细文档

- 完整文档：[scripts-README.md](scripts-README.md)
- 编译运行文档：[DataEase_v2.9_编译运行文档.md](DataEase_v2.9_编译运行文档.md)
