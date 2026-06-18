# KiroTime

KiroTime 是一个开源跨平台课程表项目，目标是极致轻量、纯本地化、无后端成本，并能正确表达国内高校复杂课表场景。

当前开发阶段：Phase 2 - 安全模式教务系统 HTML 本地解析。

当前已有功能：

- 7 x 12 课表主网格，支持多节次和冲突重叠课程横向分 lane 展示。
- `currentWeek` 当前周过滤，底层按 `CourseSchedule.weeks` 显式周数组判断。
- Riverpod 状态管理和 Isar 本地存储。
- Mock 课程数据初始化。
- Android WebView 导入入口：用户手动打开教务系统页面后，App 获取整页 HTML 并本地解析。
- 通用 HTML 解析器：支持 `1-16周`、单双周、逗号周、混合区间，并转换为 `CourseMeta` / `CourseSchedule`。
- 课表主界面已支持周切换、日期选择、学期/开学日期/总周数设置、课程详情查看和课程编辑。

## 隐私说明

- 课程、老师、教室、教学班级、周次和学期设置默认只保存在本机 Isar 数据库。
- KiroTime 不提供开发者服务器，不上传用户课表数据，也不集成广告、社交或统计 SDK。
- 教务系统导入由用户主动打开学校网页，页面内容只在本机 WebView 中读取，并在本机解析。
- Android `INTERNET` 权限仅用于用户主动访问教务系统网页，不用于连接 KiroTime 后端。
- JSON 备份会保存到 `Download/KiroTime`，文件包含完整课表信息，请用户自行妥善保存和分享。
- 导入诊断默认只保留摘要；完整 HTML 诊断文件默认关闭，只有用户在高级设置中开启后才会保留。

当前限制：

- 导入当前仍会替换本地课表，尚未提供导入前预览、差异确认和自动备份。
- 学期设置当前是运行期状态，下一步需要接入本地设置持久化，避免重启后重新设置。
- WebView 登录态依赖系统 WebView 自身会话，后续需要补充学校 URL、UA 和导入配置的本地保存。

## 本地开发

请先安装 Flutter SDK、Android SDK 和 JDK 21，并确保 `flutter`、`dart`
可在当前 shell 中执行。

常用验证命令：

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
```

当前仓库提交 Isar 生成文件，模型变更后重新运行 `build_runner`。

Android debug 构建和安装：

```bash
flutter build apk --debug
flutter install --debug
```

当前已补齐 Android 和 Linux runner。运行桌面版：

```bash
flutter run -d linux
```

`isar_flutter_libs 3.1.0+1` 的 Android 插件尚未声明 AGP 9 需要的 namespace，且默认 `compileSdkVersion` 过低。本仓库通过 `dependency_overrides` 指向 `third_party/isar_flutter_libs` 本地补丁包，保持 Android 构建可复现。
