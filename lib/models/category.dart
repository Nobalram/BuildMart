class ProductCategory {
  final String id;
  final String name;
  final String icon;
  final int order;

  ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.order,
  });

  factory ProductCategory.fromMap(String id, Map<String, dynamic> data) {
    return ProductCategory(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      order: (data['order'] ?? 0) as int,
    );
  }
}
