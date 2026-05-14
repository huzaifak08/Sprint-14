import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sprint_14/components/app_network_image.dart';
import 'package:uuid/uuid.dart';
import 'package:sprint_14/models/business_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/business_provider/business_provider.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/business_dashboard_view.dart';

class BusinessView extends ConsumerWidget {
  const BusinessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final businesses = ref.watch(businessProvider);

    return Scaffold(
      body: businesses.when(
        data: (bus) => bus.isEmpty
            ? _buildEmptyState(context, ref, theme)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: bus.length,
                itemBuilder: (context, index) =>
                    _BusinessCard(business: bus[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBusinessForm(context, ref),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "No active businesses",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Text(
            "Tap + to start your first shop ledger",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Unified Form for Add/Edit
  void _showBusinessForm(
    BuildContext context,
    WidgetRef ref, {
    BusinessModel? existingBusiness,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BusinessFormSheet(business: existingBusiness),
    );
  }
}

class _BusinessCard extends ConsumerWidget {
  final BusinessModel business;
  const _BusinessCard({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessDashboardView(businessId: business.id),
            ),
          ),
          onLongPress: () => _showOptions(context, ref),
          contentPadding: const EdgeInsets.all(16),
          leading: AppNetworkImage(
            path: business.logoPath,
            size: 55,
            isCircle: false,
            borderRadius: 15,
            fallbackLetter: business.name.isNotEmpty ? business.name[0] : 'B',
          ),
          title: Text(
            business.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          subtitle: Text(
            "${business.type} • ${business.currency}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text(
                "Edit Business Details",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => _BusinessFormSheet(business: business),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.red,
              ),
              title: const Text(
                "Delete Business",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                ref.read(businessProvider.notifier).deleteBusiness(business.id);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Unified Bottom Sheet for Add/Update
class _BusinessFormSheet extends ConsumerStatefulWidget {
  final BusinessModel? business;
  const _BusinessFormSheet({this.business});

  @override
  ConsumerState<_BusinessFormSheet> createState() => _BusinessFormSheetState();
}

class _BusinessFormSheetState extends ConsumerState<_BusinessFormSheet> {
  late TextEditingController nameController;
  File? _logo;
  String? _remoteLogo;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.business?.name);
    _remoteLogo = widget.business?.logoPath;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (picked != null) setState(() => _logo = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 🔥 FIXED: Accessing uid safely to avoid PigeonUserDetails error
    final user = ref.read(authControllerProvider).value;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        left: 24,
        right: 24,
        top: 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.business == null ? "NEW BUSINESS" : "UPDATE BUSINESS",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
              backgroundImage: _logo != null
                  ? FileImage(_logo!)
                  : (_remoteLogo != null && _remoteLogo!.startsWith('http')
                        ? NetworkImage(_remoteLogo!)
                        : null),
              child: (_logo == null && _remoteLogo == null)
                  ? Icon(
                      Icons.add_a_photo_outlined,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Store Name",
              prefixIcon: const Icon(Icons.store),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: () {
                // Safely get string UID
                final uid = user?.uid;
                if (uid == null || nameController.text.isEmpty) return;

                if (widget.business == null) {
                  final newBus = BusinessModel(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    type: 'Garments',
                    currency: 'PKR',
                    createdAt: DateTime.now(),
                    ownerId: uid,
                    logoPath: _logo?.path,
                    participantIds: [],
                    isSynced: false,
                    isDeleted: false,
                  );
                  ref.read(businessProvider.notifier).addBusiness(newBus);
                } else {
                  final updated = widget.business!.copyWith(
                    name: nameController.text,
                    logoPath: _logo?.path ?? widget.business?.logoPath,
                  );
                  ref.read(businessProvider.notifier).updateBusiness(updated);
                }
                Navigator.pop(context);
              },
              child: Text(
                widget.business == null ? "CREATE BUSINESS" : "SAVE CHANGES",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
