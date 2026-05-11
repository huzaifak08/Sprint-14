import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../helpers/responsive_helper.dart';
import 'ledger_view/ledger_view.dart';
import 'business_views/business_view.dart';
import 'settings_view.dart';
import 'add_or_update_ledger_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop) _buildWebSidebar(theme),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              // Disable swiping on desktop for a snappier web feel
              physics: isDesktop
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              children: const [LedgerView(), BusinessView()],
            ),
          ),
        ],
      ),
      floatingActionButton: !isDesktop ? _buildMobileFab(theme) : null,
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(theme),
    );
  }

  Widget _buildWebSidebar(ThemeData theme) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        // Uses the theme's surface color, slightly adjusted for depth
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Adaptive Logo Color
          SvgPicture.asset(
            "assets/images/logo.svg",
            width: 45,
            colorFilter: ColorFilter.mode(
              theme.colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 40),
          _sidebarItem(
            theme,
            0,
            Icons.account_balance_wallet_outlined,
            Icons.account_balance_wallet,
            "Ledger",
          ),
          _sidebarItem(
            theme,
            1,
            Icons.business_outlined,
            Icons.business,
            "Business",
          ),
          const Spacer(),
          _sidebarItem(
            theme,
            2,
            Icons.settings_outlined,
            Icons.settings,
            "Settings",
            isSettings: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    ThemeData theme,
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    bool isSettings = false,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Highlight active item with primary container color
        selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.4),
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (isSettings) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsView()),
            );
          } else {
            _onNavTap(index);
          }
        },
      ),
    );
  }

  Widget _buildBottomNavBar(ThemeData theme) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onNavTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Ledger',
        ),
        NavigationDestination(
          icon: Icon(Icons.business_outlined),
          selectedIcon: Icon(Icons.business),
          label: 'Business',
        ),
      ],
    );
  }

  Widget _buildMobileFab(ThemeData theme) {
    return FloatingActionButton(
      heroTag: null, // Fixed: Prevents multiple hero lag/crash
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      onPressed: () {
        if (_currentIndex == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddOrUpdateLedgerView()),
          );
        }
      },
      child: const Icon(Icons.add),
    );
  }
}
