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

  bool _obscureNovaSenha = true;
  double _scaleAlterarSenha = 1.0;
  int _passwordStrength = 0;
  String _strengthLabel = '';

  // Função para calcular a força da senha
  int evaluatePasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    return strength;
  }

  void _updatePasswordStrength(String password) {
    setState(() {
      _passwordStrength = evaluatePasswordStrength(password);
      switch (_passwordStrength) {
        case 1:
        case 2:
          _strengthLabel = 'Fraca';
          break;
        case 3:
          _strengthLabel = 'Moderada';
          break;
        case 4:
        case 5:
          _strengthLabel = 'Forte';
          break;
        default:
          _strengthLabel = 'Muito fraca';
      }
    });
  }

  // Exibe Snackbar para feedback
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF222222), // Fundo preto
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Função para hashear a senha
  String hashPassword(String plainPassword) {
    return BCrypt.hashpw(plainPassword, BCrypt.gensalt());
  }

  Future<void> _alterarSenha() async {
    final email = _emailController.text.trim();
    final novaSenha = _novaSenhaController.text.trim();
    final confirmarSenha = _confirmarSenhaController.text.trim();

    if (email.isEmpty || novaSenha.isEmpty || confirmarSenha.isEmpty) {
      _showSnackbar('Por favor, preencha todos os campos.');
      return;
    }

    if (novaSenha != confirmarSenha) {
      _showSnackbar('As senhas não coincidem.');
      return;
    }

    if (_passwordStrength < 3) {
      _showSnackbar('A senha deve ser pelo menos moderada.');
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
        _showSnackbar('Senha alterada com sucesso!');
        _emailController.clear();
        _novaSenhaController.clear();
        _confirmarSenhaController.clear();
      } else {
        _showSnackbar('Email não encontrado.');
      }

      await conn.close();
    } catch (e) {
      _showSnackbar('Erro ao conectar ao banco de dados.');
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
              obscureText: _obscureNovaSenha,
              onChanged: _updatePasswordStrength,
              style: GoogleFonts.inter(
                  fontSize: 16, color: const Color(0xFF222222)),
              decoration: InputDecoration(
                labelText: 'Nova Senha',
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureNovaSenha = !_obscureNovaSenha;
                    });
                  },
                  child: Icon(
                    _obscureNovaSenha ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
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
            const SizedBox(height: 8),

            // Indicador de força da senha
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _passwordStrength / 5,
                    backgroundColor: Colors.grey[300],
                    color: _passwordStrength < 3
                        ? Colors.red
                        : (_passwordStrength == 3
                            ? Colors.orange
                            : Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _strengthLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _passwordStrength < 3
                        ? Colors.red
                        : (_passwordStrength == 3
                            ? Colors.orange
                            : Colors.green),
                  ),
                ),
              ],
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
              child: Text(
                'Voltar para login',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
