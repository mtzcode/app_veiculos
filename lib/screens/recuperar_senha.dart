import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bcrypt/bcrypt.dart';
import '../db_connection.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  String _message = '';
  bool _isHoveredVoltar = false;
  double _scaleAlterarSenha = 1.0;

  // Função para hashear a senha
  String hashPassword(String plainPassword) {
    return BCrypt.hashpw(plainPassword, BCrypt.gensalt());
  }

  Future<void> _alterarSenha() async {
    final email = _emailController.text.trim();
    final novaSenha = _novaSenhaController.text.trim();
    final confirmarSenha = _confirmarSenhaController.text.trim();

    if (email.isEmpty || novaSenha.isEmpty || confirmarSenha.isEmpty) {
      setState(() {
        _message = 'Por favor, preencha todos os campos.';
      });
      return;
    }

    if (novaSenha != confirmarSenha) {
      setState(() {
        _message = 'As senhas não coincidem.';
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
        // Hashear a nova senha antes de salvar
        final hashedPassword = hashPassword(novaSenha);

        await conn.query(
          'UPDATE usuarios SET senha = ? WHERE email = ?',
          [hashedPassword, email],
        );
        setState(() {
          _message = 'Senha alterada com sucesso!';
        });
        _emailController.clear();
        _novaSenhaController.clear();
        _confirmarSenhaController.clear();
      } else {
        setState(() {
          _message = 'Email não encontrado.';
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
              'Recuperar Senha',
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campo Nova Senha
            TextField(
              controller: _novaSenhaController,
              obscureText: true,
              style: GoogleFonts.inter(
                  fontSize: 16, color: const Color(0xFF222222)),
              decoration: InputDecoration(
                labelText: 'Nova Senha',
                labelStyle: GoogleFonts.inter(
                    fontSize: 16, color: const Color(0xFF333333)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDCDDE2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campo Confirmar Senha
            TextField(
              controller: _confirmarSenhaController,
              obscureText: true,
              style: GoogleFonts.inter(
                  fontSize: 16, color: const Color(0xFF222222)),
              decoration: InputDecoration(
                labelText: 'Confirmar Senha',
                labelStyle: GoogleFonts.inter(
                    fontSize: 16, color: const Color(0xFF333333)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDCDDE2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _alterarSenha,
              onTapDown: (_) => setState(() => _scaleAlterarSenha = 0.9),
              onTapUp: (_) => setState(() => _scaleAlterarSenha = 1.0),
              child: AnimatedScale(
                scale: _scaleAlterarSenha,
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
                      'Alterar Senha',
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
              onHover: (hover) {
                setState(() {
                  _isHoveredVoltar = hover;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Voltar para login',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 2,
                    width: _isHoveredVoltar ? 150 : 0,
                    color: const Color(0xFFFF2964),
                  ),
                ],
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
