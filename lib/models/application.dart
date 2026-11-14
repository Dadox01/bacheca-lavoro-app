class Application {
  final int id;
  final int jobId;
  final String jobTitle;
  final String firstName;
  final String lastName;
  final String email;
  final String message;
  final String cvName;
  final int cvSize;
  final String createdAt;

  const Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.message,
    required this.cvName,
    required this.cvSize,
    required this.createdAt,
  });

  factory Application.fromJson(Map<String, dynamic> j) {
    final cv = Map<String, dynamic>.from((j['cv'] as Map?) ?? const {});
    return Application(
      id: j['id'] as int,
      jobId: (j['jobId'] as num).toInt(),
      jobTitle: (j['jobTitle'] as String?) ?? '',
      firstName: (j['firstName'] as String?) ?? '',
      lastName: (j['lastName'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      message: (j['message'] as String?) ?? '',
      cvName: (cv['originalName'] as String?) ?? 'curriculum.pdf',
      cvSize: (cv['size'] as num?)?.toInt() ?? 0,
      createdAt: (j['createdAt'] as String?) ?? '',
    );
  }

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}
