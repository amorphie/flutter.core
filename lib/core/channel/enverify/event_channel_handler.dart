part of env_bridge;

class EventChannelHandler {
  static const platformEvents = EventChannel("com.amorphie.core/enverify/events");

  EventChannelHandler._();

  EventChannelHandler.init() {
    _setupEventChannel();
  }

  _setupEventChannel() {
    platformEvents.receiveBroadcastStream().listen((dynamic data) {
      print("EventChannel: Received data: $data ");
    });
  }
}
