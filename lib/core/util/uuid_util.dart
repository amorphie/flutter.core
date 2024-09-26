import 'package:uuid/uuid.dart';

class UuidUtil {
  UuidUtil._();

  static String generateUUID() {
    return const Uuid().v1();
  }

  static String generateUUIDWithoutHyphen() {
    return const Uuid().v1().replaceAll('-', '');
  }
}
