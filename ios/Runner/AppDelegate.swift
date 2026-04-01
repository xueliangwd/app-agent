import Flutter
import UIKit
#if canImport(FoundationModels)
import FoundationModels
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "app_agent/native_bridge"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "getPlatformContext":
          let device = UIDevice.current
          result("iOS \(device.systemVersion) · \(device.model)")
        case "generateSystemAIResponse":
          let arguments = call.arguments as? [String: Any]
          let prompt = arguments?["prompt"] as? String ?? ""
          self.handleSystemAI(prompt: prompt, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleSystemAI(prompt: String, result: @escaping FlutterResult) {
#if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      let model = SystemLanguageModel.default
      switch model.availability {
      case .available:
        Task {
          do {
            let session = LanguageModelSession(
              instructions: "You are a concise, helpful native on-device assistant. Reply in the user's language."
            )
            let response = try await session.respond(to: prompt)
            result(response.content)
          } catch {
            result(
              FlutterError(
                code: "system_ai_failed",
                message: "iOS System AI generation failed: \(error.localizedDescription)",
                details: nil
              )
            )
          }
        }
      case .unavailable(let reason):
        result(
          FlutterError(
            code: "system_ai_unavailable",
            message: "Apple Foundation Models unavailable: \(String(describing: reason))",
            details: nil
          )
        )
      }
    } else {
      result(
        FlutterError(
          code: "system_ai_unsupported",
          message: "System AI requires iOS 26 or later and Apple Intelligence-enabled devices.",
          details: nil
        )
      )
    }
#else
    result(
      FlutterError(
        code: "system_ai_unavailable",
        message: "Foundation Models framework is not available in the current iOS toolchain.",
        details: nil
      )
    )
#endif
  }
}
