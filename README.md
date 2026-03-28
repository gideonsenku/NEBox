# Relay

<p align="center">
  <img src="NEBox/Assets.xcassets/BoxJs.imageset/BoxJs.png" width="120" alt="Relay Icon" />
</p>

<p align="center">
  <strong>BoxJS iOS 客户端</strong><br/>
  一个美观、原生的 BoxJS 管理工具
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS_16+-blue" />
  <img src="https://img.shields.io/badge/swift-5.0-orange" />
  <img src="https://img.shields.io/badge/version-0.0.2-green" />
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" />
</p>

## 功能特性

- **收藏应用管理** — iOS 主屏幕风格的图标网格，支持长按拖拽排序和编辑模式
- **应用订阅** — 添加、刷新、删除订阅源，卡片式 UI 展示订阅状态和更新时间
- **多代理工具切换** — 支持 Loon / Surge / Shadowrocket / Quantumult X，每个工具独立配置 API 地址
- **应用详情与配置** — 查看应用描述、编辑配置项（单选、复选、文本输入等）
- **会话管理** — 创建、切换、关联多组会话，保存和恢复应用数据状态
- **全局备份** — 一键备份/恢复全部数据，支持导入导出
- **脚本执行** — 内置 JavaScript 控制台，支持远程脚本和自定义脚本运行
- **数据查看器** — 查询、浏览和编辑 BoxJS 存储的键值数据
- **个性化设置** — 主题切换、壁纸模式、背景图片选择等

## 支持的代理工具

| 工具 | 状态 |
|------|------|
| Loon | ✅ |
| Surge | ✅ |
| Shadowrocket | ✅ |
| Quantumult X | ✅ |

每个代理工具可独立配置 BoxJS API 地址，支持一键切换。

## 技术栈

- **UI 框架**: SwiftUI + UIKit（UICollectionView 等高性能组件）
- **架构模式**: MVVM + Combine
- **网络层**: Moya / Alamofire
- **图片加载**: SDWebImage / SDWebImageSwiftUI
- **依赖管理**: Swift Package Manager

### 主要依赖

| 依赖 | 用途 |
|------|------|
| [Moya](https://github.com/Moya/Moya) | 网络抽象层 |
| [Alamofire](https://github.com/Alamofire/Alamofire) | HTTP 客户端 |
| [SDWebImage](https://github.com/SDWebImage/SDWebImage) | 图片缓存与加载 |
| [AnyCodable](https://github.com/Flight-School/AnyCodable) | 动态 JSON 类型支持 |
| [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) | Markdown / HTML 渲染 |
| [SwipeCellKit](https://github.com/SwipeCellKit/SwipeCellKit) | 列表滑动操作 |

## 项目结构

```
Relay/
├── Models/            # 数据模型 (BoxDataResp, AppModel, AppSubCache, Session 等)
├── Views/             # SwiftUI 视图
│   ├── HomeView       # 收藏应用主页
│   ├── SubcribeView   # 应用订阅管理
│   ├── ProfileView    # 个人中心与备份
│   ├── AppDetailView  # 应用详情与配置
│   └── ...
├── ViewModels/        # MVVM ViewModel (BoxJsViewModel)
├── Services/          # 网络服务层
│   ├── BoxJSAPI       # Moya TargetType 定义
│   ├── ApiRequest     # API 请求门面
│   └── NetworkProvider# Moya Provider 封装
├── Managers/          # 全局管理器 (ApiManager, ToastManager)
├── Helpers/           # 工具类 (震动反馈等)
└── Extension/         # 扩展 (Color hex, Toast 视图等)
```

## 构建与运行

### 环境要求

- Xcode 15.4+
- iOS 16.0+
- Swift 5.0

### 步骤

1. 克隆仓库
   ```bash
   git clone https://github.com/gideonsenku/NEBox.git
   cd NEBox
   ```

2. 用 Xcode 打开项目
   ```bash
   open NEBox.xcodeproj
   ```

3. 等待 SPM 自动拉取依赖，选择目标设备后运行

### 配置 BoxJS 地址

首次启动后，点击首页左上角的工具切换按钮，选择你使用的代理工具并输入对应的 BoxJS API 地址（例如 `http://127.0.0.1:9090`）。

## API 兼容性

Relay 通过 REST API 与 BoxJS 后端通信：

- **查询**: `/query/boxdata`, `/query/data/*`, `/query/versions`
- **更新**: `/api/update`, `/api/save`
- **订阅**: `/api/addAppSub`, `/api/deleteAppSub`, `/api/reloadAppSub`
- **备份**: `/api/saveGlobalBak`, `/api/delGlobalBak`, `/api/revertGlobalBak`
- **脚本**: `/api/runScript`

响应格式：`{ "code": 0, "message": "...", ...payload }`

## License

MIT
