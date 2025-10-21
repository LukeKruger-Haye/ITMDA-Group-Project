class Quote {
  int? id;
  int clientId;
  double totalPrice;
  String description;
  String? createdAt;

  Quote({
    this.id,
    required this.clientId,
    required this.totalPrice,
    required this.description,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'quote_id': id,
      'client_id': clientId,
      'total_price': totalPrice,
      'description': description,
      'created_at': createdAt?.toString()
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['quote_id'],
      clientId: map['client_id'],
      totalPrice: map['total_price'],
      description: map['description'],
      createdAt: map['created_at'] 
    );
  }
}
