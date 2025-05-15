abstract class NeoAnalyticEvent {}

sealed class NeoCoreAnalyticEvent extends NeoAnalyticEvent {}

class NeoAnalyticEventStartScreenTracking extends NeoCoreAnalyticEvent {
  final String label;
  final String viewClass;
  final Map<String, dynamic> attributes;

  NeoAnalyticEventStartScreenTracking({
    required this.label,
    required this.viewClass,
    required this.attributes,
  });
}

class NeoAnalyticEventStopScreenTracking extends NeoCoreAnalyticEvent {
  final String label;

  NeoAnalyticEventStopScreenTracking({required this.label});
}

class NeoAnalyticEventCustomEvent extends NeoCoreAnalyticEvent {
  final String eventName;
  final Map<String, dynamic> attributes;

  NeoAnalyticEventCustomEvent({
    required this.eventName,
    this.attributes = const {},
  });
}

class NeoAnalyticEventNetworkError extends NeoCoreAnalyticEvent {
  final String? requestId;
  final String? errorCode;
  final String? errorType;
  final String? title;
  final String? description;

  NeoAnalyticEventNetworkError({
    this.requestId,
    this.errorCode,
    this.errorType,
    this.title,
    this.description,
  });
}
