import 'package:uuid/uuid.dart';

class UuidUtil {
  UuidUtil._();

  static String generateUUID() {
    return const Uuid().v1();
  }

  static String generateUUIDWithoutHypen() {
    return const Uuid().v1().replaceAll('-', '');
  }
}
