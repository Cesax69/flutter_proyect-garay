import 'dart:convert';
import 'package:crypto/crypto.dart';

String encryptPassword(String password) {
  final bytes = utf8.encode(password); // Convierte el password a bytes
  final digest = sha256.convert(bytes); // Aplica SHA-256
  return digest.toString(); // Devuelve el hash como string
}