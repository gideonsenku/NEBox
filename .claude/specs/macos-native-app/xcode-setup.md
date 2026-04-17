# Xcode 手动配置指南 — 新建 RelayMac Target

> ⚠️ 此步骤由用户在 Xcode 中手动执行。Claude 已准备好所有源文件和 Info.plist / entitlements，等待 Xcode 引用。

## 前置确认

执行前确认工作副本无未提交改动：
```bash
cd /Users/senku/develop/repo/NEBox
git status
```

建议先为当前进度创建一个分支：
```bash
git checkout -b feature/macos-native-app
```

## 步骤 1：在 Xcode 中新建 macOS App Target

1. 打开 `Relay.xcodeproj`
2. 顶部菜单 **File → New → Target…**
3. 选择 **macOS → App**，点击 Next
4. 填写：
   - **Product Name**: `RelayMac`
   - **Team**: 保持与 Relay target 一致
   - **Organization Identifier**: `net.sodion` （与 iOS 一致）
   - **Bundle Identifier**: `net.sodion.relay-app.mac`（Xcode 会自动拼接；若有差异可手动修改）
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Testing System**: **None**（勿勾选）
   - **Storage**: **None**
   - **Include Tests**: 不勾选
5. 点击 Finish。Xcode 会在项目根生成一个 `RelayMac` 组，包含 `RelayMacApp.swift`、`ContentView.swift`、`Assets.xcassets`、`Preview Content`、`RelayMac.entitlements`、`Info.plist`

## 步骤 2：替换 Xcode 生成的模板文件

Xcode 自动生成了模板文件，但我们已准备好实际内容。**从 Xcode 项目中移除**以下文件（选中 → Delete → **Move to Trash**）：

- `RelayMac/RelayMacApp.swift` （Xcode 自动生成的模板，将由批次 3 替换）
- `RelayMac/ContentView.swift` （将不使用）
- `RelayMac/Preview Content/` （可选保留，Claude 不会用到）
- `RelayMac/RelayMac.entitlements` （Xcode 生成的空版本，用 Claude 准备的替换）
- `RelayMac/Info.plist` （同上）
- `RelayMac/Assets.xcassets` （Xcode 生成的空版本，用 Claude 准备的替换）

移除后，手动把 Claude 已创建的文件从 Finder 拖回 Xcode 的 `RelayMac` 组（选 **Create groups**，Target Membership 仅勾 `RelayMac`）：

- `RelayMac/Info.plist`
- `RelayMac/RelayMac.entitlements`
- `RelayMac/Assets.xcassets`

## 步骤 3：配置 RelayMac Build Settings

选中 `RelayMac` target → **Build Settings**，确认以下值：

| Setting                                  | 值                              |
|------------------------------------------|---------------------------------|
| `MACOSX_DEPLOYMENT_TARGET`                | `26.0`                          |
| `SUPPORTED_PLATFORMS`                     | `macosx`                        |
| `TARGETED_DEVICE_FAMILY`                  | （macOS target 不需要，留空）   |
| `INFOPLIST_FILE`                          | `RelayMac/Info.plist`           |
| `CODE_SIGN_ENTITLEMENTS`                  | `RelayMac/RelayMac.entitlements`|
| `PRODUCT_BUNDLE_IDENTIFIER`               | `net.sodion.relay-app.mac`      |
| `SWIFT_VERSION`                           | 与 Relay target 一致（5.0 或更高）|
| `ENABLE_HARDENED_RUNTIME`                 | `YES`                           |

## 步骤 4：把 Relay/ 的共享文件加入 RelayMac target

这一步决定了代码复用是否成功。操作方法：**逐个选中下列文件 / 文件夹，在 File Inspector（右侧第一面板）的 Target Membership 中勾选 `RelayMac`**。

### 必须双勾 Target Membership 的文件

#### Models
- `Relay/Models/BoxDataModel.swift`

#### ViewModels
- `Relay/ViewModels/BoxJsViewModel.swift`

#### Services（整个文件夹内所有 .swift）
- `Relay/Services/BoxJSAPI.swift`
- `Relay/Services/NetworkProvider.swift`
- `Relay/Services/ApiRequest.swift`
- `Relay/Services/EnvScriptLoader.swift`

#### Managers
- `Relay/Managers/ApiManager.swift`
- `Relay/Managers/ToastManager.swift`
- `Relay/Managers/LogManager.swift`

#### Extension
- `Relay/Extension/ArrayExtension.swift`
- `Relay/Extension/GlobalToastView.swift`
- `Relay/Extension/ViewModifier.swift` ⚠️ 批次 2 将用 `#if os` 守卫内部的 UIKit 代码

#### Helpers（批次 2 完成后再勾）
这些文件将在批次 2 中被修改为跨平台，届时再勾：
- `Relay/Helpers/Utils.swift`
- `Relay/Helpers/AvatarStorage.swift`
- `Relay/Helpers/Vibration.swift` → 仅 iOS 勾（macOS 会通过 PlatformBridge）
- `Relay/Helpers/PlatformBridge.swift` （批次 2.1 新增，双勾）
- `Relay/Helpers/PlatformColors.swift` （批次 2.2 新增，双勾）
- `Relay/Helpers/PlatformImage.swift` （批次 2.3 新增，双勾）

### 禁止勾 RelayMac 的文件

- `Relay/RelayApp.swift` （仅 iOS）
- `Relay/Views/**` 下**所有**文件 （仅 iOS）
- `Relay/Info.plist` （仅 iOS）
- `Relay/Assets.xcassets` （仅 iOS，RelayMac 使用自己的）

## 步骤 5：添加 SPM 依赖到 RelayMac Target

RelayMac 需要与 Relay 共享相同的 Swift Package 依赖：

1. 选中 `RelayMac` target → **General** 标签
2. **Frameworks, Libraries, and Embedded Content** 中点击 `+`
3. 添加（已在项目中可直接选择）：
   - `Moya`（和 `CombineMoya` 如有）
   - `Alamofire`
   - `AnyCodable`
   - `SDWebImageSwiftUI`
   - `SDWebImage`

## 步骤 6：创建 RelayMac scheme

通常新建 target 时 Xcode 会自动创建对应 scheme。若没有：

1. **Product → Scheme → Manage Schemes…**
2. 确认 `RelayMac` scheme 存在，勾选 **Shared**（方便 CI）

## 步骤 7：验证

- `Product → Destination` 切到 **My Mac**
- `Product → Build`（⌘B）应成功（此时 RelayMacApp.swift 还是 Xcode 模板，会显示默认 "Hello, world"）
- 切回 `Relay` scheme + iPhone 模拟器，构建依然成功

## 完成后通知 Claude

完成以上步骤后，告知 Claude："Xcode target 已配置好"，Claude 会：
1. 验证 `project.pbxproj` 的关键字段
2. 执行批次 1.6（SPM 依赖检查，必要时补齐 pbxproj）
3. 继续批次 2（共享层跨平台抽象）

## 故障排查

| 症状                                      | 解决                                                                |
|------------------------------------------|---------------------------------------------------------------------|
| 构建 RelayMac 时提示 `No such module 'UIKit'` | 检查 Target Membership，确认该文件没有被错误双勾                    |
| 构建提示 `MACOSX_DEPLOYMENT_TARGET=26.0` 不可用 | 升级 Xcode 到 26+ 或 macOS 26+ 编译支持                              |
| SPM 依赖缺失                              | 在 `Package Dependencies` 里确认 RelayMac 被勾选为使用者              |
| 共享 Swift 文件找不到                     | 在文件右侧 File Inspector → Target Membership 双勾                    |
