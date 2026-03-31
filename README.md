# App Agent

一个使用 Flutter 从 0 到 1 搭建的 Agent App Demo，交互形态参考豆包，当前优先支持 iOS。

## 已实现

- 会话列表 + 会话详情双栏布局
- 移动端单栏跳转，桌面/平板双栏展示
- 文本消息
- Markdown 消息，支持标题、列表、表格
- 富文本消息
- 图表消息，支持折线图、柱状图、饼图
- 输入框与本地 mock AI 回复
- iOS `MethodChannel` 示例

## 技术栈

- Flutter
- `flutter_markdown`
- `fl_chart`
- `google_fonts`
- `intl`

## 多平台模型接入

当前已接入三家平台，并支持在 App 内切换模型：

- OpenAI
- DeepSeek
- 豆包 / 火山方舟

启动时通过 `dart-define` 传入配置。

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

## 目录结构

```text
lib/
  app/
  core/
  features/chat/
  services/
ios/
  Runner/AppDelegate.swift
```

## 下一步建议

- 接入流式输出，让回复逐字展示
- 增加消息协议，支持图片、文件、工具调用结果
- 增加本地持久化，保存会话记录
- 引入真正的 Agent 工具编排能力
