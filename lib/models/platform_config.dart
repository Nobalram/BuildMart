import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at: platformConfig/settings — a single document holding
/// platform-wide pricing knobs the admin can tune without an app update.
class PlatformConfig {
  final double mileageKmPerLiter;
  final double fuelCostPerLiter;
  final double platformFee;
  final double taxPercent;
  final double freeDeliveryThreshold;

  const PlatformConfig({
    this.mileageKmPerLiter = 15,
    this.fuelCostPerLiter = 100,
    this.platformFee = 29,
    this.taxPercent = 18,
    this.freeDeliveryThreshold = 5000,
  });

  factory PlatformConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const PlatformConfig();
    return PlatformConfig(
      mileageKmPerLiter: (data['mileageKmPerLiter'] ?? 15).toDouble(),
      fuelCostPerLiter: (data['fuelCostPerLiter'] ?? 100).toDouble(),
      platformFee: (data['platformFee'] ?? 29).toDouble(),
      taxPercent: (data['taxPercent'] ?? 18).toDouble(),
      freeDeliveryThreshold: (data['freeDeliveryThreshold'] ?? 5000).toDouble(),
    );
  }
}

class ConfigRepository {
  final _db = FirebaseFirestore.instance;

  Stream<PlatformConfig> watchConfig() {
    return _db
        .collection('platformConfig')
        .doc('settings')
        .snapshots()
        .map((doc) => PlatformConfig.fromMap(doc.data()));
  }
}
