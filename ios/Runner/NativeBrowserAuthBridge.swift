import AuthenticationServices
import Flutter
import UIKit

final class NativeBrowserAuthBridge: NSObject, ASWebAuthenticationPresentationContextProviding {
  static let shared = NativeBrowserAuthBridge()

  private var session: ASWebAuthenticationSession?
  private weak var presentationWindow: UIWindow?

  private override init() {
    super.init()
  }

  func configure(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.publicai.app/native_browser_auth",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "Native auth bridge unavailable", details: nil))
        return
      }

      switch call.method {
      case "authenticate":
        self.authenticate(call: call, result: result)
      case "consumePendingCallback":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func authenticate(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard session == nil else {
      result(FlutterError(code: "AUTH_IN_PROGRESS", message: "Native auth is already in progress", details: nil))
      return
    }

    guard let args = call.arguments as? [String: Any],
          let urlString = args["url"] as? String,
          let callbackScheme = args["callbackScheme"] as? String,
          let url = URL(string: urlString) else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid native auth arguments", details: nil))
      return
    }

    guard let anchor = resolvePresentationAnchor() else {
      result(FlutterError(code: "NO_PRESENTATION_ANCHOR", message: "No active window for native auth", details: nil))
      return
    }
    presentationWindow = anchor

    let authSession = ASWebAuthenticationSession(
      url: url,
      callbackURLScheme: callbackScheme
    ) { [weak self] callbackUrl, error in
      guard let self = self else { return }
      self.session = nil
      self.presentationWindow = nil

      if let error = error as? ASWebAuthenticationSessionError {
        switch error.code {
        case .canceledLogin:
          result(FlutterError(code: "CANCELED", message: "User canceled native auth", details: nil))
        default:
          result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
        }
        return
      }

      if let error = error {
        result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
        return
      }

      guard let callbackUrl = callbackUrl else {
        result(FlutterError(code: "NO_CALLBACK", message: "Native auth completed without a callback", details: nil))
        return
      }

      result(callbackUrl.absoluteString)
    }

    authSession.presentationContextProvider = self
    authSession.prefersEphemeralWebBrowserSession = false
    session = authSession

    if !authSession.start() {
      session = nil
      presentationWindow = nil
      result(FlutterError(code: "START_FAILED", message: "Failed to start native auth session", details: nil))
    }
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    presentationWindow ?? resolvePresentationAnchor() ?? ASPresentationAnchor()
  }

  private func resolvePresentationAnchor() -> UIWindow? {
    let foregroundScenes = UIApplication.shared.connectedScenes.compactMap { scene in
      scene as? UIWindowScene
    }.filter { scene in
      scene.activationState == .foregroundActive || scene.activationState == .foregroundInactive
    }

    for scene in foregroundScenes {
      if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
        return keyWindow
      }
    }

    for scene in foregroundScenes {
      if let visibleWindow = scene.windows.first(where: { !$0.isHidden && $0.alpha > 0 }) {
        return visibleWindow
      }
    }

    return nil
  }
}
