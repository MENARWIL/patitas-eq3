import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  const Pet({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.species,
    required this.age,
    required this.imageUrl,
  });

  final String id;
  final String ownerUid;
  final String name;
  final String species;
  final int age;
  final String imageUrl;

  Map<String, Object> toFirestore() => {
    'ownerUid': ownerUid,
    'name': name,
    'species': species,
    'age': age,
    'imageUrl': imageUrl,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory Pet.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Pet(
      id: document.id,
      ownerUid: data['ownerUid'] as String,
      name: data['name'] as String,
      species: data['species'] as String,
      age: (data['age'] as num).toInt(),
      imageUrl: data['imageUrl'] as String,
    );
  }
}
