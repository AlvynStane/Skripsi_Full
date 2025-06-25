class Employee {
  final String uid;
  final String no;
  final String name;
  final String nik;
  final String email;
  final String gender;
  final DateTime dob;
  final String pob;
  final String position;
  final String address;
  final DateTime joinDate;
  final String phone;

  Employee({
    required this.uid,
    required this.no,
    required this.name,
    required this.nik,
    required this.email,
    required this.gender,
    required this.dob,
    required this.pob,
    required this.position,
    required this.address,
    required this.joinDate,
    required this.phone,
  });

  Employee copyWith({
    String? no,
    String? name,
    String? nik,
    String? email,
    String? gender,
    DateTime? dob,
    String? pob,
    String? position,
    String? address,
    DateTime? joinDate,
    String? phone,
  }) {
    return Employee(
      uid: uid,
      no: no ?? this.no,
      name: name ?? this.name,
      nik: nik ?? this.nik,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      pob: pob ?? this.pob,
      position: position ?? this.position,
      address: address ?? this.address,
      joinDate: joinDate ?? this.joinDate,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'no': no,
      'name': name,
      'nik': nik,
      'email': email,
      'gender': gender,
      'dob': dob.toIso8601String(),
      'pob': pob,
      'position': position,
      'address': address,
      'joinDate': joinDate.toIso8601String(),
      'phone': phone,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      uid: map['uid'] ?? '',
      no: map['no'] ?? '',
      name: map['name'] ?? '',
      nik: map['nik'] ?? '',
      email: map['email'] ?? '',
      gender: map['gender'] ?? '',
      dob: DateTime.tryParse(map['dob'] ?? '') ?? DateTime(1970),
      pob: map['pob'] ?? '',
      position: map['position'] ?? '',
      address: map['address'] ?? '',
      joinDate: DateTime.tryParse(map['joinDate'] ?? '') ?? DateTime(1970),
      phone: map['phone'] ?? '',
    );
  }
}
