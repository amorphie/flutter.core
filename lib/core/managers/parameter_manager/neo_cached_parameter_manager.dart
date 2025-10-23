class NeoCachedParameterManager {
  final Map<String, dynamic> _data = {};

  void write(String key, dynamic value) {
    _data[key] = value;
  }

  dynamic read(String key) {
    return _data[key];
  }

  void delete(String key) {
    _data.remove(key);
  }

  void clear() {
    _data.clear();
  }
}
