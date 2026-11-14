class Job {
  final int id;
  final String companyName;
  final String title;
  final String description;
  final String location;
  final String contract;
  final String? salary;
  final String createdAt;
  final int applicationsCount;

  const Job({
    required this.id,
    required this.companyName,
    required this.title,
    required this.description,
    required this.location,
    required this.contract,
    required this.salary,
    required this.createdAt,
    this.applicationsCount = 0,
  });

  factory Job.fromJson(Map<String, dynamic> j) => Job(
    id: j['id'] as int,
    companyName: (j['companyName'] as String?) ?? '',
    title: (j['title'] as String?) ?? '',
    description: (j['description'] as String?) ?? '',
    location: (j['location'] as String?) ?? '',
    contract: (j['contract'] as String?) ?? '',
    salary: j['salary'] as String?,
    createdAt: (j['createdAt'] as String?) ?? '',
    applicationsCount: (j['applicationsCount'] as num?)?.toInt() ?? 0,
  );
}
