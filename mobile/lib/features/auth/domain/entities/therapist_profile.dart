class TherapistProfile {
  const TherapistProfile({
    required this.name,
    required this.username,
    required this.email,
    required this.crefito,
  });

  final String name;
  final String username;
  final String email;
  final String crefito;

  String get displayName => name.trim().isEmpty ? username : name;
}
