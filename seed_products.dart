import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  final productsRef = firestore.collection('products');

  final dummyProducts = [
    {
      'id': 'p1',
      'name': 'Classic Gold Chain',
      'description': 'A timeless 96.5% pure gold necklace suitable for everyday wear. Features a durable hook clasp.',
      'price': 42000.0,
      'weight': 1.0,
      'laborFee': 1200.0,
      'stock': 15,
      'imageUrl': 'https://somsrimanee.com/wp-content/uploads/2023/07/20240906-0370.jpg',
      'category': 'Necklace'
    },
    {
      'id': 'p2',
      'name': 'Dragon Carved Ring',
      'description': 'Intricately designed gold ring featuring a traditional dragon motif. Perfect for special occasions.',
      'price': 21500.0,
      'weight': 0.5,
      'laborFee': 800.0,
      'stock': 8,
      'imageUrl': 'https://somsrimanee.com/wp-content/uploads/2023/07/20240906-0158.jpg',
      'category': 'Ring'
    },
    {
      'id': 'p3',
      'name': 'Simple Gold Bangle',
      'description': 'Elegant solid gold bangle with a smooth polished finish.',
      'price': 84500.0,
      'weight': 2.0,
      'laborFee': 1500.0,
      'stock': 5,
      'imageUrl': 'https://somsrimanee.com/wp-content/uploads/2023/07/20240906-0279-Edit.jpg',
      'category': 'Bracelet'
    },
    {
      'id': 'p4',
      'name': 'Lotus Stud Earrings',
      'description': 'Delicate gold stud earrings shaped like blooming lotus flowers.',
      'price': 10800.0,
      'weight': 0.25,
      'laborFee': 600.0,
      'stock': 20,
      'imageUrl': 'https://somsrimanee.com/wp-content/uploads/2023/07/20240906-0209-Edit.jpg',
      'category': 'Earrings'
    },
    {
      'id': 'p5',
      'name': 'Ruby Embedded Ring',
      'description': 'Premium gold ring featuring a small, high-quality ruby centerpiece.',
      'price': 25000.0,
      'weight': 0.5,
      'laborFee': 2500.0,
      'stock': 3,
      'imageUrl': 'https://somsrimanee.com/wp-content/uploads/2023/07/20240906-0164.jpg',
      'category': 'Ring'
    },
  ];

  print("Starting seed...");
  for (final p in dummyProducts) {
    await productsRef.doc(p['id'].toString()).set(p);
    print("Added ${p['name']}!");
  }
  print("Done!");
}
