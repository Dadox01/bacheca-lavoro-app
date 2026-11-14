class Company {
  final int id;
  final String name;
  final String email;
  final String createdAt;

  const Company({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory Company.fromJson(Map<String, dynamic> j) => Company(
    id: j['id'] as int,
    name: j['name'] as String,
    email: j['email'] as String,
    createdAt: (j['createdAt'] as String?) ?? '',
  );
}
