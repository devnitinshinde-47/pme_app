/// Represents a meeting participant.
class Participant {
  final String id;
  final String displayName;
  final bool isMuted;
  final bool isVideoOn;
  final bool isHost;
  final bool isScreenSharing;

  const Participant({
    required this.id,
    required this.displayName,
    required this.isMuted,
    required this.isVideoOn,
    required this.isHost,
    required this.isScreenSharing,
  });

  factory Participant.fromMap(Map<dynamic, dynamic> map) {
    return Participant(
      id: map['id']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? 'Participant',
      isMuted: map['isMuted'] == true,
      isVideoOn: map['isVideoOn'] == true,
      isHost: map['isHost'] == true,
      isScreenSharing: map['isScreenSharing'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'isMuted': isMuted,
        'isVideoOn': isVideoOn,
        'isHost': isHost,
        'isScreenSharing': isScreenSharing,
      };

  @override
  String toString() =>
      'Participant(id: $id, name: $displayName, muted: $isMuted, videoOn: $isVideoOn, host: $isHost)';
}
