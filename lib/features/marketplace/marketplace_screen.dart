import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';

/// A starter storefront for local products and handmade goods.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  static const _categories = ['All', 'Food', 'Home', 'Beauty', 'Crafts'];

  static const _products = <_MarketplaceProduct>[
    _MarketplaceProduct(
      name: 'Rwandan Arabica Coffee',
      description: 'Small-batch roasted coffee with a smooth, bright finish.',
      category: 'Food',
      seller: 'Hillside Roasters',
      price: 8500,
      icon: Icons.coffee,
      color: Color(0xFF795548),
      badge: 'POPULAR',
    ),
    _MarketplaceProduct(
      name: 'Gahaya Woven Basket',
      description: 'A handwoven basket made by local artisans.',
      category: 'Crafts',
      seller: 'Imigongo Studio',
      price: 18000,
      icon: Icons.shopping_basket_outlined,
      color: Color(0xFFBE964E),
      badge: 'HANDMADE',
    ),
    _MarketplaceProduct(
      name: 'Pure Honey Jar',
      description: 'Locally harvested honey, naturally rich and golden.',
      category: 'Food',
      seller: 'Nyungwe Apiaries',
      price: 6000,
      icon: Icons.hive_outlined,
      color: Color(0xFFFFB300),
      badge: 'LOCAL',
    ),
    _MarketplaceProduct(
      name: 'Avocado Body Butter',
      description: 'A nourishing moisturizer made with avocado oil.',
      category: 'Beauty',
      seller: 'Green Valley Co-op',
      price: 12000,
      icon: Icons.spa_outlined,
      color: Color(0xFF689F38),
      badge: 'NATURAL',
    ),
    _MarketplaceProduct(
      name: 'Handmade Clay Mug',
      description: 'A one-of-a-kind ceramic mug finished by hand.',
      category: 'Home',
      seller: 'Earth & Fire Pottery',
      price: 9500,
      icon: Icons.coffee_maker_outlined,
      color: Color(0xFFB36B4B),
      badge: 'HANDMADE',
    ),
    _MarketplaceProduct(
      name: 'Dried Fruit Mix',
      description: 'A colorful snack mix made from locally grown fruit.',
      category: 'Food',
      seller: 'Harvest Kigali',
      price: 5000,
      icon: Icons.eco_outlined,
      color: Color(0xFF7E9B45),
      badge: 'FRESH PICK',
    ),
  ];

  final _searchController = TextEditingController();
  final Map<_MarketplaceProduct, int> _cart = {};
  String _selectedCategory = 'All';
  String _searchQuery = '';

  int get _cartCount => _cart.values.fold(0, (sum, quantity) => sum + quantity);
  int get _cartTotal => _cart.entries.fold(
        0,
        (sum, entry) => sum + (entry.key.price * entry.value),
      );

  List<_MarketplaceProduct> get _visibleProducts => _products.where((product) {
        final matchesCategory =
            _selectedCategory == 'All' || product.category == _selectedCategory;
        final query = _searchQuery.toLowerCase();
        final matchesQuery = query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            product.seller.toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(_MarketplaceProduct product) {
    setState(() {
      _cart.update(
        product,
        (quantity) => quantity + 1,
        ifAbsent: () => 1,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to your basket.'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW BASKET',
          onPressed: _showBasket,
        ),
      ),
    );
  }

  void _showBasket() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _cart.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Your basket is empty.')),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PortalHeading('Your Basket', size: 20),
                      const SizedBox(height: 12),
                      for (final entry in _cart.entries)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(entry.key.icon, color: entry.key.color),
                          title: Text(entry.key.name),
                          subtitle: Text(
                            '${entry.value} × ${_formatPrice(entry.key.price)}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove one',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                if (entry.value == 1) {
                                  _cart.remove(entry.key);
                                } else {
                                  _cart[entry.key] = entry.value - 1;
                                }
                              });
                              Navigator.pop(sheetContext);
                              _showBasket();
                            },
                          ),
                        ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Subtotal  ${_formatPrice(_cartTotal)}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const Text(
                        'Delivery and final details are confirmed by the seller.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mutedBrown),
                      ),
                      const SizedBox(height: 12),
                      PortalButton(
                        label: 'REQUEST THIS ORDER',
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _requestOrder();
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestOrder() async {
    if (_cart.isEmpty) return;

    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request an order'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This sends an inquiry to the Code Hills team. It does not take payment.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'YOUR NAME'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Please enter your name.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contactController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'EMAIL OR PHONE'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a way the seller can contact you.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('SEND REQUEST'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final orderLines = _cart.entries
          .map(
            (entry) =>
                '${entry.value} × ${entry.key.name} (${_formatPrice(entry.key.price * entry.value)})',
          )
          .join('\n');

      await AppData.instance.addInquiry({
        'name': nameController.text.trim(),
        'email': contactController.text.trim(),
        'inquiry': 'Marketplace order request:\n$orderLines\n'
            'Subtotal: ${_formatPrice(_cartTotal)}',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order request sent. The seller can follow up with you.'),
          backgroundColor: AppColors.darkBrown,
        ),
      );
    }

    nameController.dispose();
    contactController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      radius: 22,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PortalHeading('Marketplace', size: 24),
                      const SizedBox(height: 4),
                      const ImigongoBand(height: 14),
                      const SizedBox(height: 14),
                      const Text(
                        'Shop products made by local makers and small businesses.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search products or sellers',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final category in _categories)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(category),
                                  selected: _selectedCategory == category,
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = category),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_visibleProducts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No products found. Try another search.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 760
                                ? 3
                                : constraints.maxWidth >= 500
                                    ? 2
                                    : 1;
                            return GridView.builder(
                              itemCount: _visibleProducts.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 300,
                              ),
                              itemBuilder: (context, index) => _ProductCard(
                                product: _visibleProducts[index],
                                onAdd: () => _addToCart(_visibleProducts[index]),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Prices and products shown are starter examples. Update them with your real listings before launch.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_cartCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showBasket,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    'VIEW BASKET • $_cartCount ITEMS • ${_formatPrice(_cartTotal)}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onAdd});

  final _MarketplaceProduct product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => PortalCard(
        radius: 18,
        background: AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: product.color.withOpacity(0.18),
                    child: Icon(product.icon, size: 68, color: product.color),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.badge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.seller,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedBrown,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatPrice(product.price),
                          style: const TextStyle(
                            color: AppColors.darkBrown,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Add ${product.name} to basket',
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_shopping_cart, size: 19),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MarketplaceProduct {
  const _MarketplaceProduct({
    required this.name,
    required this.description,
    required this.category,
    required this.seller,
    required this.price,
    required this.icon,
    required this.color,
    required this.badge,
  });

  final String name;
  final String description;
  final String category;
  final String seller;
  final int price;
  final IconData icon;
  final Color color;
  final String badge;
}

String _formatPrice(int amount) =>
    '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} RWF';






































































































