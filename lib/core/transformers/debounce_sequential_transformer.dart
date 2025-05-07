import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

/// An [EventTransformer] that combines sequential processing with debounce functionality.
///
/// Waits for a [duration] of inactivity before processing an event,
/// effectively filtering out rapid successive events and only processing the last one.
EventTransformer<E> debounceSequencial<E>(Duration duration) {
  return (events, mapper) {
    return sequential<E>().call(events.debounceTime(duration), mapper);
  };
}
