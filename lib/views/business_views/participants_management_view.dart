import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/components/app_network_image.dart';
import 'package:sprint_14/models/participant_model.dart';
import 'package:sprint_14/providers/participant_provider/participant_provider.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';

class ParticipantsManagementView extends ConsumerStatefulWidget {
  final String businessId;
  const ParticipantsManagementView({super.key, required this.businessId});

  @override
  ConsumerState<ParticipantsManagementView> createState() =>
      _ParticipantsManagementViewState();
}

class _ParticipantsManagementViewState
    extends ConsumerState<ParticipantsManagementView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participantsAsync = ref.watch(participantProvider(widget.businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Team Workspace",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => ref
                .read(participantProvider(widget.businessId).notifier)
                .syncPendingParticipants(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: participantsAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return _buildEmptyState(theme);
          }

          final ownersCount = staffList.where((p) => p.isOwner).length;
          final adminsCount = staffList.where((p) => p.isAdmin).length;
          final salesCount = staffList.where((p) => p.isSalesman).length;

          return RefreshIndicator(
            onRefresh: () => ref
                .read(participantProvider(widget.businessId).notifier)
                .syncPendingParticipants(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 8),
                _buildRosterMetricsCard(
                  theme,
                  ownersCount,
                  adminsCount,
                  salesCount,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ALL STAFF MEMBERS (${staffList.length})",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSecondary.withValues(
                          alpha: 0.6,
                        ),
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (staffList.any((p) => !p.isSynced))
                      Card(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: const StadiumBorder(),
                        margin: EdgeInsets.zero,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            "CHANGES PENDING",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: staffList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    // 🔥 MODIFIED: Handled via high performance standalone Consumer components
                    return _StaffRosterTileItem(
                      participant: staffList[index],
                      onAction: (action) =>
                          _handleMenuAction(action, staffList[index]),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text("Failed to load workplace parameters: $err")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          "Add Staff",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showInviteStaffSheet(context),
      ),
    );
  }

  /// --- 1. ROSTER SUMMARY ANALYTICS PANEL ---
  Widget _buildRosterMetricsCard(
    ThemeData theme,
    int owners,
    int admins,
    int sales,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.3 : 0.04,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSingleMetric(
            "Owners",
            owners.toString(),
            theme.colorScheme.primary,
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.onSecondary.withValues(alpha: 0.1),
          ),
          _buildSingleMetric(
            "Admins",
            admins.toString(),
            theme.colorScheme.tertiary,
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.onSecondary.withValues(alpha: 0.1),
          ),
          _buildSingleMetric("Salesmen", sales.toString(), Colors.teal),
        ],
      ),
    );
  }

  Widget _buildSingleMetric(String title, String count, Color accentColor) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// --- 2. OVERLAY SHEET: ADD/INVITE NEW STAFF ---
  void _showInviteStaffSheet(BuildContext context) {
    final theme = Theme.of(context);
    final emailController = TextEditingController();
    String selectedRole = 'salesman';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Add Workspace Staff",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Find your employee by email to sync them into your store operations.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Employee Email Address",
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Assign Workspace Access Role",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'salesman',
                        child: Text("Salesman (Log Transactions Only)"),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text("Admin (Full Management Control)"),
                      ),
                    ],
                    onChanged: (val) =>
                        setModalState(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (emailController.text.isNotEmpty) {
                          Navigator.pop(context);
                          try {
                            await ref
                                .read(
                                  participantProvider(
                                    widget.businessId,
                                  ).notifier,
                                )
                                .inviteUser(
                                  businessId: widget.businessId,
                                  email: emailController.text,
                                  role: selectedRole,
                                );
                            if (context.mounted) {
                              _showSnackBar(
                                context,
                                "Staff Invitation Processed Successfully.",
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              _showSnackBar(
                                context,
                                e.toString(),
                                isError: true,
                              );
                            }
                          }
                        }
                      },
                      child: const Text(
                        "Confirm & Send Access",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// --- ACTIONS ROUTER ENGINE ---
  void _handleMenuAction(String action, ParticipantModel participant) {
    final notifier = ref.read(participantProvider(widget.businessId).notifier);

    if (action == 'toggle_status') {
      notifier.toggleStaffAccess(
        businessId: widget.businessId,
        userId: participant.userId,
        isActive: !participant.isActive,
      );
    } else if (action == 'remove') {
      notifier.removeStaff(
        businessId: widget.businessId,
        userId: participant.userId,
      );
    } else if (action == 'role') {
      _showRoleUpdateDialog(context, participant);
    }
  }

  void _showRoleUpdateDialog(
    BuildContext context,
    ParticipantModel participant,
  ) {
    String roleSelection = participant.role;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Modify Status Group",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: DropdownButtonFormField<String>(
          value: roleSelection,
          items: const [
            DropdownMenuItem(value: 'salesman', child: Text("Salesman")),
            DropdownMenuItem(value: 'admin', child: Text("Admin")),
          ],
          onChanged: (val) => roleSelection = val!,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(participantProvider(widget.businessId).notifier)
                  .updateStaffRole(
                    businessId: widget.businessId,
                    userId: participant.userId,
                    newRole: roleSelection,
                  );
            },
            child: const Text("Save Privileges"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.supervised_user_circle_outlined,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "Your Workspace is Lonely",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Add your team members to manage your store collaboratively.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// --- 🔥 NEW PRODUCTION HIGH PERFORMANCE CUSTOMER ROSTER CONTAINER ITEM ---
class _StaffRosterTileItem extends ConsumerWidget {
  final ParticipantModel participant;
  final ValueChanged<String> onAction;

  const _StaffRosterTileItem({
    required this.participant,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 🔥 Watch the other user's file cache/cloud state by passing their specific UID
    final userFileAsync = ref.watch(userProvider(participant.userId));

    return Opacity(
      opacity: participant.isActive ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: !participant.isSynced
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.primary.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            // Safe Cache Image Wrapper driven dynamically by loaded other user file data
            userFileAsync.when(
              data: (user) => AppNetworkImage(
                path: user?.profilePic,
                size: 46,
                isCircle: true,
                fallbackLetter: user?.name.isNotEmpty == true
                    ? user!.name[0]
                    : 'U',
              ),
              loading: () => const SizedBox(
                width: 46,
                height: 46,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => AppNetworkImage(
                path: null,
                size: 46,
                isCircle: true,
                fallbackLetter: participant.userId.isNotEmpty
                    ? participant.userId[0]
                    : 'U',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic name loading wrapper with fallback string layout parameters
                  userFileAsync.when(
                    data: (user) => Text(
                      user?.name ?? "Unknown User",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    loading: () => Text(
                      "Loading Profile...",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: theme.colorScheme.onSecondary.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    error: (_, __) => Text(
                      "UID: ${participant.userId.substring(0, 8)}...",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildRoleBadge(theme, participant.role),
                      if (!participant.isActive) ...[
                        const SizedBox(width: 6),
                        const Text(
                          "• SUSPENDED",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: Icon(
                Icons.more_vert_rounded,
                color: theme.colorScheme.onSecondary.withValues(alpha: 0.6),
              ),
              onSelected: onAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'role',
                  child: LabelIcon(
                    icon: Icons.shield_outlined,
                    text: "Change Permissions",
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: LabelIcon(
                    icon: participant.isActive
                        ? Icons.lock_outline_rounded
                        : Icons.lock_open_rounded,
                    text: participant.isActive
                        ? "Suspend Access"
                        : "Restore Access",
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'remove',
                  child: LabelIcon(
                    icon: Icons.person_remove_outlined,
                    text: "Offboard Staff",
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(ThemeData theme, String role) {
    Color badgeColor;
    switch (role.toLowerCase()) {
      case 'owner':
        badgeColor = theme.colorScheme.primary;
        break;
      case 'admin':
        badgeColor = theme.colorScheme.tertiary;
        break;
      default:
        badgeColor = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Helper UI Component for standardizing icons next to list text elements
class LabelIcon extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const LabelIcon({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
