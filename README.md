# course_schedule - 校园课程表

一款基于 Flutter 的跨平台校园课程表应用，支持 Windows、Android、iOS 和 Web 平台。

## 功能特性

### 课程表管理
- 添加、编辑、删除课程
- 支持单双周课程显示
- 多颜色主题区分课程
- 支持查看今天的课程
- 周次切换（1-20周）
- 月份和学期选择
- 导入CSV格式课程表

### 天气查询
- 集成和风天气 API
- 实时天气查询
- 未来天气预报
- 湿度、风速、气压等详情
- 支持31个国内城市切换
- 自定义城市输入

### 备忘录功能
- 添加备忘录笔记
- 查看备忘录详情
- 删除备忘录

### 个人设置
- 主题颜色自定义
- 明暗模式切换
- 跟随系统主题
- 字体大小调整
- 字体选择（默认、宋体、黑体、楷体）
- 用户信息设置（昵称、学号、头像）

## 技术栈

- **Flutter** - UI 框架
- **sqflite** - 本地数据库（支持 Windows/Android/iOS）
- **sqflite_common_ffi_web** - Web 端数据存储
- **http** - 网络请求
- **file_picker** - 文件选择
- **path_provider** - 路径管理
- **csv** - CSV 文件解析

## 平台支持

- ✅ Windows
- ✅ Android
- ✅ iOS
- ✅ Web

## 快速开始

### 安装依赖

```bash
flutter pub get
```

### 运行应用

#### Windows

```bash
flutter run -d windows
```

#### Web

```bash
flutter run -d chrome
```

#### Android

```bash
flutter run -d android
```

#### iOS

```bash
flutter run -d ios
```

## 项目结构

```
lib/
├── main.dart           # 主应用入口
├── course.dart         # 课程数据模型
├── database_helper.dart # 数据库辅助类
├── weather_service.dart # 天气服务
├── csv_importer.dart    # CSV 导入功能
├── simple_storage.dart  # Web 端数据存储
└── sqflite_import.dart  # SQLite 导入

```

## CSV 导入格式

CSV 文件格式如下（不包含表头）：

```
课程名称,教室,星期(1-7),节次(1-8),颜色索引(0-7),周次类型(0=每周,1=单周,2=双周)
```

示例：

```
高等数学,教学楼A101,1,1,0,0
大学英语,外语楼202,2,2,1,0
程序设计,计算机楼303,3,3,2,1
```

## 天气 API

本项目使用和风天气免费 API。如需使用真实天气数据，请在 `weather_service.dart` 中配置您的 API Key。

## 许可证

MIT License
