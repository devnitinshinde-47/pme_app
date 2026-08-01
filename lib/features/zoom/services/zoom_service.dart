import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/enums.dart';
import '../models/participant.dart';

/// High-level Dart service exposing a clean API for Zoom meeting operations.
///
/// All Zoom SDK details are encapsulated inside the Android Kotlin layer.
/// Flutter never interacts directly with any Zoom SDK classes.
class ZoomService {
  ZoomService._();
  static final ZoomService instance = ZoomService._();

  static const _methodChannel = MethodChannel('com.pme.pawanmateeducation/zoom_method_channel');
  static const _eventChannel = EventChannel('com.pme.pawanmateeducation/zoom_event_channel');

  Stream<ZoomMeetingEvent>? _eventStream;

  /// A broadcast stream of all Zoom meeting lifecycle events from the native layer.
  Stream<ZoomMeetingEvent> get events {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => ZoomMeetingEvent.fromMap(event as Map))
        .asBroadcastStream();
    return _eventStream!;
  }

  /// Initialize the Zoom Meeting SDK.
  ///
  /// Must be called before [joinMeeting]. Safe to call multiple times.
  Future<void> initialize({
    String domain = 'zoom.us',
    String appKey = 'J1ty4gWuQk2jGNYMEVGX1A',
    String appSecret = 'OBEKGm013qquBXKPm3fbahQnlrLGVSPk',
  }) async {
    try {
      await _methodChannel.invokeMethod<Map>('initialize', {
        'domain': domain,
        'appKey': appKey,
        'appSecret': appSecret,
      });
    } on PlatformException {
      rethrow;
    }
  }

  /// Join a Zoom meeting with the given [meetingNumber], [displayName], and [password].
  ///
  /// If the native Zoom SDK is not authenticated, falls back to launching
  /// the Zoom meeting URL in the browser / Zoom app.
  Future<void> joinMeeting({
    required String meetingNumber,
    required String displayName,
    required String password,
    String? meetingUrl,
  }) async {
    try {
      // Step 1: Initialize native Zoom SDK
      await initialize();

      // Step 2: Invoke native join meeting
      await _methodChannel.invokeMethod<Map>('joinMeeting', {
        'meetingNumber': meetingNumber,
        'displayName': displayName,
        'password': password,
      });
    } catch (e) {
      await _launchZoomFallback(
        meetingNumber: meetingNumber,
        displayName: displayName,
        password: password,
        meetingUrl: meetingUrl,
      );
    }
  }

  /// Leave the current Zoom meeting.
  Future<void> leaveMeeting() async {
    try {
      await _methodChannel.invokeMethod('leaveMeeting');
    } on PlatformException {
      // The native SDK reports the operation result.
    }
  }

  /// Mute the local user's microphone.
  Future<void> muteSelf() async {
    try {
      await _methodChannel.invokeMethod('muteSelf');
    } on PlatformException {
      // The native SDK reports the operation result.
    }
  }

  /// Unmute the local user's microphone.
  Future<void> unmuteSelf() async {
    try {
      await _methodChannel.invokeMethod('unmuteSelf');
    } on PlatformException {
      // The native SDK reports the operation result.
    }
  }

  /// Start the local user's video camera.
  Future<void> startVideo() async {
    try {
      await _methodChannel.invokeMethod('startVideo');
    } on PlatformException {
      // The native SDK reports the operation result.
    }
  }

  /// Stop the local user's video camera.
  Future<void> stopVideo() async {
    try {
      await _methodChannel.invokeMethod('stopVideo');
    } on PlatformException {
      // The native SDK reports the operation result.
    }
  }

  /// Start screen sharing.
  Future<void> startScreenShare() async {
    try {
      await _methodChannel.invokeMethod('startScreenShare');
    } on PlatformException {
      // The native SDK reports the operation result.
    }
  }

  /// Stop screen sharing.
  Future<void> stopScreenShare() async {
    try {
      await _methodChannel.invokeMethod('stopScreenShare');
    } on PlatformException {
      // The native SDK reports the operation result.
    }
  }

  /// Returns a list of current meeting [Participant]s.
  Future<List<Participant>> getParticipants() async {
    try {
      final raw = await _methodChannel.invokeMethod<List>('getParticipants');
      if (raw == null) return [];
      return raw.map((e) => Participant.fromMap(e as Map)).toList();
    } on PlatformException {
      return [];
    }
  }

  /// Mute a specific participant by their [participantId].
  Future<void> muteParticipant(String participantId) async {
    try {
      await _methodChannel.invokeMethod('muteParticipant', {'participantId': participantId});
    } on PlatformException {
      // The native SDK reports the operation result.
    }
  }

  /// Unmute a specific participant by their [participantId].
  Future<void> unmuteParticipant(String participantId) async {
    try {
      await _methodChannel.invokeMethod('unmuteParticipant', {'participantId': participantId});
    } on PlatformException {
      // The native SDK reports the operation result.
    }
  }

  /// Returns the current [MeetingState].
  Future<MeetingState> getMeetingState() async {
    try {
      final state = await _methodChannel.invokeMethod<String>('getMeetingState');
      return meetingStateFromString(state);
    } on PlatformException {
      return MeetingState.idle;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _launchZoomFallback({
    required String meetingNumber,
    required String password,
    String? displayName,
    String? meetingUrl,
  }) async {
    final cleanId = meetingNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final nameParam = displayName?.isNotEmpty == true ? Uri.encodeComponent(displayName!) : 'Student';
    final deepLinkStr = 'zoomus://zoom.us/join?confno=$cleanId&pwd=$password&uname=$nameParam';
    final urlStr = meetingUrl?.isNotEmpty == true
        ? meetingUrl!
        : 'https://zoom.us/j/$cleanId?pwd=$password';

    final deepUri = Uri.parse(deepLinkStr);
    if (await canLaunchUrl(deepUri)) {
      await launchUrl(deepUri, mode: LaunchMode.externalApplication);
      return;
    }

    final webUri = Uri.parse(urlStr);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}
