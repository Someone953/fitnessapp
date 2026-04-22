import 'package:flutter/material.dart';
import 'db_helper.dart';

class AuthScreen extends StatefulWidget {
  final Function(int) onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_isLogin) {
      final user = await DbHelper.login(username, password);
      if (user != null) {
        widget.onLoginSuccess(user['id'] as int);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      }
    } else {
      try {
        final id = await DbHelper.register(username, password);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        setState(() {
          _isLogin = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already exists')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isLogin ? 'Login' : 'Register'),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin 
                  ? "Don't have an account? Register" 
                  : "Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
