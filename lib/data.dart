import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const statuses = ['Cutting', 'Stitching', 'Ready', 'Delivered'];
const mFields = ['Chest', 'Waist', 'Shoulder', 'Sleeve', 'Length', 'Shalwar', 'Collar'];

double n0(dynamic v) => v is num ? v.toDouble() : 0;
String rs(double v) => 'Rs ${NumberFormat('#,##0').format(v)}';
String fmtDate(dynamic t) => DateFormat('dd MMM yyyy').format((t as Timestamp).toDate());
String errText(Object e) => e.toString().replaceFirst('Exception: ', '');

double balance(Map<String, dynamic> o) {
  final b = n0(o['total']) - n0(o['paid']);
  return b < 0 ? 0 : b;
}

/// Har user ka data sirf users/{uid}/... mein save hota hai
class Db {
  static DocumentReference<Map<String, dynamic>> get _me => FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid);
  static CollectionReference<Map<String, dynamic>> get customers => _me.collection('customers');
  static CollectionReference<Map<String, dynamic>> get orders => _me.collection('orders');
}
