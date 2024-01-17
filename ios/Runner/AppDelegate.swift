import UIKit
import Flutter
import Alamofire
import EnQualify

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

      let prepareSdkMethodChannel = FlutterMethodChannel(name: "com.amorphie.core/common/methods", binaryMessenger: controller.binaryMessenger)
      let startSdkMethodChannel = FlutterMethodChannel(name: "com.amorphie.core/enverify/methods", binaryMessenger: controller.binaryMessenger)

      prepareSdkMethodChannel.setMethodCallHandler({
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          // This method is invoked on the UI thread.
          // Handle battery messages.
          print(call.method)
        })

      startSdkMethodChannel.setMethodCallHandler({
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          // This method is invoked on the UI thread.
          // Handle battery messages.
          print(call.method)
        })

      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /*
     private func receiveBatteryLevel(result: FlutterResult) {
       let device = UIDevice.current
       device.isBatteryMonitoringEnabled = true
       if device.batteryState == UIDevice.BatteryState.unknown {
         result(FlutterError(code: "UNAVAILABLE",
                             message: "Battery level not available.",
                             details: nil))
       } else {
         result(Int(device.batteryLevel * 100))
       }
     }
     */
}
