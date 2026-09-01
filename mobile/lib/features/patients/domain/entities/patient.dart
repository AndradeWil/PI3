class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.phone,
    required this.email,
    required this.address,
    required this.clinicalCondition,
    required this.dailyFrequency,
    required this.companyName,
  });

  final int id;
  final String name;
  final int? age;
  final String phone;
  final String email;
  final String address;
  final String clinicalCondition;
  final int dailyFrequency;
  final String? companyName;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
