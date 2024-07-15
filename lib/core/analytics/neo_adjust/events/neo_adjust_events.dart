enum NeoAdjustEvent {
  // STOPSHIP: Update event id from Adjust panel when event created
  neoLoginSuccess("testId");

  const NeoAdjustEvent(this.id);
  final String id;
}
