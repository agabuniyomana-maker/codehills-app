import 'package:flutter/material.dart';

import '../../data/app_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';
import '../plan_detail/plan_detail_screen.dart';

/// Natural-resources catalog — port of NaturalResourcesPanel.java.
///
/// Features: resource strip, search box, price/city filters, plan cards.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const _allResources = 'ALL RESOURCES';

  String _selectedResource = _allResources;
  String _searchText = '';
  String? _priceFilter;
  String? _cityFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BusinessPlan> get _filtered {
    var list = _selectedResource == _allResources
        ? AppData.instance.plans
        : AppData.instance.plansForResource(_selectedResource);
    if (_priceFilter != null) {
      list = list.where((p) => p.priceRange == _priceFilter).toList();
    }
    if (_cityFilter != null) {
      list = list.where((p) => p.city == _cityFilter).toList();
    }
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      list = list
          .where(
            (p) =>
                p.planName.toLowerCase().contains(q) ||
                p.resourceName.toLowerCase().contains(q) ||
                p.city.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final plans = _filtered;

    return PortalCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Column(
              children: [
                const PortalHeading(
                  'Natural Resource Business Plans',
                  size: 20,
                ),
                const SizedBox(height: 6),
                const PortalHeading(
                  'Rwandan local ventures with downloadable plans',
                  size: 12,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 14),
                _resourceStrip(),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchText = v),
                  decoration: InputDecoration(
                    hintText: 'Search resources or plans...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchText.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchText = '');
                            },
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        value: _priceFilter,
                        hint: 'PRICE RANGE',
                        items: AppData.instance.priceRanges,
                        onChanged: (v) => setState(() => _priceFilter = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdown(
                        value: _cityFilter,
                        hint: 'CITY',
                        items: AppData.instance.cities,
                        onChanged: (v) => setState(() => _cityFilter = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.gold, height: 1),
          Expanded(
            child: plans.isEmpty
                ? const Center(
                    child: PortalHeading(
                      'No plans match your filters',
                      size: 15,
                      color: AppColors.mutedBrown,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(18),
                    itemCount: plans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => PlanCard(plan: plans[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _resourceStrip() {
    final names = [
      _allResources,
      ...AppData.instance.resources.map((r) => r.resourceName)
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final name = names[i];
          final selected = name == _selectedResource;
          return ChoiceChip(
            label: Text(name),
            selected: selected,
            onSelected: (_) => setState(() => _selectedResource = name),
            selectedColor: AppColors.gold,
            backgroundColor: AppColors.white,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: selected ? AppColors.white : AppColors.darkBrown,
            ),
            side: const BorderSide(color: AppColors.gold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text(
              hint,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            isExpanded: true,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
            items: [
              DropdownMenuItem(value: null, child: Text('ALL $hint')),
              for (final item in items)
                DropdownMenuItem(value: item, child: Text(item)),
            ],
            onChanged: onChanged,
          ),
        ),
      );
}

/// One plan row card with cover thumbnail and quick facts.
class PlanCard extends StatelessWidget {
  final BusinessPlan plan;

  const PlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold, width: 1.4),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                plan.coverAssetPath,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 96,
                  height: 96,
                  color: AppColors.gold,
                  child: const Icon(Icons.park, color: AppColors.white),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.planName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _typeBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.resourceName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _fact(Icons.location_on_outlined, plan.city),
                      _fact(Icons.payments_outlined, plan.priceRange),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedBrown),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: plan.isPremium ? AppColors.darkBrown : AppColors.yellow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          plan.isPremium ? 'PREMIUM' : 'FREE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: plan.isPremium ? AppColors.yellow : AppColors.darkBrown,
          ),
        ),
      );

  Widget _fact(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mutedBrown),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedBrown),
          ),
        ],
      );
}
