# 彩虹键盘光效

三星风格彩虹流光 + 按键扩散波纹，目标为 iOS 15–17、iPhone 14 Pro Max，支持原生键盘和微信输入法。

## 已实现

- 彩虹渐变流光
- 整个键盘区域覆盖（不改变键位布局）
- 按键触摸扩散波纹
- 原生键盘 / 微信输入法配置项
- 中文 PreferenceLoader 设置页
- Rootless 与 Roothide 编译目标入口

## GitHub Actions 编译

仓库已经包含完整的 GitHub Actions。Workflow 不再依赖不存在的 `theos/setup-theos` Action，而是直接 clone Theos：

```text
.github/workflows/build.yml
```

把整个 `RainbowKeyboard` 目录上传到 GitHub 仓库根目录后，进入：

`Actions → Build RainbowKeyboard → Run workflow`

或直接 push 到 `main` / `master` 分支。Workflow 会分别生成两个 Artifact：

- `RainbowKeyboard-rootless`
- `RainbowKeyboard-roothide`

每个 Artifact 内包含对应的 `.deb` 文件。编译机使用 GitHub macOS runner，自动安装 Theos、Roothide Theos 和 iOS 15.2 SDK，不需要把编译环境打包进源码仓库。

也可以在本地已配置 Theos 的环境执行：

```sh
make clean
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
make clean
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide
```

Roothide 版本必须使用 Relaxin / Roothide 兼容的 Theos 分支；普通 Theos 不能可靠生成 Roothide 包。

## 安装后

打开“设置 → 彩虹键盘光效”，启用原生键盘和微信输入法。修改配置后，建议强制退出正在使用的输入法宿主应用，或切换一次键盘。

## 兼容说明

- 微信输入法不同版本的键盘扩展 Bundle ID 可能不同，需要根据设备实际 Bundle ID 补充 `RainbowKeyboard.plist` 的过滤项。
- 第一次测试建议先只启用原生键盘；确认动画稳定后再启用微信输入法。
- 当前实现使用通用 UIKit 视图识别，避免依赖单一私有类名，但不同 iOS 小版本仍需实机验证。
- iOS 15–17 的 PreferenceBundle 编译需要对应 SDK 的 Preferences 私有头文件。


## CI 验证说明

GitHub Actions 会先把 `dpkg-deb -c` 的完整列表保存到文件，再执行检查，避免 `grep -q` 提前关闭管道导致 `tar: stdout: write error: Broken pipe`。该错误属于 CI 检查脚本的管道问题，不代表 `.deb` 本身损坏。
