class Item {
  int? id;
  String name;
  String category;
  int quantity;
  String condition;

  Item({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.condition,
  });

  Map<String, dynamic> toMap() {
    return {
      'item_id': id,
      'name': name,
      'total_price': totalPrice,
      'description': description,
      'created_at': createdAt?.toString()
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      clientId: map['client_id'],
      totalPrice: map['total_price'],
      description: map['description'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null
    );
  }
}
