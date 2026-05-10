import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

final String usersCollection = "users";
final String projectsCollection = "projects";
final String ledgersCollection = "ledgers";
final String businessesCollection = "businesses";
final String productsCollection = "products";
final String salesCollection = "sales";

final String themeKey = "sprint-14-theme";

final allSteps = [
  'Step 1: Console Setup',
  'Step 2: Verification',
  'Step 3: Development',
  'Step 4: 1st Release',
  'Step 5: Testing Start',
  'Step 6: 2nd Release',
  'Step 7: 3rd Release',
  'Step 8: Production App',
  'Step 9: Go Live',
  'Step 10: Delivery',
];

final FirebaseOptions options = FirebaseOptions(
  apiKey: "AIzaSyBAYi7_tTVi9Wbz6QOu4SAxYiM3U7saCNs",
  authDomain: "sprint14-d3ab2.firebaseapp.com",
  projectId: "sprint14-d3ab2",
  storageBucket: "sprint14-d3ab2.firebasestorage.app",
  messagingSenderId: "911681711269",
  appId: "1:911681711269:web:36bac815263e2761d9f14c",
  measurementId: "G-GHZZKZ65BF",
);

final List<String> transactionCategories = [
  "Food",
  "Fuel",
  "Service",
  "Account",
  "Salary",
  "Shopping",
  "Medical",
  "Bills",
  "10%",
  "Saving",
  "Loan",
  "Travel",
  "Others",
];

final Map<String, Color> categoryColors = {
  "Food": Colors.blueAccent,
  "Fuel": Colors.orangeAccent,
  "Service": Colors.tealAccent,
  "Account": Colors.purpleAccent,
  "Salary": Colors.greenAccent,
  "Shopping": Colors.pinkAccent,
  "Medical": Colors.redAccent,
  "Bills": Colors.amberAccent,
  "10%": Colors.indigoAccent,
  "Saving": Colors.cyanAccent,
  "Loan": Colors.deepOrangeAccent,
  "Travel": Colors.lightGreenAccent,
  "Others": Colors.grey,
};
