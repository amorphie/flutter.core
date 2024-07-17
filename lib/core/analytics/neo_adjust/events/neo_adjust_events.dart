enum NeoAdjustEvent {
  // STOPSHIP: Update event id from Adjust panel when event created
  loginSuccess("loginSuccess");

  const NeoAdjustEvent(this.id);
  final String id;
}
