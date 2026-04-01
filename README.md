# App Agent

一个使用 Flutter 从 0 到 1 搭建的 Agent App Demo，交互形态参考豆包，当前支持 iOS 与 Android 双端运行。

## 已实现

- 会话列表 + 会话详情双栏布局
- 移动端单栏跳转，桌面/平板双栏展示
- iOS / Android 双端工程
- 流式输出，回复会逐段渲染
- 文本消息
- Markdown 消息，支持标题、列表、表格
- 富文本消息
- 图表消息，支持折线图、柱状图、饼图
- 块级内容混排：代码块、引用、LaTeX、Mermaid
- 图片、图库、文件卡片、网页卡片
- 音频/视频卡片、任务结果卡片
- 本地图片/文件选择并作为消息发送
- 本地图片预览
- 输入框与本地 mock AI 回复
- iOS `MethodChannel` 示例

## 技术栈

- Flutter
- `flutter_markdown`
- `fl_chart`
- `file_picker`
- `google_fonts`
- `intl`

## 多平台模型接入

当前已接入三家平台，并支持在 App 内切换模型：

- OpenAI
- DeepSeek
- 豆包 / 火山方舟
- Custom（自定义 OpenAI-compatible 提供方）
- System AI（系统原生 AI）

启动时通过 `dart-define` 传入配置。
这些值只作为首次默认值，后续可直接在 App 内设置页修改并本地保存。

### OpenAI

```bash
--dart-define=OPENAI_API_KEY=sk-xxx \
--dart-define=OPENAI_MODELS=gpt-5.2,gpt-5-mini \
--dart-define=OPENAI_BASE_URL=https://api.openai.com/v1
```

### DeepSeek

```bash
--dart-define=DEEPSEEK_API_KEY=sk-xxx \
--dart-define=DEEPSEEK_MODELS=deepseek-chat,deepseek-reasoner \
--dart-define=DEEPSEEK_BASE_URL=https://api.deepseek.com
```

### 豆包 / 火山方舟

```bash
--dart-define=DOUBAO_API_KEY=your_ark_key \
--dart-define=DOUBAO_MODELS=doubao-seed-1-6-251015 \
--dart-define=DOUBAO_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
```

也兼容：

```bash
--dart-define=ARK_API_KEY=your_ark_key
```

### Custom

```bash
--dart-define=CUSTOM_API_KEY=sk-xxx \
--dart-define=CUSTOM_BASE_URL=https://your-openai-compatible-gateway/v1 \
--dart-define=CUSTOM_MODELS=your-model-id
```

### System AI

`System AI` 不需要 API Key。

- iOS：优先调用系统原生 Foundation Models
- Android：已接入 ML Kit GenAI Prompt API，依赖 AICore / Gemini Nano；支持设备上会直接走系统侧 on-device AI

## 本地运行

```bash
fvm flutter pub get
fvm flutter run \
  --dart-define=OPENAI_API_KEY=sk-xxx \
  --dart-define=DEEPSEEK_API_KEY=sk-xxx \
  --dart-define=DOUBAO_API_KEY=your_ark_key
```

如果只跑 iOS 模拟器：

```bash
fvm flutter run -d ios
```

如果跑 Android 设备或模拟器：

```bash
fvm flutter run -d android
```

注意：
启用 Android `System AI` 后，Android 端最低版本要求为 API 26。

## 目录结构

```text
lib/
  app/
  core/
  features/chat/
  services/
ios/
  Runner/AppDelegate.swift
android/
  app/src/main/kotlin/com/example/app_agent/MainActivity.kt
```

## 下一步建议

- 增加本地持久化，保存会话记录与附件元数据
- 为附件接入真实上传链路与服务端解析
- 增加音视频播放、Mermaid/LaTeX 真渲染
- 引入真正的 Agent 工具编排能力
