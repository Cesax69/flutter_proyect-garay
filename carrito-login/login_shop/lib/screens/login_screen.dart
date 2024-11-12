import 'package:flutter/material.dart';
import 'package:login_shop/helpers/email_service.dart';
import '../helpers/db_helper.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';
import 'admin_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../helpers/encryption_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.blue.shade800],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _userOrEmailController,
                      decoration: InputDecoration(
                        hintText: 'Usuario o Email',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su usuario o email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '¿No tienes cuenta? Regístrate',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userInput = _userOrEmailController.text;
        final password = _passwordController.text;

        // Manejo especial para el admin
        if ((userInput == 'admin' || userInput == 'admin@admin.com') && password == 'admin') {
          final user = await DatabaseHelper().getAdminUser();
          
          if (!mounted) return;

          if (user != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminScreen(),
              ),
            );
            return;
          }
        }

        // Para usuarios normales, usar contraseña hasheada
        final hashedPassword = encryptPassword(password);
        final user = await DatabaseHelper().loginUser(userInput, hashedPassword);

        if (!mounted) return;

        if (user != null && user['id'] != null) {
          final userId = user['id'] as int;
          final username = user['username'] as String;
          final role = user['role'] as int;
          final email = user['email'] as String;

          try {
            await EmailService.sendLoginNotification(email);
          } catch (emailError) {
            print('Error al enviar el correo: $emailError');
          }

          if (role == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminScreen(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => WelcomeScreen(
                  username: username,
                  userId: userId,
                ),
              ),
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: "Credenciales inválidas",
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error al iniciar sesión",
          backgroundColor: Colors.red,
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _userOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}