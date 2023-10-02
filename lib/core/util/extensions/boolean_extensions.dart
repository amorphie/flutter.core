extension BooleanExtensions on bool? {
  bool get orFalse => this ?? false;
}
