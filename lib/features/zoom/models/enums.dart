/// Represents the current state of a Zoom meeting.
enum MeetingState {
  idle,
  connecting,
  inMeeting,
  reconnecting,
  disconnecting,
  ended,
  error,
}

/// Maps a string value from the native layer to a [MeetingState].
MeetingState meetingStateFromString(String? value) {
  switch (value) {
    case 'idle':
      return MeetingState.idle;
    case 'connecting':
      return MeetingState.connecting;
    case 'inMeeting':
      return MeetingState.inMeeting;
    case 'reconnecting':
      return MeetingState.reconnecting;
    case 'disconnecting':
      return MeetingState.disconnecting;
    case 'ended':
      return MeetingState.ended;
    case 'error':
      return MeetingState.error;
    default:
      return MeetingState.idle;
  }
}

/// All possible Zoom meeting event types dispatched from the native layer.
enum ZoomEventType {
  meetingJoined,
  meetingLeft,
  participantJoined,
  participantLeft,
  participantMuted,
  participantUnmuted,
  participantVideoStatusChanged,
  participantUpdated,
  screenShareStarted,
  screenShareStopped,
  connectionLost,
  connectionRestored,
  hostChanged,
  meetingEnded,
  meetingStateChanged,
  unknown,
}

/// Maps a raw event type string from the native layer to a [ZoomEventType].
ZoomEventType zoomEventTypeFromString(String? value) {
  switch (value) {
    case 'meetingJoined':
      return ZoomEventType.meetingJoined;
    case 'meetingLeft':
      return ZoomEventType.meetingLeft;
    case 'participantJoined':
      return ZoomEventType.participantJoined;
    case 'participantLeft':
      return ZoomEventType.participantLeft;
    case 'participantMuted':
      return ZoomEventType.participantMuted;
    case 'participantUnmuted':
      return ZoomEventType.participantUnmuted;
    case 'participantVideoStatusChanged':
      return ZoomEventType.participantVideoStatusChanged;
    case 'participantUpdated':
      return ZoomEventType.participantUpdated;
    case 'screenShareStarted':
      return ZoomEventType.screenShareStarted;
    case 'screenShareStopped':
      return ZoomEventType.screenShareStopped;
    case 'connectionLost':
      return ZoomEventType.connectionLost;
    case 'connectionRestored':
      return ZoomEventType.connectionRestored;
    case 'hostChanged':
      return ZoomEventType.hostChanged;
    case 'meetingEnded':
      return ZoomEventType.meetingEnded;
    case 'meetingStateChanged':
      return ZoomEventType.meetingStateChanged;
    default:
      return ZoomEventType.unknown;
  }
}

/// A structured event dispatched from the native Zoom SDK via [EventChannel].
class ZoomMeetingEvent {
  final ZoomEventType type;
  final Map<String, dynamic> data;

  const ZoomMeetingEvent({required this.type, required this.data});

  factory ZoomMeetingEvent.fromMap(Map<dynamic, dynamic> map) {
    return ZoomMeetingEvent(
      type: zoomEventTypeFromString(map['event']?.toString()),
      data: Map<String, dynamic>.from(map)..remove('event'),
    );
  }

  @override
  String toString() => 'ZoomMeetingEvent(type: $type, data: $data)';
}
