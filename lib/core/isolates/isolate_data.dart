import 'package:flutter/services.dart';

class IsolateData<T> {
  final RootIsolateToken token;
  final T data;

  IsolateData(this.data) : token = ServicesBinding.rootIsolateToken!;
}
