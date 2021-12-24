import 'package:encrypt/encrypt.dart';

class Encryption {
  final key = Key.fromLength(32);
  final iv = IV.fromLength(16);

  Encrypted encrypt(plainText){
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    print(encrypted.base64);
    return encrypted;
  }

  decrypt(encryptedText){
    final encrypter = Encrypter(AES(key));
    final decrypted = encrypter.decrypt(Encrypted.fromBase64(encryptedText), iv: iv);
    return decrypted;
  }


}