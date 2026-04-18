import AppIntents
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let siriStorageChannelName = "com.convex.fblaConferenceApp/siri_storage"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinishLaunching = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: siriStorageChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler(handleSiriStorageCall)
    }

    if #available(iOS 16.0, *) {
      ConvexConferenceShortcuts.updateAppShortcutParameters()
    }

    return didFinishLaunching
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func handleSiriStorageCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let key = arguments["key"] as? String,
      !key.isEmpty
    else {
      result(
        FlutterError(
          code: "invalid_arguments",
          message: "A non-empty key is required.",
          details: nil
        )
      )
      return
    }

    switch call.method {
    case "getString":
      result(SiriScheduleStore.getString(forKey: key))
    case "setString":
      guard let value = arguments["value"] as? String else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "A string value is required.",
            details: nil
          )
        )
        return
      }
      SiriScheduleStore.setString(value, forKey: key)
      result(nil)
    case "remove":
      SiriScheduleStore.removeValue(forKey: key)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
