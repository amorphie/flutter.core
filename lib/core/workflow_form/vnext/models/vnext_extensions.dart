/// vNext workflow extensions model
/// Contains the view and data endpoints from vNext workflow responses
class VNextExtensions {
  final VNextViewExtension? view;
  final VNextDataExtension? data;
  final String? currentState;
  final String? status;
  final List<String> transitions;
  final List<dynamic> activeCorrelations;

  const VNextExtensions({
    this.view,
    this.data,
    this.currentState,
    this.status,
    this.transitions = const [],
    this.activeCorrelations = const [],
  });

  factory VNextExtensions.fromJson(Map<String, dynamic> json) {
    return VNextExtensions(
      view: json['view'] != null 
          ? VNextViewExtension.fromJson(json['view'] as Map<String, dynamic>)
          : null,
      data: json['data'] != null
          ? VNextDataExtension.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      currentState: json['currentState'] as String?,
      status: json['status'] as String?,
      transitions: (json['transitions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      activeCorrelations: json['activeCorrelations'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'view': view?.toJson(),
      'data': data?.toJson(),
      'currentState': currentState,
      'status': status,
      'transitions': transitions,
      'activeCorrelations': activeCorrelations,
    };
  }

  /// Check if this extensions object has valid view endpoint
  bool get hasViewEndpoint => view?.href != null && view!.href.isNotEmpty;

  /// Check if this extensions object has valid data endpoint
  bool get hasDataEndpoint => data?.href != null && data!.href.isNotEmpty;

  /// Check if data should be loaded based on view configuration
  bool get shouldLoadData => view?.loadData == true && hasDataEndpoint;
}

/// vNext view extension containing view endpoint information
class VNextViewExtension {
  final String href;
  final bool loadData;

  const VNextViewExtension({
    required this.href,
    this.loadData = false,
  });

  factory VNextViewExtension.fromJson(Map<String, dynamic> json) {
    return VNextViewExtension(
      href: json['href'] as String? ?? '',
      loadData: json['loadData'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'href': href,
      'loadData': loadData,
    };
  }
}

/// vNext data extension containing data endpoint information
class VNextDataExtension {
  final String href;

  const VNextDataExtension({
    required this.href,
  });

  factory VNextDataExtension.fromJson(Map<String, dynamic> json) {
    return VNextDataExtension(
      href: json['href'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'href': href,
    };
  }
}
