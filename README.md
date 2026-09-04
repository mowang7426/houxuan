# KBGlow - 第三方键盘按键发光插件

iOS 越狱 Tweak，给微信输入法、百度输入法、搜狗输入法添加按键发光效果。

## 支持设备
- iPhone 14 Pro Max / iOS 17.0
- Relaxin + roothide 越狱环境
- 理论支持所有 arm64e / iOS 15+ 越狱设备

## 功能

### 三种发光动画
1. **涟漪扩散** - 按下时从指尖向外扩散光晕，逐渐消失（默认）
2. **常驻光晕** - 按住时常亮，松开后淡出
3. **粒子爆发** - 按下时发射彩色粒子

### 可自定义项（系统设置中）
- 总开关
- 各键盘独立开关（微信/百度/搜狗）
- 动画类型切换
- 发光颜色：8 种预设 + RGB 自定义
- 发光大小（20-150）
- 动画时长（0.1-2.0 秒）
- 不透明度（0.1-1.0）
- 跟随手指位置开关
- 一键重置

## 编译方法

### 方法一：GitHub Actions 在线编译（推荐，无需 Mac）

本项目已内置 `.github/workflows/build.yml`，推送到 GitHub 后自动编译：

1. 在 GitHub 创建一个新仓库（Public 或 Private 均可）
2. 将本项目所有文件推送到仓库：
   ```bash
   cd KBGlow
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/你的用户名/仓库名.git
   git push -u origin main
   ```
3. 打开 GitHub 仓库页面，点击 **Actions** 标签
4. 等待 **Build KBGlow** 工作流运行完成（约 3-5 分钟）
5. 点击运行记录，在页面底部 **Artifacts** 区域下载 `KBGlow-deb`
6. 解压下载的 zip，里面就是编译好的 deb 文件

> 如果 Actions 运行失败，点开日志看报错。常见原因是 SDK 或工具链下载地址失效，更新 `.github/workflows/build.yml` 里的下载链接即可。

### 方法二：本地 Mac 编译

#### 环境要求
- macOS（需要 Xcode / Command Line Tools）
- 已安装 Theos

#### 安装 Theos（如果还没装）
```bash
# 安装依赖
brew install ldid xz

# 克隆 Theos
git clone --recursive https://github.com/theos/theos.git ~/theos
export THEOS=~/theos

# 下载 iOS SDK（需要 Xcode 中提取，或从 https://github.com/theos/sdks 下载）
# 将 iPhoneOS17.0.sdk 放到 ~/theos/sdks/
```

#### 编译
```bash
cd KBGlow
make clean package
```

编译成功后会在 `./packages/` 目录生成 deb 文件：
`com.mowang.kbglow_1.0.0_iphoneos-arm.deb`

## 安装方法

### 普通越狱
1. 将 deb 文件传到手机
2. 用 Sileo / Zebra / Cydia 安装
3. 安装后注销（killall SpringBoard）

### roothide 越狱（你的环境）
roothide 越狱需要对 deb 进行根路径隐藏处理：

**方法一：使用 RootHide Patcher（推荐）**
1. 在手机上安装 RootHide Patcher（通过 Sileo 搜索安装）
2. 打开 RootHide Patcher，选择编译好的 deb 文件
3. 点击 Patch，生成适配 roothide 的 deb
4. 用文件管理器打开 patch 后的 deb，选择用 Sileo 安装
5. 注销生效

**方法二：命令行手动安装**
```bash
# 将 deb 传到手机后 SSH 连接
dpkg -i com.mowang.kbglow_1.0.0_iphoneos-arm.deb
killall -9 SpringBoard
```

## 使用说明

1. 安装完成后，打开 **设置**
2. 找到 **KBGlow** 入口
3. 开启总开关，选择要启用的键盘
4. 自定义发光效果（颜色、大小、动画类型等）
5. 打开任意 App，调出对应键盘，打字即可看到发光效果

## 注意事项

1. **首次安装后需要注销**才能生效
2. 设置修改后**切换一下键盘**（切到别的输入法再切回来）即可生效，无需注销
3. 如果某个键盘没有发光效果，可能是该键盘的按键类名不匹配，可在设置中关闭再开启试试
4. 粒子模式相对耗电，建议日常用涟漪模式
5. 本插件只在第三方键盘扩展进程中加载，不影响系统其他功能

## 文件结构
```
KBGlow/
├── Makefile                  # 主编译配置
├── control                   # deb 包信息
├── KBGlow.plist              # Tweak 进程过滤（只注入键盘扩展）
├── Tweak.xm                  # 核心 hook 代码
├── KBGlowManager.h/m         # 配置管理 + 发光触发
├── KBGlowView.h/m            # 发光动画视图（三种动画）
├── KBGlowPrefs/              # 系统设置面板
│   ├── Makefile
│   ├── control
│   ├── KBGlowPrefs.plist
│   ├── RootListController.h/m    # 主设置页
│   └── ColorPickerController.h/m # 颜色选择页
└── README.md
```

## 技术原理

1. 通过 `CydiaSubstrate` hook `UIView` 的 `touchesBegan:withEvent:`
2. 判断当前进程是否为支持的第三方键盘扩展（通过 bundle ID）
3. 向上遍历视图层级，判断被触摸的 view 是否为按键（类名包含 key/button 等关键词）
4. 在按键位置叠加 `CAGradientLayer`（径向渐变）或 `CAEmitterLayer`（粒子）实现发光效果
5. 设置通过 `NSUserDefaults` 的 App Group 共享，偏好面板和 Tweak 端读写同一 suite

## 版本
v1.0.0
