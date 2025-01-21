import 'dart:io';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:logger/logger.dart';

void main() async {
  // Configuração do Logger
  final logger = Logger();

  // Carregando variáveis de ambiente do sistema
  final dbHost = Platform.environment['DB_HOST'] ?? 'localhost';
  final dbPort =
      int.tryParse(Platform.environment['DB_PORT'] ?? '3306') ?? 3306;
  final dbUser = Platform.environment['DB_USER'] ?? 'root';
  final dbPassword = Platform.environment['DB_PASSWORD'] ?? '';
  final dbName = Platform.environment['DB_NAME'] ?? 'default_db';
  final serverPort =
      int.tryParse(Platform.environment['SERVER_PORT'] ?? '8080') ?? 8080;

  // Configurações do MySQL
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
    exit(1); // Encerra o programa com erro
  }

  // Handler do servidor
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler((Request request) {
    return Response.ok('Servidor está rodando!');
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
