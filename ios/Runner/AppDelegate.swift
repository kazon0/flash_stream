import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var exportResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "flash_stream/file_export",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "exportFile" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard
          let args = call.arguments as? [String: String],
          let path = args["path"],
          let fileName = args["fileName"]
        else {
          result(FlutterError(code: "bad_args", message: "Missing export path or file name", details: nil))
          return
        }
        self.exportFile(path: path, fileName: fileName, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func exportFile(path: String, fileName: String, result: @escaping FlutterResult) {
    let source = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: source.path) else {
      result(FlutterError(code: "export_failed", message: "Source file does not exist: \(path)", details: nil))
      return
    }

    if exportResult != nil {
      result(FlutterError(code: "export_busy", message: "Another export is already in progress", details: nil))
      return
    }

    exportResult = result
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(forExporting: [source], asCopy: true)
    } else {
      picker = UIDocumentPickerViewController(url: source, in: .exportToService)
    }
    picker.delegate = self
    picker.shouldShowFileExtensions = true
    window?.rootViewController?.present(picker, animated: true)
  }
}

extension AppDelegate: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    exportResult?(urls.first?.path)
    exportResult = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    exportResult?(nil)
    exportResult = nil
  }
}
