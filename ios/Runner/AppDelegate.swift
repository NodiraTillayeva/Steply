import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let CHANNEL = "com.example.steply/share"
  private static let APP_GROUP = "group.com.example.steplynara.shared"
  private static let SHARED_KEY = "ShareKey"
  private var pendingSharedURL: String?
  private var shareChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    shareChannel = FlutterMethodChannel(
      name: AppDelegate.CHANNEL,
      binaryMessenger: controller.binaryMessenger
    )

    shareChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { result(nil); return }

      if call.method == "getSharedURL" {
        // First check if URL was passed via URL scheme
        if let url = self.pendingSharedURL {
          self.pendingSharedURL = nil
          print("📱 [Share] Returning URL from URL scheme: \(url)")
          result(url)
          return
        }

        // Fallback: check App Group UserDefaults
        if let userDefaults = UserDefaults(suiteName: AppDelegate.APP_GROUP) {
          if let url = userDefaults.string(forKey: AppDelegate.SHARED_KEY) {
            userDefaults.removeObject(forKey: AppDelegate.SHARED_KEY)
            userDefaults.synchronize()
            print("📱 [Share] Returning URL from App Group: \(url)")
            result(url)
            return
          }
        }

        result(nil)
      } else if call.method == "debugShareSetup" {
        // Debug method to verify App Group works
        let canAccessAppGroup = UserDefaults(suiteName: AppDelegate.APP_GROUP) != nil
        print("📱 [Share] App Group accessible: \(canAccessAppGroup)")
        result(canAccessAppGroup)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("📱 [Share] Received URL scheme: \(url.absoluteString)")
    if url.scheme == "steply" && url.host == "share" {
      if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
         let urlParam = components.queryItems?.first(where: { $0.name == "url" })?.value {
        pendingSharedURL = urlParam
        print("📱 [Share] Extracted shared URL: \(urlParam)")
      }
    }
    return super.application(app, open: url, options: options)
  }
}
