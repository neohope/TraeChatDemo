# TraeChatDemo 前端

## 项目概述

TraeChatDemo 前端是一个使用 Flutter 开发的跨平台聊天应用客户端，支持 iOS、Android 和 Web 平台。

## 功能特点

- 用户注册和登录
- 个人资料管理
- 一对一聊天
- 群组聊天
- 多媒体消息（图片、视频、文件等）
- 消息通知
- 多语言支持
- 深色/浅色主题切换

## 技术栈

- **Flutter/Dart**：跨平台UI框架
- **Provider/Bloc**：状态管理
- **Dio**：网络请求
- **Hive/SharedPreferences**：本地存储
- **Socket.IO**：实时通信
- **GetIt**：依赖注入
- **Intl**：国际化

## 目录结构

```
├── assets/              # 静态资源
│   ├── fonts/          # 字体文件
│   └── images/         # 图片资源
├── lib/                # 主要代码目录
│   ├── app.dart        # 应用入口
│   ├── core/           # 核心功能和工具
│   │   ├── config/     # 应用配置
│   │   ├── di/         # 依赖注入
│   │   ├── error/      # 错误处理
│   │   ├── network/    # 网络相关
│   │   └── theme/      # 主题配置
│   ├── data/           # 数据层
│   │   ├── datasources/ # 数据源
│   │   ├── models/     # 数据模型
│   │   └── repositories/ # 仓库实现
│   ├── domain/         # 领域层
│   │   ├── entities/   # 实体模型
│   │   ├── repositories/ # 仓库接口
│   │   └── usecases/   # 用例
│   ├── l10n/           # 国际化
│   ├── main.dart       # 程序入口
│   ├── presentation/   # 表现层
│   │   ├── blocs/      # 状态管理
│   │   ├── pages/      # 页面
│   │   ├── providers/  # 提供者
│   │   └── widgets/    # 组件
│   └── utils/          # 工具类
├── l10n.yaml           # 国际化配置
├── pubspec.lock        # 依赖锁定文件
├── pubspec.yaml        # 项目配置和依赖
├── test/               # 测试目录
└── web/                # Web平台特定文件
```

## 开发环境设置

### 前提条件

- Flutter SDK (最新稳定版)
- Dart SDK
- Android Studio / VS Code
- Xcode (仅限 macOS，用于 iOS 开发)

### 安装步骤

1. 克隆仓库：
   ```bash
   git clone https://github.com/yourusername/TraeChatDemo.git
   cd TraeChatDemo/frontend
   ```

2. 安装依赖：
   ```bash
   flutter pub get
   ```

3. 运行应用：
   ```bash
   flutter run
   ```

## 构建和部署

### Android

```bash
# 构建APK
flutter build apk

# 构建App Bundle
flutter build appbundle
```

### iOS

```bash
# 构建iOS应用
flutter build ios
```

### Web

```bash
# 构建Web应用
flutter build web
```

## 测试

```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/path/to/test.dart
```

## 国际化

应用支持多语言，翻译文件位于 `lib/l10n` 目录。要添加新语言，请在该目录中创建新的 `.arb` 文件，并运行：

```bash
flutter gen-l10n
```

## 贡献

请参阅项目根目录的 [CONTRIBUTING.md](../CONTRIBUTING.md) 文件。

## 许可证

本项目采用 MIT 许可证 - 详情请参阅项目根目录的 [LICENSE](../LICENSE) 文件。