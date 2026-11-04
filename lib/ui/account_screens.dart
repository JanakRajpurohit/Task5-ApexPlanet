import 'package:flutter/material.dart';

import '../models/food.dart';
import '../state/crave_store.dart';
import 'crave_widgets.dart';

const _coral = Color(0xFFFF7043);
const _teal = Color(0xFF20645F);
const _muted = Color(0xFF817873);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({required this.store, super.key});

  final CraveStore store;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.store.profileName);
  late final _email = TextEditingController(text: widget.store.profileEmail);
  late final _phone = TextEditingController(text: widget.store.profilePhone);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Profile')),
    body: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFFFE6DC),
              child: Text(
                _name.text.isEmpty ? 'C' : _name.text[0].toUpperCase(),
                style: const TextStyle(
                  color: _coral,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (value) =>
                (value?.trim().isNotEmpty ?? false) ? null : 'Enter your name.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) =>
                RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(value?.trim() ?? '')
                ? null
                : 'Enter a valid email address.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
            validator: (value) =>
                RegExp(
                  r'^[+]?[0-9][0-9\s-]{7,14}$',
                ).hasMatch(value?.trim() ?? '')
                ? null
                : 'Enter a valid phone number.',
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Save Changes',
            onPressed: () {
              if (!(_key.currentState?.validate() ?? false)) return;
              widget.store.updateProfile(
                name: _name.text.trim(),
                phone: _phone.text.trim(),
                email: _email.text.trim(),
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Profile updated')));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class AddressBookScreen extends StatelessWidget {
  const AddressBookScreen({
    required this.store,
    super.key,
    this.selectOnTap = false,
  });

  final CraveStore store;
  final bool selectOnTap;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editAddress(context),
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
        backgroundColor: _coral,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text('Choose where your order should arrive.'),
          ),
          for (final address in store.addresses)
            Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  store.selectAddress(address.id);
                  if (selectOnTap) Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            address.type == 'Home'
                                ? Icons.home_outlined
                                : address.type == 'Work'
                                ? Icons.work_outline
                                : Icons.location_on_outlined,
                            color: _teal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            address.type,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            const _DefaultPill(),
                          ],
                          const Spacer(),
                          PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                _editAddress(context, address: address);
                              } else if (action == 'delete') {
                                _confirmDelete(context, address);
                              } else {
                                store.setDefaultAddress(address.id);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              if (!address.isDefault)
                                const PopupMenuItem(
                                  value: 'default',
                                  child: Text('Set as default'),
                                ),
                              if (store.addresses.length > 1)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('${address.phone}\n${address.fullAddress}'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _editAddress(
    BuildContext context, {
    DeliveryAddress? address,
  }) async {
    final result = await showModalBottomSheet<DeliveryAddress>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddressEditor(address: address, store: store),
    );
    if (result != null) store.saveAddress(result);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DeliveryAddress address,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove ${address.type} · ${address.fullAddress}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: _coral)),
          ),
        ],
      ),
    );
    if (remove == true) store.deleteAddress(address.id);
  }
}

class _AddressEditor extends StatefulWidget {
  const _AddressEditor({required this.store, this.address});

  final CraveStore store;
  final DeliveryAddress? address;

  @override
  State<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends State<_AddressEditor> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.address?.name ?? widget.store.profileName,
  );
  late final _phone = TextEditingController(
    text: widget.address?.phone ?? widget.store.profilePhone,
  );
  late final _house = TextEditingController(text: widget.address?.house ?? '');
  late final _street = TextEditingController(
    text: widget.address?.street ?? '',
  );
  late final _city = TextEditingController(text: widget.address?.city ?? '');
  late final _state = TextEditingController(text: widget.address?.state ?? '');
  late final _pincode = TextEditingController(
    text: widget.address?.pincode ?? '',
  );
  late String _type = widget.address?.type ?? 'Home';
  bool _isDefault = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _house,
      _street,
      _city,
      _state,
      _pincode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _key,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.address == null ? 'Add address' : 'Edit address',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _field(_name, 'Full name'),
            _field(
              _phone,
              'Phone number',
              keyboard: TextInputType.phone,
              validator: (value) =>
                  RegExp(r'^[+]?[0-9][0-9\s-]{7,14}$').hasMatch(value ?? '')
                  ? null
                  : 'Enter a valid phone number.',
            ),
            _field(_house, 'House / flat number'),
            _field(_street, 'Street'),
            Row(
              children: [
                Expanded(child: _field(_city, 'City')),
                const SizedBox(width: 8),
                Expanded(child: _field(_state, 'State')),
              ],
            ),
            _field(
              _pincode,
              'Pincode',
              keyboard: TextInputType.number,
              validator: (value) => RegExp(r'^[0-9]{6}$').hasMatch(value ?? '')
                  ? null
                  : 'Enter a 6-digit pincode.',
            ),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Address type'),
              items: const [
                DropdownMenuItem(value: 'Home', child: Text('Home')),
                DropdownMenuItem(value: 'Work', child: Text('Work')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _type = value ?? 'Home'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set as default address'),
              value: _isDefault,
              activeTrackColor: _coral,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Save Address',
              onPressed: () {
                if (!(_key.currentState?.validate() ?? false)) return;
                final prior = widget.address;
                Navigator.pop(
                  context,
                  DeliveryAddress(
                    id:
                        prior?.id ??
                        DateTime.now().microsecondsSinceEpoch.toString(),
                    name: _name.text.trim(),
                    phone: _phone.text.trim(),
                    house: _house.text.trim(),
                    street: _street.text.trim(),
                    city: _city.text.trim(),
                    state: _state.text.trim(),
                    pincode: _pincode.text.trim(),
                    type: _type,
                    isDefault: _isDefault || prior?.isDefault == true,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => (value?.trim().isNotEmpty ?? false) ? null : 'Required.',
    ),
  );
}

class _DefaultPill extends StatelessWidget {
  const _DefaultPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE6F2EE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'DEFAULT',
      style: TextStyle(color: _teal, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({required this.store, super.key});

  final CraveStore store;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  static const _statuses = ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: _coral,
          indicatorColor: _coral,
          tabs: [for (final status in _statuses) Tab(text: status)],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final status in _statuses)
            _OrderList(store: widget.store, status: status),
        ],
      ),
    ),
  );
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.store, required this.status});

  final CraveStore store;
  final String status;

  @override
  Widget build(BuildContext context) {
    final orders = store.orders
        .where((order) => status == 'All' || order.status == status)
        .toList();
    if (orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Your orders will show up here.'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        for (final order in orders)
          Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.id,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _StatusPill(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.items
                        .map((item) => '${item.food.name} × ${item.quantity}')
                        .join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _dateLabel(order.createdAt),
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '₹${order.total}',
                        style: const TextStyle(
                          color: _teal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Order ${order.id}'),
                            content: Text(
                              '${order.items.map((item) => '${item.food.name} × ${item.quantity}').join('\n')}\n\nTotal: ₹${order.total}\nStatus: ${order.status}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Recent order';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'Completed'
        ? const Color(0xFF2E9D68)
        : status == 'Cancelled'
        ? const Color(0xFFD94B45)
        : _coral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.store, super.key});

  final CraveStore store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Order notifications'),
            subtitle: const Text('Updates about your order'),
            value: store.orderNotifications,
            activeTrackColor: _coral,
            onChanged: store.setOrderNotifications,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.campaign_outlined),
            title: const Text('Offers & updates'),
            subtitle: const Text('New menu items and promotions'),
            value: store.promotionalNotifications,
            activeTrackColor: _coral,
            onChanged: store.setPromotionalNotifications,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            subtitle: const Text('Apply dark theme throughout Crave'),
            value: store.darkMode,
            activeTrackColor: _coral,
            onChanged: store.setDarkMode,
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(store.language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Choose language'),
                children: [
                  RadioGroup<String>(
                    groupValue: store.language,
                    onChanged: (value) {
                      if (value != null) store.setLanguage(value);
                      Navigator.pop(context);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final language in ['English', 'Hindi'])
                          RadioListTile<String>(
                            value: language,
                            title: Text(language),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showInfo(
              context,
              'Privacy Policy',
              'Crave uses Firebase Authentication for sign-in and Firestore for customer profiles, restaurant menus, orders, and delivery-address snapshots. Saved address-book entries and uploaded files are not configured.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showInfo(
              context,
              'Terms & Conditions',
              'Orders are submitted as Cash on Delivery. Check the order status in the app and pay the restaurant in cash when the order is delivered. Online payments are not available.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App information'),
            subtitle: Text('Crave · Firebase foundation · Version 1.0.0'),
          ),
        ],
      ),
    ),
  );

  void _showInfo(BuildContext context, String title, String text) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'How do I track my order?',
      'Open Orders in the app to see each submitted order and the latest status provided by the restaurant.',
    ),
    (
      'Can I change my delivery address?',
      'You can enter or select a delivery address during checkout. The address is saved with the order; address-book entries are not yet synced between sessions.',
    ),
    (
      'What payment methods are available?',
      'Cash on Delivery only. Pay the restaurant in cash when your order is delivered; online payments are not supported.',
    ),
    (
      'Can I cancel an order?',
      'Contact the restaurant if you need to cancel. A restaurant can reject a new order or cancel an order that is still in preparation.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & Support')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        for (final faq in _faqs)
          Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: const Icon(Icons.help_outline, color: _teal),
              title: Text(
                faq.$1,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [Text(faq.$2)],
            ),
          ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.support_agent, color: _coral),
            title: const Text('Contact Support'),
            subtitle: const Text(
              'We’re happy to help with your Crave questions.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Contact Crave Support',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Support contact details have not been configured.',
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Done',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class AboutCraveScreen extends StatelessWidget {
  const AboutCraveScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About Crave')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CraveWordmark(),
            const SizedBox(height: 22),
            Text(
              'Your favourite meals are just a tap away.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Crave is a Flutter food-delivery app. Customer sign-in and the published menu use Firebase. Ordering, payment, seller management, and persistent profiles are still being connected.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}

class LocationPicker extends StatefulWidget {
  const LocationPicker({required this.store, super.key});

  final CraveStore store;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final query = _search.text.toLowerCase();
      final results = widget.store.addresses.where(
        (address) =>
            query.isEmpty ||
            address.city.toLowerCase().contains(query) ||
            address.fullAddress.toLowerCase().contains(query),
      );
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deliver to', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search location or saved address',
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.my_location, color: _coral),
                title: const Text('Use current location'),
                subtitle: const Text(
                  'Current-location lookup is not connected.',
                ),
              ),
              for (final address in results)
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: _teal),
                  title: Text('${address.type} · ${address.city}'),
                  subtitle: Text(
                    address.fullAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: address.id == widget.store.selectedAddress.id
                      ? const Icon(Icons.check_circle, color: _teal)
                      : null,
                  onTap: () {
                    widget.store.selectAddress(address.id);
                    Navigator.pop(context);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.add_location_alt_outlined,
                  color: _coral,
                ),
                title: const Text('Add a new address'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AddressBookScreen(store: widget.store),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
