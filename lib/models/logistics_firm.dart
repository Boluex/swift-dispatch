// lib/models/logistics_firm.dart

class LogisticsFirm {
  final String companyName;
  final String address;
  final String city;
  final String state;
  final String whatsappPhoneNumber;
  final String email;
  final String? website;
  final double rating;
  final double distanceAway;
  final double price;

  LogisticsFirm({
    required this.companyName,
    required this.address,
    required this.city,
    required this.state,
    required this.whatsappPhoneNumber,
    required this.email,
    this.website,
    required this.rating,
    required this.distanceAway,
    required this.price,
  });
}