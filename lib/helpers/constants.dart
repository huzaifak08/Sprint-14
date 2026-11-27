import 'package:flutter/material.dart';

// App identity (Play Store / bundle id: com.digitalmunshi.app).
const String appName = 'Digital Munshi';

// The only account that sees owner tools (the Projects screen).
const String appOwnerEmail = 'huzaifa.uno@gmail.com';

// Firestore Collections:
final String usersCollection = "users";
final String projectsCollection = "projects";
final String ledgersCollection = "ledgers";
final String businessesCollection = "businesses";
final String productsCollection = "products";
final String salesCollection = "sales";
final String expensesCollection = "expenses";
final String participantsCollection = 'participants';
const String notificationsCollection = "notifications";
const String eventLedgersCollection = "event_ledgers";
const String eventParticipantsCollection = "event_participants";
const String transactionsCollection = "event_transactions";
const String milestonesCollection = "event_settlement_milestones";

// Method Channel:
const String methodChannel = "flutter_channel";

// Method Channel Methods:
const String getAppVersionMethod = "getAppVersion";

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
