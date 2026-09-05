# 智控台 · xiaozhi-esp32-server fnOS FPK

把官方 [xinnan-tech/xiaozhi-esp32-server](https://github.com/xinnan-tech/xiaozhi-esp32-server)
以**全模块**方式封装成飞牛 fnOS `.fpk` 应用，用于让 ESP32 小智设备连接自建后端。

应用包版本号使用 `<上游版本>.<FPK修订>` 格式（当前上游 `v0.9.6` → 包版本
`0.9.6.2`），镜像默认使用国内镜像站
`ghcr.nju.edu.cn/xinnan-tech/xiaozhi-esp32-server`。

仓库内的 `auto-upstream` 工作流会定时检测上游新标签：发现新版后自动更新镜像
tag、manifest 与 README，提交并发布同名 Release，再由 `build-fpk` 工作流自动
构建并附加 FPK。

## 包含的服务

| 容器 | 镜像 | 用途 | 端口 |
| --- | --- | --- | --- |
| xiaozhi-esp32-server | server_0.9.6 | WebSocket 语音后端 + 简单 OTA / 视觉接口 | 8000 / 8003（宿主机固定） |
| xiaozhi-esp32-server-web | web_0.9.6 | 智控台（Java API + Nginx） | 8002（安装时 fnOS 分配宿主机端口） |
| xiaozhi-esp32-server-db | mysql:8.0 | 全模块数据库 | 仅内网 |
| xiaozhi-esp32-server-redis | redis:8.0-alpine | 缓存 | 仅内网 |

## 资源占用优化

- 固定版本号，避免 `latest` 漂移；
- MySQL 固定 `8.0`、Redis 使用 `alpine` 精简镜像；
- 数据库、Redis 只内网暴露，不映射到宿主机；
- 每个容器限制 Docker 日志 10MB×3，避免日志无限增长；
- 给 server / web / db / redis 设置了内存上限（2G / 1.5G / 1G / 512M），
  全部使用云 API 时整组通常在 2-3GB 内运行；
- 不捆绑 FunASR 本地模型（约数百 MB~1GB），默认走云端 ASR；
  需要本地模型时把 `model.pt` 放入
  `@appdata/xiaozhi-esp32-server/var/models/SenseVoiceSmall/` 后重启。

## 安装

1. 飞牛桌面 → 应用中心 → 手动安装，选择 Release 里的 `xiaozhi-esp32-server-<版本>.fpk`；
2. 首次启动需要从 `ghcr.nju.edu.cn` 与 Docker Hub 拉取镜像；
3. 点击桌面“智控台”，注册第一个管理员账号。

## 首次配置（重要，三件事）

按官方全模块流程，注册管理员后还需完成：

1. **填写 server.secret**
   在智控台「参数管理」找到 `server.secret` 的参数值并复制；通过 fnOS SSH 编辑
   `var/data/.config.yaml`（位于应用数据目录，安装回调已生成模板），把
   `manager-api.secret` 改为该值，然后在应用中心重启应用。
2. **配置模型密钥**
   在智控台「模型配置」中填写你使用的 LLM / ASR / TTS 等服务商密钥。
3. **填写 websocket 地址**
   在「参数管理」把 `server.websocket` 设为
   `ws://你的NAS局域网IP:8000/xiaozhi/v1/`。

确认 server 容器日志出现
`Websocket地址是 ws://...:8000/xiaozhi/v1/` 即启动成功。

## ESP32 固件里填写

```
Websocket 接口：ws://你的NAS局域网IP:8000/xiaozhi/v1/
OTA 接口：      http://你的NAS局域网IP:8002/xiaozhi/ota/
```

## 升级渠道

- `appname` 固定为 `xiaozhi-esp32-server`；
- `var` 持久保存：MySQL 数据、Redis 数据、`.config.yaml`、上传文件与可选模型；
- 应用中心安装同名新版本 fpk 走升级流程，数据不会被清除；
- 发布新版本时只需更新 compose 中 `server_*` / `web_*` 镜像 tag 与
  `manifest` 版本，然后重新打包 / 发布 Release。

## 重新打包

```powershell
.\build-fpk.ps1
```

产物输出到 `dist\xiaozhi-esp32-server-<版本>.fpk`，并自动在本目录生成同名
带版本号文件。`fnpack` 可放入 PATH，或用 `FNPACK` 环境变量指定路径。

> 如国内镜像站拉取失败，可将 compose 里所有
> `ghcr.nju.edu.cn/xinnan-tech/...` 替换为 `ghcr.io/xinnan-tech/...`。
