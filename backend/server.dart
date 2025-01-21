import 'dart:io';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:logger/logger.dart';
import 'package:bcrypt/bcrypt.dart';

void main() async {
  // Configuração do Logger
  final logger = Logger();

  // Configurações do MySQL
  final dbHost = 'localhost'; // Ajuste conforme sua configuração
  final dbPort = 3306;
  final dbUser = 'root';
  final dbPassword = ''; // Substitua pela sua senha
  final dbName = 'default_db'; // Substitua pelo nome do seu banco
  final serverPort = 8080;

  final connectionSettings = ConnectionSettings(
    host: dbHost,
    port: dbPort,
    user: dbUser,
    password: dbPassword,
    db: dbName,
  );

  // Criando a conexão com o banco de dados
  MySqlConnection? connection;
  try {
    connection = await MySqlConnection.connect(connectionSettings);
    logger.i('Conexão com o banco de dados estabelecida.');
  } catch (e) {
    logger.e('Erro ao conectar com o banco de dados: $e');
    exit(1);
  }

  // Handler do servidor
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler((Request request) async {
    if (request.url.path == 'register' && request.method == 'POST') {
      return await _registerUser(request, connection, logger);
    } else if (request.url.path == 'login' && request.method == 'POST') {
      return await _loginUser(request, connection, logger);
    }
    return Response.notFound('Endpoint não encontrado.');
  });

  // Configuração do servidor
  final ip = InternetAddress.anyIPv4;

  try {
    final server = await shelf_io.serve(handler, ip, serverPort);
    logger
        .i('Servidor rodando em http://${server.address.host}:${server.port}');
  } catch (e) {
    logger.e('Erro ao iniciar o servidor: $e');
  }
}

// Função para hashear senhas
String hashPassword(String plainPassword) {
  return BCrypt.hashpw(plainPassword, BCrypt.gensalt());
}

// Função para verificar senhas
bool verifyPassword(String plainPassword, String hashedPassword) {
  return BCrypt.checkpw(plainPassword, hashedPassword);
}

// Endpoint para registrar um usuário
Future<Response> _registerUser(
    Request request, MySqlConnection? connection, Logger logger) async {
  try {
    final payload = await request.readAsString();
    final data = Uri.splitQueryString(payload);

    final nome = data['nome'];
    final email = data['email'];
    final senha = data['senha'];

    if (nome == null || email == null || senha == null) {
      return Response.badRequest(body: 'Dados inválidos.');
    }

    // Gerando o hash da senha
    final hashedPassword = hashPassword(senha);

    // Inserindo no banco de dados
    final query = 'INSERT INTO usuario (nome, email, senha) VALUES (?, ?, ?)';
    await connection?.query(query, [nome, email, hashedPassword]);

    logger.i('Usuário registrado com sucesso: $nome');
    return Response.ok('Usuário registrado com sucesso.');
  } catch (e) {
    logger.e('Erro ao registrar usuário: $e');
    return Response.internalServerError(body: 'Erro ao registrar usuário.');
  }
}

// Endpoint para login
Future<Response> _loginUser(
    Request request, MySqlConnection? connection, Logger logger) async {
  try {
    final payload = await request.readAsString();
    final data = Uri.splitQueryString(payload);

    final email = data['email'];
    final senha = data['senha'];

    if (email == null || senha == null) {
      return Response.badRequest(body: 'Dados inválidos.');
    }

    // Verificando se o email existe no banco
    final query = 'SELECT senha FROM usuario WHERE email = ?';
    final results = await connection?.query(query, [email]);

    if (results == null || results.isEmpty) {
      return Response.notFound('Usuário não encontrado.');
    }

    final hashedPassword = results.first['senha'] as String;

    // Verificando a senha
    if (verifyPassword(senha, hashedPassword)) {
      logger.i('Login bem-sucedido para o email: $email');
      return Response.ok('Login bem-sucedido.');
    } else {
      return Response.forbidden('Senha incorreta.');
    }
  } catch (e) {
    logger.e('Erro ao fazer login: $e');
    return Response.internalServerError(body: 'Erro ao fazer login.');
  }
}
