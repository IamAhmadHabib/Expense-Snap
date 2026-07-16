enum PermissionTarget { microphone, camera, photos, notifications }

enum PermissionStatus { notDetermined, granted, denied, permanentlyDenied }

class PermissionSnapshot {
  final PermissionTarget target;
  final PermissionStatus status;

  const PermissionSnapshot({required this.target, required this.status});

  bool get isGranted => status == PermissionStatus.granted;

  @override
  bool operator ==(Object other) {
    return other is PermissionSnapshot &&
        other.target == target &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(target, status);
}
