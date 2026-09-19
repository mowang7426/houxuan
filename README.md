# 彩虹键盘光效

三星风格彩虹流光 + 按键扩散波纹，目标为 iOS 15–17、iPhone 14 Pro Max，支持原生键盘和微信输入法。

## 已实现

- 彩虹渐变流光
- 整个键盘区域覆盖（不改变键位布局）
- 按键触摸扩散波纹
- 原生键盘 / 微信输入法配置项
- 中文 PreferenceLoader 设置页
- Rootless 与 Roothide 编译目标入口

## 编译环境

需要在 macOS 或已配置 Theos 的越狱开发环境执行：

```sh
make clean
make rootless   # Rootless .deb
make roothide   # Roothide .deb
```

若 Roothide Theos 不识别 `roothide` scheme，请使用 Relaxin 配套的 Theos 分支，并将 `THEOS_PACKAGE_SCHEME` 按其文档修改为对应 scheme。

## 安装后

打开“设置 → 彩虹键盘光效”，启用原生键盘和微信输入法。修改配置后，建议强制退出正在使用的输入法宿主应用，或切换一次键盘。

## 兼容说明

- 微信输入法不同版本的键盘扩展 Bundle ID 可能不同，需要根据设备实际 Bundle ID 补充 `RainbowKeyboard.plist` 的过滤项。
- 第一次测试建议先只启用原生键盘；确认动画稳定后再启用微信输入法。
- 当前实现使用通用 UIKit 视图识别，避免依赖单一私有类名，但不同 iOS 小版本仍需实机验证。
- iOS 15–17 的 PreferenceBundle 编译需要对应 SDK 的 Preferences 私有头文件。
