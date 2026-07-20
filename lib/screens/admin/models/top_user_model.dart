class TopUserModel {
  final String uid;
  final String name;
  final String phone;
  final int totalOrders;
  final double totalWeight;
  final double totalRevenue;

  const TopUserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.totalOrders,
    required this.totalWeight,
    required this.totalRevenue,
  });
}
