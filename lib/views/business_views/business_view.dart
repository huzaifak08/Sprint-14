import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/models/business_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/business_provider/business_provider.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/business_dashboard_view.dart';
import 'package:uuid/uuid.dart';

class BusinessView extends ConsumerWidget {
  const BusinessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businesses = ref.watch(businessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Businesses"),
        actions: [
          IconButton(
            onPressed: () => _showAddBusinessSheet(context, ref),
            icon: const Icon(Icons.add_business_rounded),
          ),
        ],
      ),
      body: businesses.when(
        data: (bus) {
          if (bus.isEmpty) _buildEmptyState(context, ref);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bus.length,
            itemBuilder: (context, index) {
              final business = bus[index];
              return _BusinessCard(business: business);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No business found. Create your shop ledger!"),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddBusinessSheet(context, ref),
            child: const Text("Add Ladies Garment Shop"),
          ),
        ],
      ),
    );
  }

  void _showAddBusinessSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String? currentUid = ref.read(authControllerProvider).value?.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Setup New Business",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Business Name (e.g. Ladies Garments)",
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (currentUid == null) return;

                  if (nameController.text.isNotEmpty) {
                    final newBusiness = BusinessModel(
                      id: const Uuid().v4(),
                      name: nameController.text,
                      type: 'Clothing',
                      currency: 'PKR',
                      createdAt: DateTime.now(),
                      ownerId: currentUid,
                      isSynced: false,
                      isDeleted: false,
                    );
                    ref
                        .read(businessProvider.notifier)
                        .addBusiness(newBusiness);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Create Business"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final BusinessModel business;
  const _BusinessCard({required this.business});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.shopping_bag_outlined, color: Colors.white),
        ),
        title: Text(
          business.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${business.type} • ${business.currency}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to specific Business Dashboard
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessDashboardView(businessId: business.id),
            ),
          );
        },
      ),
    );
  }
}
