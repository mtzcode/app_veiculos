import 'package:mysql1/mysql1.dart';

class DBConnection {
  static Future<MySqlConnection> getConnection() async {
    final settings = ConnectionSettings(
      host: '192.168.15.7', // Altere para o endereço do seu servidor MySQL
      port: 3306, // Porta padrão do MySQL
      user: 'mtzcode', // Usuário do banco
      password: 'srv123', // Senha do banco
      db: 'app_veiculos', // Nome do banco criado
    );
    return await MySqlConnection.connect(settings);
  }
}
