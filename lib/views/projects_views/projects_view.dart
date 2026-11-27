import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_munshi/helpers/theme_widgets.dart';
import 'package:digital_munshi/models/project_model.dart';
import 'package:digital_munshi/providers/project_provider/project_provider.dart';
import 'package:digital_munshi/views/projects_views/components/project_card.dart';
import 'package:digital_munshi/views/projects_views/project_detail_view.dart';
import 'package:digital_munshi/views/projects_views/project_form_view.dart';

enum _ProjectFilter {
  all("All"),
  active("Active"),
  unpaid("Unpaid"),
  paid("Paid");

  final String label;
  const _ProjectFilter(this.label);

  bool matches(ProjectModel p) => switch (this) {
    _ProjectFilter.all => true,
    _ProjectFilter.active => p.isActive,
    _ProjectFilter.unpaid => !p.isPaid,
    _ProjectFilter.paid => p.isPaid,
  };
}

/// Owner-only list of client projects with search, filters and a summary.
class ProjectsView extends ConsumerStatefulWidget {
  const ProjectsView({super.key});

  @override
  ConsumerState<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends ConsumerState<ProjectsView> {
  final _searchController = TextEditingController();
  String _query = '';
  _ProjectFilter _filter = _ProjectFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectModel> _visible(List<ProjectModel> projects) {
    final q = _query.trim().toLowerCase();
    return [
      for (final p in projects)
        if (_filter.matches(p) &&
            (q.isEmpty ||
                p.appName.toLowerCase().contains(q) ||
                p.owner.toLowerCase().contains(q) ||
                p.email.toLowerCase().contains(q)))
          p,
    ];
  }

  void _openForm() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ProjectFormView()),
  );

  void _openDetail(ProjectModel project) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProjectDetailView(project: project)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsState = ref.watch(projectProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PROJECTS",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: projectsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _MessageState(
          icon: Icons.cloud_off_rounded,
          title: "Couldn't load projects",
          subtitle: "$err",
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return const _MessageState(
              icon: Icons.rocket_launch_rounded,
              title: "No projects yet",
              subtitle: "Tap \"New Project\" to add your first one.",
            );
          }
          final visible = _visible(projects);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList.list(
                  children: [
                    _SummaryHeader(projects: projects),
                    const SizedBox(height: 20),
                    _buildSearchField(theme),
                    const SizedBox(height: 12),
                    _buildFilters(theme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (visible.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.search_off_rounded,
                    title: "No matching projects",
                    subtitle: "Try another search or filter.",
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  sliver: SliverList.builder(
                    itemCount: visible.length,
                    itemBuilder: (_, i) => ProjectCard(
                      key: ValueKey(visible[i].id),
                      project: visible[i],
                      onTap: () => _openDetail(visible[i]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'projects_add',
        onPressed: _openForm,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "NEW PROJECT",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: "Search app, owner or email",
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: "Clear",
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Theme(
      data: theme.copyWith(chipTheme: themedChips(theme)),
      child: Wrap(
        spacing: 8,
        children: [
          for (final f in _ProjectFilter.values)
            ChoiceChip(
              label: Text(f.label),
              selected: _filter == f,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) => setState(() => _filter = f),
            ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final List<ProjectModel> projects;
  const _SummaryHeader({required this.projects});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = projects.where((p) => p.isActive).length;
    final paid = projects.where((p) => p.isPaid).length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primary.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TOTAL PROJECTS",
            style: TextStyle(
              color: cs.onPrimary.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${projects.length}",
            style: TextStyle(
              color: cs.onPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: "ACTIVE", value: active),
              _Stat(label: "PAID", value: paid),
              _Stat(label: "UNPAID", value: projects.length - paid),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: cs.onPrimary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$value",
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: cs.onPrimary.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.primary.withValues(alpha: 0.25)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.outline, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
