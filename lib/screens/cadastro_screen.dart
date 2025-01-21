import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bcrypt/bcrypt.dart'; // Import necessário para bcrypt
import '../db_connection.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmaSenhaController =
      TextEditingController();

  String _message = '';
  double _scaleCadastrar = 1.0;

  // Método para validar email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // Método para validar senha
  bool _isValidPassword(String password) {
    final passwordRegex = RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  // Método para cadastrar o usuário
  Future<void> _cadastrarUsuario() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final confirmaSenha = _confirmaSenhaController.text.trim();

    if (nome.isEmpty ||
        email.isEmpty ||
        senha.isEmpty ||
        confirmaSenha.isEmpty) {
      setState(() {
        _message = 'Por favor, preencha todos os campos.';
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _message = 'Por favor, insira um e-mail válido.';
      });
      return;
    }

    if (!_isValidPassword(senha)) {
      setState(() {
        _message =
            'A senha deve ter pelo menos 8 caracteres e conter letras e números.';
      });
      return;
    }

    if (senha != confirmaSenha) {
      setState(() {
        _message = 'As senhas não coincidem.';
      });
      return;
    }

    try {
      var conn = await DBConnection.getConnection();

      // Gerar hash da senha antes de salvar
      final hashedPassword = BCrypt.hashpw(senha, BCrypt.gensalt());
      var result = await conn.query(
        'INSERT INTO usuarios (nome, email, senha) VALUES (?, ?, ?)',
        [nome, email, hashedPassword],
      );

      if (result.affectedRows == 1) {
        setState(() {
          _message = 'Cadastro realizado com sucesso!';
        });
        _nomeController.clear();
        _emailController.clear();
        _senhaController.clear();
        _confirmaSenhaController.clear();
      } else {
        setState(() {
          _message = 'Erro ao cadastrar usuário.';
        });
      }

      await conn.close();
    } catch (e) {
      setState(() {
        _message = 'Erro ao conectar: $e';
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
              'Crie sua conta',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nomeController,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF222222),
              ),
              decoration: InputDecoration(
                labelText: 'Nome',
                labelStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF333333),
                ),
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
              controller: _emailController,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF222222),
              ),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF333333),
                ),
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
                fontSize: 16,
                color: const Color(0xFF222222),
              ),
              decoration: InputDecoration(
                labelText: 'Senha',
                labelStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF333333),
                ),
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
              controller: _confirmaSenhaController,
              obscureText: true,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF222222),
              ),
              decoration: InputDecoration(
                labelText: 'Confirmar Senha',
                labelStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF333333),
                ),
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
              onTap: _cadastrarUsuario,
              onTapDown: (_) => setState(() => _scaleCadastrar = 0.9),
              onTapUp: (_) => setState(() => _scaleCadastrar = 1.0),
              child: AnimatedScale(
                scale: _scaleCadastrar,
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
                      'Cadastrar',
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
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Text(
                'Voltar para login',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _message.contains('sucesso')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
