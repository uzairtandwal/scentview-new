class UserAddress {
  final int? id;
  final String title; // Home, Office, etc.
  final String fullName;
  final String phone;
  final String fullAddress;
  final bool isDefault;

  UserAddress({
    this.id,
    required this.title,
    required this.fullName,
    required this.phone,
    required this.fullAddress,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'fullName': fullName,
      'phone': phone,
      'fullAddress': fullAddress,
      'isDefault': isDefault ? 1 : 0,
    };
  }
}
