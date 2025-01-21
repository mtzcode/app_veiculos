import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bcrypt/bcrypt.dart'; // Import necessário para bcrypt
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

  String _errorMessage = '';

  double _scaleEntrar = 1.0;

  // Método para verificar senha usando bcrypt
  bool verifyPassword(String plainPassword, String hashedPassword) {
    return BCrypt.checkpw(plainPassword, hashedPassword);
  }

  Future<void> _login() async {
    try {
      var conn = await DBConnection.getConnection();
      var results = await conn.query(
        'SELECT senha FROM usuarios WHERE email = ?',
        [_emailController.text],
      );

      if (results.isNotEmpty) {
        final hashedPassword = results.first['senha'] as String;

        // Verifica a senha utilizando o método verifyPassword
        if (verifyPassword(_senhaController.text.trim(), hashedPassword)) {
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
            TextField(
              controller: _senhaController,
              obscureText: true,
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
              ),
            ),
            const SizedBox(height: 20),
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
