# AI漫剧生成器

基于 Flutter + Material 3 构建的 AI 漫剧生成应用，支持多协议 AI 模型配置、流式对话、自动分镜识别、视频生成与合并。

## 功能特性

- **多协议 AI 模型配置**：支持 OpenAI 兼容、自定义 HTTP、Anthropic Claude、Google Gemini 等协议，语言/视频/图片模型分别配置，支持自定义请求头
- **流式对话输出**：SSE 流式输出，逐段累加对话，非一次性输出
- **自动分镜识别**：自动识别 `<镜头1></镜头1>` 标签，提示词中告知 AI 使用该格式
- **思考模型支持**：识别 `<think></think>` 标签，默认折叠，思考内容不进入后续提示词
- **上下文窗口**：最高支持 265 万 Token，可配置（4096~2650000）
- **视频生成**：语言模型可调用视频模型生成视频，支持 10 种预设风格、5 种固定比例
- **视频管理**：预览、放大查看、保存到相册/文件、多镜头合并保存
- **进度显示**：右上角进度条实时显示生成进度
- **Markdown 渲染**：全套 Markdown 渲染支持
- **Material 3 主题**：Material You 设计，深浅色双主题

## 技术栈

- Flutter 3.44.9 / Dart 3.5.0
- Material 3 (Material You)
- Provider 状态管理
- http + SSE 流式解析
- flutter_markdown Markdown 渲染
- video_player + chewie 视频播放
- ffmpeg_kit_flutter 视频合并
- shared_preferences 本地存储
- image_gallery_saver 保存到相册

## 构建

### 环境要求

- Flutter 3.44.9+
- Android SDK (API 24+)
- Java 17

### 本地构建

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

### GitHub Actions 云端构建

推送代码到 `main` 分支自动触发构建，产物为 arm64-v8a 架构的 release APK。

## 开源协议

GPL-3.0
