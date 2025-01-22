import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';
import '../db_connection.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  String _errorMessage = '';
  double _scaleEntrar = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';
    final savedRememberMe = prefs.getBool('remember_me') ?? false;

    if (savedRememberMe && savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
      _emailController.text = savedEmail;
      _senhaController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });

      // Realiza login automático se lembrar do usuário estiver ativo
      await _autoLogin(savedEmail, savedPassword);
    }
  }

  Future<void> _autoLogin(String email, String password) async {
    try {
      var conn = await DBConnection.getConnection();
      var results = await conn.query(
        'SELECT * FROM usuarios WHERE email = ?',
        [email],
      );

      if (results.isNotEmpty) {
        final hashedPassword = results.first['senha'] as String;

        if (BCrypt.checkpw(password, hashedPassword)) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      }

      await conn.close();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao conectar: $e';
      });
    }
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, preencha todos os campos.';
      });
      return;
    }

    try {
      var conn = await DBConnection.getConnection();
      var results = await conn.query(
        'SELECT * FROM usuarios WHERE email = ?',
        [email],
      );

      if (results.isNotEmpty) {
        final hashedPassword = results.first['senha'] as String;

        if (BCrypt.checkpw(senha, hashedPassword)) {
          await _saveCredentials(email, senha);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Senha incorreta.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Usuário não encontrado.';
        });
      }

      await conn.close();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao conectar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Seja bem-vindo',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 24),

            // Campo de Email
            TextField(
              controller: _emailController,
              style: GoogleFonts.inter(
                  fontSize: 16, color: const Color(0xFF222222)),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: GoogleFonts.inter(
                    fontSize: 16, color: const Color(0xFF333333)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDCDDE2)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campo de Senha
            TextField(
              controller: _senhaController,
              obscureText: !_isPasswordVisible,
              style: GoogleFonts.inter(
                  fontSize: 16, color: const Color(0xFF222222)),
              decoration: InputDecoration(
                labelText: 'Senha',
                labelStyle: GoogleFonts.inter(
                    fontSize: 16, color: const Color(0xFF333333)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDCDDE2)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: const Color(0xFF333333),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Checkbox Lembre-se de Mim
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                Text(
                  'Lembre-se de mim',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF333333)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _login,
              onTapDown: (_) => setState(() => _scaleEntrar = 0.9),
              onTapUp: (_) => setState(() => _scaleEntrar = 1.0),
              child: AnimatedScale(
                scale: _scaleEntrar,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2964), Color(0xFFFF0133)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Entrar',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/cadastro');
                  },
                  child: Text(
                    'Novo por aqui? Cadastre-se',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF333333)),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/recuperar-senha');
                  },
                  child: Text(
                    'Esqueci minha senha',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF333333)),
                  ),
                ),
              ],
            ),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
