import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PasskeyApp());
}

class PasskeyApp extends StatelessWidget {
  const PasskeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Passkey Auth',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _channel = MethodChannel('com.aora.passkey/auth');
  static const _apiBase = 'http://10.0.2.2:3000';

  final _usernameController = TextEditingController();
  String _status = 'Ready';
  bool _loading = false;

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() => _loading = true);
    try {
      final optionsRes = await http.post(
        Uri.parse('$_apiBase/register/options'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'username': username}),
      );
      final optionsBody = jsonDecode(optionsRes.body) as Map<String, dynamic>;

      final attestationJson = await _channel.invokeMethod<String>(
        'createPasskey',
        {'publicKey': jsonEncode(optionsBody)},
      );

      final verifyRes = await http.post(
        Uri.parse('$_apiBase/register/verify'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'credential': jsonDecode(attestationJson!),
        }),
      );

      final verified = (jsonDecode(verifyRes.body) as Map<String, dynamic>)['verified'] == true;
      setState(() => _status = verified ? 'Registration successful ✅' : 'Registration failed ❌');
    } catch (e) {
      setState(() => _status = 'Registration error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() => _loading = true);
    try {
      final optionsRes = await http.post(
        Uri.parse('$_apiBase/login/options'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'username': username}),
      );
      final optionsBody = jsonDecode(optionsRes.body) as Map<String, dynamic>;

      final assertionJson = await _channel.invokeMethod<String>(
        'getPasskey',
        {'publicKey': jsonEncode(optionsBody)},
      );

      final verifyRes = await http.post(
        Uri.parse('$_apiBase/login/verify'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'credential': jsonDecode(assertionJson!),
        }),
      );

      final verified = (jsonDecode(verifyRes.body) as Map<String, dynamic>)['verified'] == true;
      setState(() => _status = verified ? 'Login successful ✅' : 'Login failed ❌');
    } catch (e) {
      setState(() => _status = 'Login error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Passkey + FaceID/TouchID')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Username (email preferred)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _register,
              child: const Text('Register Passkey'),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: _loading ? null : _login,
              child: const Text('Login with Passkey'),
            ),
            const SizedBox(height: 20),
            Text(_status),
            const SizedBox(height: 8),
            const Text(
              'Android emulator uses http://10.0.2.2:3000; update for iOS device/simulator as needed.',
            ),
          ],
        ),
      ),
    );
  }
}
