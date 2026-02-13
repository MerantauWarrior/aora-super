package com.aora.passkey

import androidx.credentials.CreateCredentialResponse
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.GetCredentialException
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.aora.passkey/auth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "createPasskey" -> createPasskey(call, result)
                    "getPasskey" -> getPasskey(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun createPasskey(call: MethodCall, result: MethodChannel.Result) {
        val requestJson = call.argument<String>("publicKey")
        if (requestJson == null) {
            result.error("MISSING_REQUEST", "publicKey options are required", null)
            return
        }

        val credentialManager = CredentialManager.create(this)
        val request = CreatePublicKeyCredentialRequest(requestJson)

        credentialManager.createCredentialAsync(
            this,
            request,
            null,
            mainExecutor,
            object : CredentialManagerCallback<CreateCredentialResponse, CreateCredentialException> {
                override fun onResult(resultData: CreateCredentialResponse) {
                    result.success(resultData.data)
                }

                override fun onError(e: CreateCredentialException) {
                    result.error("CREATE_PASSKEY_FAILED", e.message, null)
                }
            }
        )
    }

    private fun getPasskey(call: MethodCall, result: MethodChannel.Result) {
        val requestJson = call.argument<String>("publicKey")
        if (requestJson == null) {
            result.error("MISSING_REQUEST", "publicKey options are required", null)
            return
        }

        val credentialManager = CredentialManager.create(this)
        val option = GetPublicKeyCredentialOption(requestJson)
        val request = GetCredentialRequest(listOf(option))

        credentialManager.getCredentialAsync(
            this,
            request,
            null,
            mainExecutor,
            object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                override fun onResult(resultData: GetCredentialResponse) {
                    result.success(resultData.credential.data)
                }

                override fun onError(e: GetCredentialException) {
                    result.error("GET_PASSKEY_FAILED", e.message, null)
                }
            }
        )
    }
}
