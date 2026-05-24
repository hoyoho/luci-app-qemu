# luci-app-qemu

OpenWrt/LEDE QEMU 虚拟机管理器

## 赞助

如果你觉得这个项目对你有帮助，可以赞助我：

<div align="center">

<table>
<tr>
<td><img src="docs/screenshots/wechat.png" width="150"></td>
<td><img src="docs/screenshots/alipay.jpg" width="150"></td>
</tr>
<tr>
<td align="center">微信</td>
<td align="center">支付宝</td>
</tr>
</table>

</div>

## 简介

luci-app-qemu 是一个基于 LuCI 的 Web 界面，用于在 OpenWrt/LEDE 系统上管理 QEMU 虚拟机。它提供了友好的网页界面，可以直接通过浏览器创建、配置、启动、停止和监控虚拟机。

## 截图

### 虚拟机列表
![VM List](docs/screenshots/vm_list.png)

### 添加新虚拟机
![Wizard](docs/screenshots/wizard.png)

### 基本设置
![Basic](docs/screenshots/basic.png)

### 存储配置
![Storage](docs/screenshots/storage.png)

### 网络配置
![Network](docs/screenshots/network.png)

### PCI 设备直通
![Passthrough](docs/screenshots/passthrough.png)

### 全局设置
![Enable](docs/screenshots/enable.png)

## 功能特性

- **虚拟机管理**
  - 向导式创建新虚拟机
  - 启动、停止、重启虚拟机
  - 查看虚拟机状态和资源使用情况
  - 强制停止无响应的虚拟机
  - 自动启动配置

- **硬件配置**
  - CPU 和内存分配
  - 存储设备管理（磁盘镜像、VirtIO、IDE、SCSI、USB）
  - 网络接口配置
  - 显示设置（VNC）
  - 输入设备（键盘、鼠标）
  - 声音设备
  - 控制器设备（USB、SCSI、VirtIO Serial）
  - 主机设备直通（PCI Passthrough）
  - 看门狗定时器

- **高级设置**
  - 启动选项（传统 BIOS/UEFI）
  - VNC 显示密码保护
  - 串口控制台访问
  - QMP 接口高级管理

- **存储管理**
  - 创建和管理磁盘镜像
  - 支持多种磁盘格式（qcow2、raw 等）
  - 磁盘镜像扩容

- **网络配置**
  - 用户模式 NAT 网络
  - Tap 网络
  - Bridge 网桥网络
  - Socket 网络
  - 端口转发

## 系统要求

- OpenWrt 25.12.1 或更高版本（仅支持 x86_64 架构）
- QEMU 软件包：
  - `qemu-system-x86_64`
  - `qemu-img`
  - `qemu-bridge-helper`
  - `qemu-firmware-seabios`（传统 BIOS 支持）
- OVMF 软件包（UEFI 支持）：
  - 从 [edk2-ovmf](https://github.com/hoyoho/edk2-ovmf) 编译适用于 OpenWrt 的版本
- 内核模块：
  - `kmod-tun`
  - `kmod-kvm-amd` 或 `kmod-kvm-intel`（硬件加速）
- 额外软件包：
  - `socat`（QMP 通信）
  - `luci-compat`（LuCI 兼容性）

## 安装

### 通过 APK 包安装

1. 从 [ releases ](https://github.com/hoyoho/luci-app-qemu/releases) 页面下载最新的 APK 包
2. 将 APK 上传到 OpenWrt 设备
3. 安装软件包：
   ```bash
   apk add --force-overwrite --allow-untrusted luci-app-qemu*.apk luci-i18n-qemu-zh-cn*.apk
   ```
4. 安装运行时依赖：
   ```bash
   apk add qemu-system-x86_64 qemu-img qemu-bridge-helper qemu-firmware-seabios kmod-tun kmod-kvm-amd socat
   ```

### 从源码编译

要从源码编译 luci-app-qemu，请将自定义 feed 添加到 OpenWrt 编译环境：

1. 克隆仓库到 OpenWrt SDK 的 packages 目录：
   ```bash
   git clone https://github.com/hoyoho/luci-app-qemu.git /path/to/sdk/package/luci-app-qemu
   ```

2. 进入编译配置菜单：
   ```bash
   make menuconfig
   ```

3. 在 `make menuconfig` 中，导航到 `LuCI → Applications` 选择 luci-app-qemu。

4. 退出并保存，然后编译：
   ```bash
   make package/luci-app-qemu/compile
   ```

## 使用说明

### 访问界面

1. 打开网页浏览器，访问 OpenWrt 路由器的 Web 管理界面
2. 进入 **服务 → QEMU 虚拟机**

### 创建虚拟机

1. 点击 **添加新虚拟机** 启动向导
2. 按步骤配置：
   - 基本设置（名称、描述）
   - 硬件配置（CPU、内存）
   - 存储设备（磁盘镜像）
   - 网络接口
   - 显示设置（VNC）
   - 高级选项
3. 点击 **创建** 完成

### 管理虚拟机

- **启动**：点击 **启动** 按钮启动虚拟机
- **停止**：点击 **停止** 按钮正常关机
- **强制停止**：点击 **强制停止** 按钮立即终止虚拟机
- **重启**：点击 **重启** 按钮重启虚拟机
- **编辑**：点击 **编辑** 按钮修改虚拟机设置
- **删除**：点击 **删除** 按钮删除虚拟机

### VNC 访问

1. 确保在虚拟机显示设置中已启用 VNC
2. 使用 VNC 客户端连接到 `路由器IP:590X`（X 是 VNC 端口偏移量）
3. 如果设置了密码，输入密码

### 存储管理

1. 进入 **存储** 选项卡
2. 点击 **添加磁盘镜像** 创建新磁盘
3. 选择磁盘格式和大小
4. 点击 **创建** 生成磁盘镜像

## 配置说明

### 全局设置

- **存储路径**：磁盘镜像的默认存储位置
- **启用**：QEMU 全局启用/禁用开关

### 虚拟机设置

每个虚拟机都有独立的配置，包括：
- 名称和描述
- CPU 和内存分配
- 存储设备
- 网络接口
- 显示设置
- 启动选项
- 自动启动配置

## 启用 ALSA 音频支持

默认情况下，OpenWrt feed 中的 QEMU 包编译时未启用任何音频后端（`--audio-drv-list=''`）。这意味着在 luci-app-qemu 中配置的声卡设备（AC97、HDA ICH6、HDA ICH9）会静默丢弃所有音频数据。

要通过 ALSA 实现真正的音频输出，需要从 OpenWrt SDK 重新编译 QEMU 包并启用 ALSA 支持。

### 为何需要重新编译

上游 QEMU 包明确禁用了所有音频后端：

```makefile
--audio-drv-list=''        # 不编译任何音频驱动
--disable-alsa             # ALSA 已禁用
--disable-oss              # OSS 已禁用
--disable-pa               # PulseAudio 已禁用
```

这意味着即使你的路由器有正常工作的声卡且已加载 ALSA 驱动，QEMU 也无法使用它们。

### 修改 QEMU 包 Makefile

在 OpenWrt SDK 中找到 QEMU 包：

```
<sdk-root>/package/feeds/packages/qemu/Makefile
```

进行以下修改：

**1. 添加 menuconfig 选项** — 在 `config QEMU_ZSTD` 附近添加：

```makefile
config QEMU_AUDIO_ALSA
	bool "QEMU ALSA audio support"
	default n
```

**2. 更新 configure 参数** — 找到 `--audio-drv-list` 和 `--disable-alsa` 所在行并替换：

```makefile
--audio-drv-list='$(if $(CONFIG_QEMU_AUDIO_ALSA),alsa,)' \
--$(if $(CONFIG_QEMU_AUDIO_ALSA),enable,disable)-alsa \
```

其他音频相关行（`--disable-oss`、`--disable-pa`）保持不变。

**3. 添加依赖** — 在 `qemu-target` 包块的 `DEPENDS` 中添加：

```makefile
+QEMU_AUDIO_ALSA:alsa-lib \
```

**4. 注册配置符号** — 在 `PKG_CONFIG_DEPENDS` 中添加：

```makefile
CONFIG_QEMU_AUDIO_ALSA \
```

### 编译与安装

```bash
# 1. 进入 SDK 目录
cd <sdk-root>

# 2. 在 menuconfig 中启用选项
make menuconfig
# 导航到：Utilities → Virtualization → QEMU ALSA audio support → 启用

# 3. 编译 QEMU 包
make package/qemu/compile V=s

# 4. 查找生成的包
ls bin/packages/*/packages/qemu-*_*.ipk

# 5. 复制到路由器并安装
scp bin/packages/*/packages/qemu-*_*.ipk root@<路由器IP>:/tmp/
ssh root@<路由器IP>
opkg install /tmp/qemu-*.ipk --force-reinstall
```

重新安装 QEMU 包后，luci-app-qemu 中配置的声卡设备将通过路由器的 ALSA 声音系统输出音频。验证安装：

```bash
qemu-system-x86_64 -audiodev help
# 现在应该能在可用音频驱动列表中看到 "alsa"
```

## 故障排除

### 常见问题

1. **虚拟机启动失败**
   - 检查 QEMU 软件包是否已安装
   - 验证磁盘镜像是否存在且可访问
   - 检查端口冲突（尤其是 VNC 端口）

2. **VNC 连接被拒绝**
   - 确保在虚拟机设置中启用了 VNC
   - 检查虚拟机是否正在运行
   - 验证防火墙设置允许 VNC 流量

3. **性能问题**
   - 启用 KVM 硬件加速（如果可用）
   - 调整 CPU 和内存分配
   - 使用 SSD 存储以获得更好的性能

### 日志

- 查看系统日志中的 QEMU 相关消息：
  ```bash
  logread | grep qemu
  ```
- 在 Web 界面中查看虚拟机专用日志

## 参与贡献

欢迎提交 Pull Request！

### 开发指南

- 遵循现有的代码风格
- 彻底测试更改
- 提供清晰的提交信息
- 必要时更新文档

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。
