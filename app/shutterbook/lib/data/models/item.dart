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
      'category': category,
      'quantity': quantity,
      'condition': condition,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['item_id'],
      name: map['name'],
      category: map['category'],
      condition: map['condition'],
    );
  }
}
