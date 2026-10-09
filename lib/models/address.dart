import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String label;
  final String fullName;
  final String phoneNumber;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  String get formatted => '$addressLine, $city, $state - $pincode';

  factory Address.fromMap(String id, Map<String, dynamic> data) {
    return Address(
      id: id,
      label: data['label'] ?? 'Home',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      addressLine: data['addressLine'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      pincode: data['pincode'] ?? '',
      isDefault: data['isDefault'] ?? false,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'pincode': pincode,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
