class Client {
    int? id;
    String firstName;
    String lastName;
    String email;
    String phone;

    Client({
        this.id,
        required this.firstName,
        required this.lastName,
        required this.email,
        required this.phone
    });

    Map<String, dynamic> toMap() {
        return {
            'id': id,
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'phone': phone,
        };
    }

    factory Client.fromMap(Map<String, dynamic> map) {
        return Client(
            id: map['id'],
            firstName: map['first_name'],
            lastName: map['last_name'],
            email: map['email'],
            phone: map['phone'],
        );
    }
}
