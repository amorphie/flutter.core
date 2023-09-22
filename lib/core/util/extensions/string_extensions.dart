extension StringExtensions on String? {
  String get orEmpty => this ?? "";
}
