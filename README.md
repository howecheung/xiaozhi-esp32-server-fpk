# 智控台 · xiaozhi-esp32-server fnOS FPK

把官方 [xinnan-tech/xiaozhi-esp32-server](https://github.com/xinnan-tech/xiaozhi-esp32-server)
以**全模块**方式封装成飞牛 fnOS `.fpk` 应用，用于让 ESP32 小智设备连接自建后端。

> ✅ **已验证可运行版本：v0.9.6.5**（2026-09-06，fnOS 实机）
> 本地 FunASR/SenseVoice ASR + Silero VAD 正常初始化，WebSocket 服务可启动。

应用包版本号使用 `<上游版本>.<FPK修订>` 格式（当前上游 `v0.9.6` → 包版本
`0.9.6.5`），镜像默认使用国内镜像站
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
- 支持本地 FunASR ASR：FPK 只挂载 `model.pt` 单文件，不覆盖镜像内置的
  Silero VAD；首次启动 server 时若 `model.pt` 仍是占位文件，会自动从
  ModelScope → HuggingFace → hf-mirror 依次下载真实模型（约 900MB，
  存于 `@appdata/xiaozhi-esp32-server/models/SenseVoiceSmall/model.pt`）；
- 镜像内置 Silero VAD，FPK 不再整目录挂载 `models`，避免覆盖镜像自带模型。

## 安装

1. 飞牛桌面 → 应用中心 → 手动安装，选择 Release 里的 `xiaozhi-esp32-server-<版本>.fpk`；
2. 首次启动需要从 `ghcr.nju.edu.cn` 与 Docker Hub 拉取镜像；
3. 首次启动 server 会自动下载本地 ASR 模型，下载完成前 server 会处于等待/重启状态，
   日志出现“SenseVoiceSmall model ready”后继续启动；
4. 点击桌面“智控台”，注册第一个管理员账号。

## 首次配置（重要，三件事）

按官方全模块流程，注册管理员后还需完成：

1. **填写 server.secret**
   在智控台「参数管理」找到 `server.secret` 的参数值并复制；通过 fnOS SSH 编辑
   `/vol1/@appdata/xiaozhi-esp32-server/data/.config.yaml`（注意：这里**没有**
   `var` 这一层，安装回调已生成模板），把
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
- `var` 持久保存：MySQL 数据、Redis 数据、`.config.yaml`、上传文件与已下载的
  SenseVoice 模型；
- 应用中心安装同名新版本 fpk 走升级流程，数据不会被清除；
- 上游出新版由 `auto-upstream` 工作流全自动完成；若只是 FPK 自身修复，
  手动 bump `manifest` 版本后打标签发布即可。

## 重新打包

```powershell
.\build-fpk.ps1
```

产物输出到 `dist\xiaozhi-esp32-server-<版本>.fpk`，并自动在本目录生成同名
带版本号文件。`fnpack` 可放入 PATH，或用 `FNPACK` 环境变量指定路径。

> 如国内镜像站拉取失败，可将 compose 里所有
> `ghcr.nju.edu.cn/xinnan-tech/...` 替换为 `ghcr.io/xinnan-tech/...`。

## 完整使用流程（安装 → 可对话）

1. 应用中心手动安装 `xiaozhi-esp32-server-<版本>.fpk`，首次会拉取 4 个镜像。
2. server 首次启动自动下载 SenseVoice 模型（约 900MB），期间会显示下载进度，
   完成前不要重启容器；出现 `SenseVoiceSmall model ready` 后继续初始化。
3. 浏览器打开 `http://NAS局域网IP:8002`，注册第一个管理员。
4. SSH 到 fnOS，把智控台「参数管理」里的 `server.secret` 写入：

   ```bash
   docker inspect xiaozhi-esp32-server --format '{{range .Mounts}}{{println .Source " -> " .Destination}}{{end}}'
   sudo nano /vol1/@appdata/xiaozhi-esp32-server/data/.config.yaml
   docker start xiaozhi-esp32-server   # 若此前已 stop
   ```

5. 智控台「模型配置」填 LLM/TTS（ASR 已用本地 FunASR 可不再填云端 ASR）。
6. 智控台「参数管理」把 `server.websocket` 设为
   `ws://NAS局域网IP:8000/xiaozhi/v1/`。
7. ESP32 固件填写：

   ```text
   WebSocket: ws://NAS局域网IP:8000/xiaozhi/v1/
   OTA:       http://NAS局域网IP:8002/xiaozhi/ota/
   ```

8. 看日志确认：

   ```bash
   docker logs --tail 60 xiaozhi-esp32-server
   ```

   出现 `Websocket地址是 ws://...:8000/xiaozhi/v1/` 即服务可用
   （日志里的 IP 是容器内网地址，不要填到设备里）。

## 构建与踩坑记录

| 版本 | 说明 |
| --- | --- |
| 0.9.6.1 | 首个全模块 FPK（server + 智控台 + MySQL + Redis），GitHub Actions 自动构建 |
| 0.9.6.2 | 应用改名“智控台”，换官方图标 |
| 0.9.6.3 | fnOS 升级后不刷新图标：改图标文件名强制刷新缓存 |
| 0.9.6.4 | 修复：整目录挂载空 `models/` 会盖掉镜像内置 Silero VAD；只挂 `model.pt` 并首次自动下载 |
| 0.9.6.5 | 修复：bind-mount 单文件不能用 rename 覆盖（EBUSY），改为写入文件本体 + `.sensevoice_model_ready` 标记 |

踩坑要点：

- 镜像源 `ghcr.nju.edu.cn` TLS 超时则改用 `ghcr.io`；
- 配置文件路径是 `/vol1/@appdata/xiaozhi-esp32-server/data/.config.yaml`，
  不要多加 `var/`；
- 模型下载期间不要重启容器，否则从头再下；
- 不要在 compose 里整目录挂载 `models/`，会覆盖镜像自带 VAD；
- `model.pt` 若用 bind-mount 单文件，只能原地写入，不能 `rename` 覆盖；
- ESP32 里填 NAS 局域网 IP，不是 docker 日志里的内网 IP。

## GitHub 自动化说明

- `auto-upstream.yml`：每 6 小时检测上游 Release，发现新稳定版自动更新镜像
  tag、manifest、README，提交、打标签并创建 Release；
- `build-fpk.yml`：Release 发布后自动下载 fnpack、校验版本、打包并上传 FPK。

两个工作流无需人工参与；如需 FPK 自身修复，手动 bump 版本再发布即可。
