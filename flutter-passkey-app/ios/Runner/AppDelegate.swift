import AuthenticationServices
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var currentResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.aora.passkey/auth",
      binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      self.currentResult = result

      if call.method == "createPasskey" {
        guard
          let args = call.arguments as? [String: Any],
          let json = args["publicKey"] as? String,
          let data = json.data(using: .utf8)
        else {
          result(FlutterError(code: "MISSING_REQUEST", message: "publicKey is required", details: nil))
          return
        }

        do {
          let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: "localhost"
          )
          let registrationRequest = try provider.createCredentialRegistrationRequest(challenge: data, name: "Aora User", userID: Data("user-id".utf8))
          let authController = ASAuthorizationController(authorizationRequests: [registrationRequest])
          authController.delegate = self
          authController.presentationContextProvider = self
          authController.performRequests()
        } catch {
          result(FlutterError(code: "CREATE_PASSKEY_FAILED", message: error.localizedDescription, details: nil))
        }
      } else if call.method == "getPasskey" {
        guard
          let args = call.arguments as? [String: Any],
          let json = args["publicKey"] as? String,
          let data = json.data(using: .utf8)
        else {
          result(FlutterError(code: "MISSING_REQUEST", message: "publicKey is required", details: nil))
          return
        }

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
          relyingPartyIdentifier: "localhost"
        )
        let assertionRequest = provider.createCredentialAssertionRequest(challenge: data)
        let authController = ASAuthorizationController(authorizationRequests: [assertionRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

extension AppDelegate: ASAuthorizationControllerDelegate {
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
      let payload: [String: String] = [
        "id": credential.credentialID.base64EncodedString(),
        "rawId": credential.credentialID.base64EncodedString(),
        "clientDataJSON": credential.rawClientDataJSON.base64EncodedString(),
        "attestationObject": credential.rawAttestationObject?.base64EncodedString() ?? ""
      ]
      currentResult?(String(data: try! JSONSerialization.data(withJSONObject: payload), encoding: .utf8))
      return
    }

    if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
      let payload: [String: String] = [
        "id": credential.credentialID.base64EncodedString(),
        "rawId": credential.credentialID.base64EncodedString(),
        "clientDataJSON": credential.rawClientDataJSON.base64EncodedString(),
        "authenticatorData": credential.rawAuthenticatorData.base64EncodedString(),
        "signature": credential.signature.base64EncodedString(),
        "userHandle": credential.userID.base64EncodedString()
      ]
      currentResult?(String(data: try! JSONSerialization.data(withJSONObject: payload), encoding: .utf8))
      return
    }

    currentResult?(FlutterError(code: "UNEXPECTED_CREDENTIAL", message: "Unsupported credential type", details: nil))
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    currentResult?(FlutterError(code: "PASSKEY_ERROR", message: error.localizedDescription, details: nil))
  }
}

extension AppDelegate: ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return window!
  }
}
