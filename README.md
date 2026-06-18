# KiroTime

KiroTime 是一个本地优先、轻量、开源的跨平台课程表应用。项目目标是把课程表做成一个可靠的日常工具：无广告、无社交、无开发者服务器，课表数据默认只保存在用户设备上。

## 特性

- Flutter 跨平台架构，当前重点支持 Android。
- Riverpod 状态管理，Isar 本地数据库。
- 支持国内高校常见复杂课表：
  - 单双周
  - 跳周
  - 一门课多个上课安排
  - 同一时间段课程冲突
  - 晚自习、周末课程
- 课程元数据和上课安排分离，避免复杂课表互相覆盖。
- 课程卡片支持点击查看详情、编辑、删除、复制到其他学期。
- 冲突课程使用角标标记，点开后可查看冲突列表。
- 多学期管理，课程按学期隔离。
- 每学期可配置开学日期、总周数、每日节数和上课时间。
- 上课时间支持三段式生成、恢复默认、逐节手动编辑。
- WebView 本地导入教务系统页面 HTML，解析过程在本机完成。
- 本地 JSON 导入导出，可导出到 Android `Download/KiroTime`。
- 隐私说明和导出敏感信息提示内置在应用中。

## 隐私

KiroTime 采用本地优先设计：

- 课程、老师、教室、教学班级、周次、学期设置默认只保存在本机 Isar 数据库。
- KiroTime 不提供开发者服务器，不上传用户课表数据。
- 项目不集成广告、社交或统计 SDK。
- 教务系统导入由用户主动打开学校网页，页面内容只在本机 WebView 中读取，并在本机解析。
- Android `INTERNET` 权限仅用于用户主动访问教务系统网页，不用于连接 KiroTime 后端。
- WebView 登录状态默认不长期保留；用户可在高级设置中手动开启。
- JSON 备份文件包含完整课表信息，请用户自行妥善保存和分享。
- 完整 HTML 诊断文件默认关闭，只有用户在高级设置中开启后才会保留。

## 技术栈

- Flutter / Dart
- Riverpod
- Isar
- WebView
- Kotlin / Android platform channel

## 数据模型

课程基础信息和上课安排是一对多关系：

- `CourseMeta`：课程名称、老师、教学班级。
- `CourseSchedule`：地点、星期、节次、周次、所属学期。
- `SemesterSettings`：学期、开学日期、总周数、每日节数、上课时间表。

这种结构可以表达“一门课多个地点/时段”和“同一时间多门课冲突”。

## 本地开发

请先安装 Flutter SDK、Android SDK 和 JDK 21，并确保 `flutter`、`dart` 可在当前 shell 中执行。

安装依赖：

```bash
flutter pub get
```

生成 Isar 代码：

```bash
dart run build_runner build --delete-conflicting-outputs
```

运行检查：

```bash
flutter analyze
flutter test
```

Android debug 构建：

```bash
flutter build apk --debug
```

Android release 构建：

```bash
flutter build apk --release --split-per-abi
```

Release APK 输出目录：

```text
build/app/outputs/flutter-apk/
```

## Release 签名

Release 签名文件不提交到仓库。

本地需要提供：

```text
android/key.properties
android/app/*.jks
```

这些文件已在 `.gitignore` 中忽略。公开仓库不会包含 keystore、密码或本机路径。

## 导入说明

KiroTime 的教务导入不包含后端爬虫。用户在应用内 WebView 打开教务系统页面后，应用读取当前页面 HTML 或可选接口响应，并在本机解析为课程数据。

高级设置中可配置：

- 教务系统网址
- 可选学期 JSON 接口路径
- User-Agent
- 是否保留 WebView 登录状态
- 是否保留完整 HTML 诊断文件

默认不预填任何学校网址或接口路径。

## 当前状态

当前版本：`0.1.3+4`

项目已具备基础日常使用能力，但仍在早期阶段。后续重点：

- 更稳定的多学校导入解析适配。
- 更完善的导入前预览和差异确认。
- WebDAV 加密备份与多端同步。
- Android/iOS 桌面小组件。
- 更正式的发布流程和自动化 CI。

## 许可协议

KiroTime 使用 MIT License 开源。
