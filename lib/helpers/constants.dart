import 'package:flutter/material.dart';

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
