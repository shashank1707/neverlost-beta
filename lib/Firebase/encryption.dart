import 'package:encrypt/encrypt.dart';

class Encryption {
  final key = Key.fromLength(32);
  final iv = IV.fromLength(16);

  encrypt(plainText){
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  decrypt(encryptedText){
    final encrypter = Encrypter(AES(key));
    final decrypted = encrypter.decrypt(Encrypted.fromBase64(encryptedText), iv: iv);
    return decrypted;
  }


}