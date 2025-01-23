import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db_connection.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true; // Controle para visibilidade da senha
  double _scaleSave = 1.0;
  int? _userId; // ID do usuário logado

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Carrega o ID do usuário logado do SharedPreferences
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      setState(() {
        _userId = userId;
      });
      await _loadUserData(userId);
    } else {
      _showSnackBar('Erro: Usuário não identificado.', const Color(0xFF222222));
    }
  }

  // Carrega os dados do perfil com base no ID do usuário
  Future<void> _loadUserData(int userId) async {
    try {
      var conn = await DBConnection.getConnection();
      var results = await conn.query(
        'SELECT nome, email FROM usuarios WHERE id = ?',
        [userId],
      );

      if (results.isNotEmpty) {
        setState(() {
          _nameController.text = results.first['nome'] ?? '';
          _emailController.text = results.first['email'] ?? '';
        });
      } else {
        _showSnackBar('Dados do usuário não encontrados.', Colors.orange);
      }

      await conn.close();
    } catch (e) {
      _showSnackBar('Erro ao carregar dados do usuário: $e', Colors.red);
    }
  }

  // Atualiza o perfil do usuário logado
  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_userId == null) {
      _showSnackBar('Usuário não identificado.', Colors.red);
      return;
    }

    if (name.isEmpty || email.isEmpty) {
      _showSnackBar('Por favor, preencha o nome e o e-mail.', Colors.orange);
      return;
    }

    try {
      var conn = await DBConnection.getConnection();

      // Atualiza nome, email e, se informado, a senha
      if (password.isNotEmpty) {
        final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
        await conn.query(
          'UPDATE usuarios SET nome = ?, email = ?, senha = ? WHERE id = ?',
          [name, email, hashedPassword, _userId],
        );
      } else {
        await conn.query(
          'UPDATE usuarios SET nome = ?, email = ? WHERE id = ?',
          [name, email, _userId],
        );
      }

      _showSnackBar('Perfil atualizado com sucesso!', Colors.green);
      await conn.close();
    } catch (e) {
      _showSnackBar('Erro ao atualizar o perfil: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: const Color(0xFF222222), // Fundo #222
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16), // Margem ao redor do Snackbar
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF2964),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar Perfil',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
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
                labelText: 'E-mail',
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
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF222222),
              ),
              decoration: InputDecoration(
                labelText: 'Nova Senha (opcional)',
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
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
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _updateProfile,
              onTapDown: (_) => setState(() => _scaleSave = 0.9),
              onTapUp: (_) => setState(() => _scaleSave = 1.0),
              child: AnimatedScale(
                scale: _scaleSave,
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
                      'Salvar Alterações',
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
          ],
        ),
      ),
    );
  }
}
