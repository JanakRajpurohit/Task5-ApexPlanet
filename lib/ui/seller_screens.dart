import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/seller_firebase_service.dart';
import '../models/seller_models.dart';
import '../services/firebase_auth_service.dart';
import '../services/seller_onboarding_service.dart';
import '../state/seller_store.dart';
import 'crave_widgets.dart';

const _sellerOrange = Color(0xFFFF7043);
const _sellerTeal = Color(0xFF20645E);
const _sellerInk = Color(0xFF302927);
const _sellerMuted = Color(0xFF827873);
const _sellerGreen = Color(0xFF279B67);
const _sellerRed = Color(0xFFDC4545);

void _sellerMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void _sellerOpen(BuildContext context, Widget page, {bool replace = false}) {
  final route = MaterialPageRoute<void>(builder: (_) => page);
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

String _money(int amount) => '₹$amount';

String _shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({super.key, this.onCustomerLogin});

  final VoidCallback? onCustomerLogin;

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _passwordVisible = false;
  bool _remember = false;
  bool _loading = false;

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _sellerMessage(context, 'Enter your email address first.');
      return;
    }
    try {
      await FirebaseAuthService().sendPasswordReset(email);
      if (mounted) _sellerMessage(context, 'Password reset email sent.');
    } on FirebaseAuthException catch (error) {
      if (mounted) _sellerMessage(context, error.message ?? error.code);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final authService = FirebaseAuthService();
    try {
      final credential = await authService.signIn(
        email: _email.text,
        password: _password.text,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase Authentication returned no user.');
      }
      final role = await authService.roleFor(user.uid);
      if (role != 'seller') {
        await authService.signOut();
      } else {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      if (!mounted) return;
      _sellerMessage(
        context,
        'This account is not registered as a restaurant partner.',
      );
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        _sellerMessage(context, error.message ?? error.code);
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        _sellerMessage(context, error.message ?? error.code);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  alignment: Alignment.centerLeft,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(height: 8),
                const CraveWordmark(),
                const SizedBox(height: 30),
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE6DC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: _sellerOrange,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                const Text('Sign in to manage your restaurant on Crave.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) =>
                      RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Enter a valid email address.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => (value?.length ?? 0) >= 6
                      ? null
                      : 'Use at least 6 characters.',
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _remember,
                      activeColor: _sellerOrange,
                      onChanged: (value) =>
                          setState(() => _remember = value ?? false),
                    ),
                    const Expanded(child: Text('Remember me')),
                    TextButton(
                      onPressed: _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: _sellerOrange,
                      foregroundColor: Colors.white,
                    ),
                    icon: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(_loading ? 'Signing in…' : 'Login'),
                  ),
                ),
                const SizedBox(height: 16),
                const _InfoPanel(
                  icon: Icons.info_outline,
                  text:
                      'Sign in with the seller account created during restaurant registration. Menu and order management sync through Firebase.',
                ),
                const SizedBox(height: 18),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('New to Crave? '),
                      TextButton(
                        onPressed: () => _sellerOpen(
                          context,
                          const SellerRegistrationScreen(),
                        ),
                        child: const Text('Register your restaurant'),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: TextButton.icon(
                    onPressed:
                        widget.onCustomerLogin ?? () => Navigator.pop(context),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Back to Customer Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() =>
      _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _owner = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _restaurant = TextEditingController();
  final _description = TextEditingController();
  final _restaurantPhone = TextEditingController();
  final _restaurantEmail = TextEditingController();
  final _country = TextEditingController(text: 'India');
  final _state = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  final _landmark = TextEditingController();
  final _cuisine = TextEditingController();
  final _prep = TextEditingController(text: '25');
  final _minimum = TextEditingController(text: '199');
  int _step = 0;
  bool _passwordVisible = false;
  bool _agree = false;
  bool _submitting = false;
  final Set<String> _workingDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'};
  String _opening = '10:00 AM';
  String _closing = '10:00 PM';

  List<TextEditingController> get _controllers => [
    _owner,
    _email,
    _phone,
    _password,
    _confirm,
    _restaurant,
    _description,
    _restaurantPhone,
    _restaurantEmail,
    _country,
    _state,
    _city,
    _area,
    _address,
    _pincode,
    _landmark,
    _cuisine,
    _prep,
    _minimum,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value?.trim().isNotEmpty == true ? null : 'This field is required.';

  String? _positiveInteger(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number != null && number > 0
        ? null
        : 'Enter a whole number greater than zero.';
  }

  String? _nonNegativeInteger(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number != null && number >= 0
        ? null
        : 'Enter a non-negative whole number.';
  }

  List<Widget> _stepFields() {
    switch (_step) {
      case 0:
        return [
          _textField(_owner, 'Owner full name', validator: _required),
          _textField(
            _email,
            'Email address',
            keyboard: TextInputType.emailAddress,
            validator: (value) =>
                RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(value?.trim() ?? '')
                ? null
                : 'Enter a valid email address.',
          ),
          _textField(
            _phone,
            'Mobile number',
            keyboard: TextInputType.phone,
            validator: (value) =>
                RegExp(
                  r'^[+]?[0-9][0-9\s-]{7,14}$',
                ).hasMatch(value?.trim() ?? '')
                ? null
                : 'Enter a valid mobile number.',
          ),
          _textField(
            _password,
            'Password',
            obscure: !_passwordVisible,
            validator: (value) =>
                (value?.length ?? 0) >= 6 ? null : 'Use at least 6 characters.',
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          _textField(
            _confirm,
            'Confirm password',
            obscure: !_passwordVisible,
            validator: (value) =>
                value == _password.text ? null : 'Passwords do not match.',
          ),
        ];
      case 1:
        return [
          _textField(_restaurant, 'Restaurant name', validator: _required),
          _textField(
            _description,
            'Restaurant description',
            validator: _required,
            maxLines: 3,
          ),
          _textField(
            _restaurantPhone,
            'Restaurant contact number',
            keyboard: TextInputType.phone,
            validator: _required,
          ),
          _textField(
            _restaurantEmail,
            'Restaurant email',
            keyboard: TextInputType.emailAddress,
            validator: _required,
          ),
          _uploadTile('Restaurant logo'),
          _uploadTile('Restaurant cover image'),
          _textField(
            _cuisine,
            'Restaurant category / cuisine',
            validator: _required,
          ),
        ];
      case 2:
        return [
          _textField(_country, 'Country', validator: _required),
          _textField(_state, 'State', validator: _required),
          _textField(_city, 'City', validator: _required),
          _textField(_area, 'Area', validator: _required),
          _textField(
            _address,
            'Complete address',
            validator: _required,
            maxLines: 2,
          ),
          _textField(
            _pincode,
            'PIN code',
            keyboard: TextInputType.number,
            validator: _required,
          ),
          _textField(_landmark, 'Landmark'),
        ];
      case 3:
        return [
          _textField(_cuisine, 'Cuisine type', validator: _required),
          _timePicker('Opening time', _opening, (value) => _opening = value),
          _timePicker('Closing time', _closing, (value) => _closing = value),
          const Text(
            'Working days',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Wrap(
            spacing: 4,
            children: [
              for (final day in [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ])
                FilterChip(
                  label: Text(day),
                  selected: _workingDays.contains(day),
                  onSelected: (selected) => setState(
                    () => selected
                        ? _workingDays.add(day)
                        : _workingDays.remove(day),
                  ),
                ),
            ],
          ),
          _textField(
            _prep,
            'Average preparation time (minutes)',
            keyboard: TextInputType.number,
            validator: _positiveInteger,
          ),
          _textField(
            _minimum,
            'Minimum order amount (₹)',
            keyboard: TextInputType.number,
            validator: _nonNegativeInteger,
          ),
        ];
      default:
        return [
          const _InfoPanel(
            icon: Icons.verified_user_outlined,
            text:
                'Your restaurant account is created immediately. Document uploads are not available, so do not provide document numbers or files here.',
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _agree,
            title: const Text(
              'I confirm that these business details are accurate.',
            ),
            onChanged: (value) => setState(() => _agree = value ?? false),
          ),
        ];
    }
  }

  Future<void> _selectTime(
    String current,
    ValueChanged<String> onSelected,
  ) async {
    final initial = TimeOfDay(
      hour: current.contains('PM') ? 18 : 10,
      minute: 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() => onSelected(picked.format(context)));
  }

  Widget _timePicker(
    String label,
    String value,
    ValueChanged<String> onSelected,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: OutlinedButton(
      onPressed: () => _selectTime(value, onSelected),
      child: Text(value),
    ),
  );

  Widget _uploadTile(String label) => OutlinedButton.icon(
    onPressed: () => _sellerMessage(
      context,
      'Image selection is prepared for future storage integration; no file is uploaded.',
    ),
    icon: const Icon(Icons.add_photo_alternate_outlined),
    label: Text('Add $label'),
  );

  Future<void> _next() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step == 4) {
      if (!_agree) {
        _sellerMessage(context, 'Please confirm your business details.');
        return;
      }
      await _submitRegistration();
      return;
    }
    setState(() => _step++);
  }

  Future<void> _submitRegistration() async {
    setState(() => _submitting = true);
    final restaurantDetails = <String, Object?>{
      'restaurantName': _restaurant.text.trim(),
      'description': _description.text.trim(),
      'restaurantPhone': _restaurantPhone.text.trim(),
      'restaurantEmail': _restaurantEmail.text.trim(),
      'address': {
        'country': _country.text.trim(),
        'state': _state.text.trim(),
        'city': _city.text.trim(),
        'area': _area.text.trim(),
        'street': _address.text.trim(),
        'pincode': _pincode.text.trim(),
        'landmark': _landmark.text.trim(),
      },
      'cuisine': _cuisine.text.trim(),
      'openingTime': _opening,
      'closingTime': _closing,
      'workingDays': _workingDays.toList()..sort(),
      'preparationMinutes': int.parse(_prep.text.trim()),
      'minimumOrderAmount': int.parse(_minimum.text.trim()),
    };

    try {
      await SellerOnboardingService().createSellerAccount(
        ownerName: _owner.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        restaurantDetails: restaurantDetails,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) _sellerMessage(context, error.message ?? error.code);
    } on FirebaseException catch (error) {
      if (mounted) {
        _sellerMessage(
          context,
          'Could not save your application (${error.code}). Check that the latest Firestore rules are deployed.',
        );
      }
    } on StateError catch (error) {
      if (mounted) _sellerMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Owner information',
      'Restaurant information',
      'Restaurant address',
      'Business information',
      'Finish registration',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register your restaurant'),
        actions: [
          TextButton(
            onPressed: () => _sellerMessage(
              context,
              'Progress is kept only for this registration session.',
            ),
            child: const Text('Save progress'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'Step ${_step + 1} of 5',
                style: const TextStyle(
                  color: _sellerTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_step + 1) / 5,
                color: _sellerOrange,
                backgroundColor: const Color(0xFFFFE6DC),
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 18),
              Text(
                titles[_step],
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ..._stepFields().expand(
                (field) => [field, const SizedBox(height: 12)],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: _sellerOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_step == 4 ? 'Submit registration' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SellerAccountScreen extends StatelessWidget {
  const SellerAccountScreen({required this.onSignOut, super.key});

  final Future<void> Function() onSignOut;

  Future<void> _signOut(BuildContext context) async {
    try {
      await onSignOut();
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        _sellerMessage(context, error.message ?? error.code);
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        _sellerMessage(context, error.message ?? error.code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined, size: 56, color: _sellerOrange),
                const SizedBox(height: 18),
                Text(
                  'Your restaurant account is ready.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No review is required to create an account. Menu and order management sync through Firebase; document uploads are not enabled.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _signOut(context),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SellerPortal extends StatefulWidget {
  const SellerPortal({required this.uid, required this.onSignOut, super.key});

  final String uid;
  final Future<void> Function() onSignOut;

  @override
  State<SellerPortal> createState() => _SellerPortalState();
}

class _SellerPortalState extends State<SellerPortal> {
  late final SellerFirebaseService _service = SellerFirebaseService();
  late Future<SellerStore> _storeFuture = _loadStore();
  SellerStore? _store;

  Future<SellerStore> _loadStore() async {
    final bootstrap = await _service.loadSeller(widget.uid);
    final store =
        SellerStore(
            account: bootstrap.account,
            restaurant: bootstrap.restaurant,
            foods: bootstrap.foods,
            orders: bootstrap.orders,
            offers: bootstrap.offers,
            notifications: bootstrap.notifications,
            reviews: bootstrap.reviews,
            categories: bootstrap.categories,
            firebaseService: _service,
          )
          ..workingDays.addAll(bootstrap.workingDays)
          ..scheduledClosures.addAll(bootstrap.scheduledClosures);
    store.startRealtime(widget.uid);
    _store = store;
    return store;
  }

  @override
  void dispose() {
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<SellerStore>(
    future: _storeFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Restaurant portal')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load restaurant data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => setState(() {
                      _storeFuture = _loadStore();
                    }),
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: widget.onSignOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return SellerShell(store: snapshot.data!, onSignOut: widget.onSignOut);
    },
  );
}

class SellerShell extends StatefulWidget {
  const SellerShell({required this.store, this.onSignOut, super.key});

  final SellerStore store;
  final Future<void> Function()? onSignOut;

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final pages = [
        SellerDashboardTab(store: widget.store, onSelectTab: _selectTab),
        SellerOrdersTab(store: widget.store),
        SellerMenuTab(store: widget.store),
        SellerAnalyticsTab(store: widget.store),
        SellerProfileTab(store: widget.store, onSignOut: widget.onSignOut),
      ];
      final destinations = [
        (Icons.space_dashboard_outlined, Icons.space_dashboard, 'Dashboard'),
        (Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
        (Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Menu'),
        (Icons.insights_outlined, Icons.insights, 'Analytics'),
        (Icons.person_outline, Icons.person, 'Profile'),
      ];
      final wide = MediaQuery.sizeOf(context).width >= 850;
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (widget.store.operationError case final error?)
                MaterialBanner(
                  content: Text('Could not save your change: $error'),
                  leading: const Icon(Icons.error_outline),
                  actions: [
                    TextButton(
                      onPressed: widget.store.clearOperationError,
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              Expanded(
                child: Row(
                  children: [
                    if (wide)
                      NavigationRail(
                        selectedIndex: _index,
                        onDestinationSelected: _selectTab,
                        labelType: NavigationRailLabelType.all,
                        leading: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CraveWordmark(),
                        ),
                        destinations: [
                          for (
                            var index = 0;
                            index < destinations.length;
                            index++
                          )
                            NavigationRailDestination(
                              icon: Icon(
                                index == 1 && widget.store.pendingOrders > 0
                                    ? Icons.notifications_active_outlined
                                    : destinations[index].$1,
                              ),
                              selectedIcon: Icon(destinations[index].$2),
                              label: Text(destinations[index].$3),
                            ),
                        ],
                      ),
                    Expanded(
                      child: IndexedStack(index: _index, children: pages),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _selectTab,
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: Icon(destination.$1),
                      selectedIcon: Icon(destination.$2),
                      label: destination.$3,
                    ),
                ],
              ),
      );
    },
  );

  void _selectTab(int index) => setState(() => _index = index);
}

class SellerDashboardTab extends StatelessWidget {
  const SellerDashboardTab({
    required this.store,
    required this.onSelectTab,
    super.key,
  });

  final SellerStore store;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final orders = store.restaurantOrders;
    final recent = orders.take(3).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      children: [
        Row(
          children: [
            const CraveWordmark(),
            const Spacer(),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () =>
                  _sellerOpen(context, SellerNotificationsScreen(store: store)),
              icon: Badge(
                isLabelVisible: store.unreadNotifications > 0,
                label: Text('${store.unreadNotifications}'),
                child: const Icon(Icons.notifications_none),
              ),
            ),
            IconButton(
              tooltip: 'Restaurant profile',
              onPressed: () => onSelectTab(4),
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: _sellerTeal,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: _sellerTeal,
                  child: Icon(Icons.restaurant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.restaurant.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        store.restaurant.isOpen
                            ? 'Open for orders'
                            : 'Currently closed',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: store.restaurant.isOpen,
                  activeThumbColor: _sellerOrange,
                  onChanged: store.restaurant.isApproved
                      ? store.setRestaurantOpen
                      : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Today at a glance',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 680 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.65,
              children: [
                _MetricCard(
                  title: "Today's orders",
                  value: '${store.todayOrders}',
                  icon: Icons.receipt_long,
                  color: _sellerTeal,
                ),
                _MetricCard(
                  title: "Today's revenue",
                  value: _money(store.todayRevenue),
                  icon: Icons.payments_outlined,
                  color: _sellerGreen,
                ),
                _MetricCard(
                  title: 'Pending orders',
                  value: '${store.pendingOrders}',
                  icon: Icons.hourglass_bottom,
                  color: _sellerOrange,
                ),
                _MetricCard(
                  title: 'Completed',
                  value: '${store.completedOrders}',
                  icon: Icons.task_alt,
                  color: _sellerGreen,
                ),
                _MetricCard(
                  title: 'Cancelled',
                  value:
                      '${orders.where((order) => order.orderStatus == 'Cancelled' || order.orderStatus == 'Rejected').length}',
                  icon: Icons.cancel_outlined,
                  color: _sellerRed,
                ),
                _MetricCard(
                  title: 'Average rating',
                  value: store.restaurantReviews.isEmpty
                      ? 'No reviews'
                      : '${store.averageRating.toStringAsFixed(1)} ★',
                  icon: Icons.star_outline,
                  color: Color(0xFFE6A32E),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Revenue overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => onSelectTab(3),
              child: const Text('Analytics'),
            ),
          ],
        ),
        _SellerChart(
          title: 'Revenue · last 7 days',
          values: _dailyTrend(store, revenue: true),
          labels: _lastSevenDayLabels(DateTime.now()),
          color: _sellerOrange,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent orders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => onSelectTab(1),
              child: const Text('View all'),
            ),
          ],
        ),
        if (recent.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            message: 'New restaurant orders will appear here.',
          )
        else
          for (final order in recent) _OrderCard(store: store, order: order),
        const SizedBox(height: 16),
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickAction(
              icon: Icons.add_circle_outline,
              label: 'Add new food',
              onTap: () =>
                  _sellerOpen(context, SellerFoodFormScreen(store: store)),
            ),
            _QuickAction(
              icon: Icons.inventory_2_outlined,
              label: 'Inventory',
              onTap: () =>
                  _sellerOpen(context, SellerInventoryScreen(store: store)),
            ),
            _QuickAction(
              icon: Icons.local_offer_outlined,
              label: 'Manage offers',
              onTap: () =>
                  _sellerOpen(context, SellerOffersScreen(store: store)),
            ),
            _QuickAction(
              icon: Icons.reviews_outlined,
              label: 'View reviews',
              onTap: () =>
                  _sellerOpen(context, SellerReviewsScreen(store: store)),
            ),
          ],
        ),
      ],
    );
  }
}

class SellerOrdersTab extends StatefulWidget {
  const SellerOrdersTab({required this.store, super.key});

  final SellerStore store;

  @override
  State<SellerOrdersTab> createState() => _SellerOrdersTabState();
}

class _SellerOrdersTabState extends State<SellerOrdersTab> {
  static const _filters = [
    'All',
    'New',
    'Accepted',
    'Preparing',
    'Ready for Pickup',
    'Completed',
    'Rejected',
    'Cancelled',
  ];
  String _filter = 'All';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final orders = widget.store.restaurantOrders.where(
        (order) => _filter == 'All' || order.orderStatus == _filter,
      );
      return Column(
        children: [
          _SellerAppBar(
            title: 'Orders',
            trailing: Badge(
              isLabelVisible: widget.store.pendingOrders > 0,
              label: Text('${widget.store.pendingOrders}'),
              child: const Icon(Icons.notifications_active_outlined),
            ),
            onTrailing: () => _sellerOpen(
              context,
              SellerNotificationsScreen(store: widget.store),
            ),
          ),
          SizedBox(
            height: 54,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                for (final filter in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      selectedColor: const Color(0xFFFFE6DC),
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? const _EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No orders in this section',
                    message: 'Try another filter or check back later.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (final order in orders)
                        _OrderCard(store: widget.store, order: order),
                    ],
                  ),
          ),
        ],
      );
    },
  );
}

class SellerOrderDetailScreen extends StatelessWidget {
  const SellerOrderDetailScreen({
    required this.store,
    required this.order,
    super.key,
  });

  final SellerStore store;
  final SellerOrder order;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final current = store.orderById(order.orderId) ?? order;
      final next = _nextOrderAction(current.orderStatus);
      final updatePending = store.isOrderUpdatePending(current.orderId);
      return Scaffold(
        appBar: AppBar(title: Text('Order ${current.orderId}')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    current.customerName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _StatusChip(status: current.orderStatus),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${current.createdAt.toLocal()}'.split('.').first,
              style: const TextStyle(color: _sellerMuted),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  for (final item in current.items)
                    ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        'Qty ${item.quantity} · ${_money(item.unitPrice)} each'
                        '${item.customizations.isEmpty ? '' : '\n${item.customizations.join(' · ')}'}',
                      ),
                      trailing: Text(
                        _money(item.total),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            _DetailSection(
              title: 'Customer & delivery',
              children: [
                _InfoRow(label: 'Customer', value: current.customerName),
                _InfoRow(label: 'Contact', value: current.customerPhone),
                _InfoRow(label: 'Address', value: current.deliveryAddress),
                if (current.instructions.isNotEmpty)
                  _InfoRow(label: 'Instructions', value: current.instructions),
              ],
            ),
            _DetailSection(
              title: 'Payment',
              children: [
                _InfoRow(label: 'Subtotal', value: _money(current.subtotal)),
                _InfoRow(
                  label: 'Delivery fee',
                  value: _money(current.deliveryFee),
                ),
                _InfoRow(
                  label: 'Discount',
                  value: '-${_money(current.discount)}',
                ),
                _InfoRow(label: 'Total', value: _money(current.totalAmount)),
                _InfoRow(label: 'Method', value: current.paymentMethod),
                _InfoRow(label: 'Payment status', value: current.paymentStatus),
              ],
            ),
            _DetailSection(
              title: 'Order timeline',
              children: [
                for (final update in current.statusHistory.reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle, color: _sellerTeal),
                    title: Text(update.status),
                    subtitle: Text(
                      '${update.updatedAt.toLocal()}'.split('.').first +
                          (update.note.isEmpty ? '' : '\n${update.note}'),
                    ),
                  ),
              ],
            ),
            if (current.orderStatus == 'Accepted')
              OutlinedButton.icon(
                onPressed: () => _editPrepTime(context, store, current),
                icon: const Icon(Icons.timer_outlined),
                label: Text(
                  'Preparation time: ${current.preparationMinutes} min',
                ),
              ),
            if (current.orderStatus == 'New') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _sellerRed,
                      ),
                      onPressed: updatePending
                          ? null
                          : () => _rejectOrder(context, store, current),
                      child: const Text('Reject order'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _sellerGreen,
                      ),
                      onPressed: updatePending
                          ? null
                          : () => _acceptOrder(context, store, current),
                      child: const Text('Accept order'),
                    ),
                  ),
                ],
              ),
            ] else if (next != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _sellerTeal),
                  onPressed: updatePending
                      ? null
                      : () async {
                          if (await store.updateOrderStatus(
                                current.orderId,
                                next,
                              ) &&
                              context.mounted) {
                            _sellerMessage(context, 'Order updated to $next.');
                          }
                        },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('Mark as $next'),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.store, required this.order});

  final SellerStore store;
  final SellerOrder order;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _sellerOpen(
        context,
        SellerOrderDetailScreen(store: store, order: order),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (order.orderStatus == 'New')
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: _sellerOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    order.orderId,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _StatusChip(status: order.orderStatus),
              ],
            ),
            const SizedBox(height: 8),
            Text('${order.customerName} · ${order.itemCount} items'),
            Text(
              '${_shortDate(order.createdAt)} · ${TimeOfDay.fromDateTime(order.createdAt).format(context)} · ${order.paymentMethod} (${order.paymentStatus})',
              style: const TextStyle(color: _sellerMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.items
                        .map((item) => '${item.quantity}× ${item.name}')
                        .join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _money(order.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (order.orderStatus == 'New') ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: store.isOrderUpdatePending(order.orderId)
                          ? null
                          : () => _rejectOrder(context, store, order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _sellerRed,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: store.isOrderUpdatePending(order.orderId)
                          ? null
                          : () => _acceptOrder(context, store, order),
                      style: FilledButton.styleFrom(
                        backgroundColor: _sellerGreen,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ] else if (_nextOrderAction(order.orderStatus) case final next?)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: store.isOrderUpdatePending(order.orderId)
                      ? null
                      : () async {
                          if (await store.updateOrderStatus(
                                order.orderId,
                                next,
                              ) &&
                              context.mounted) {
                            _sellerMessage(context, 'Order updated to $next.');
                          }
                        },
                  child: Text('Mark as $next'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

String? _nextOrderAction(String status) => switch (status) {
  'Accepted' => 'Preparing',
  'Preparing' => 'Ready for Pickup',
  'Ready for Pickup' => 'Picked Up',
  'Picked Up' => 'Delivered',
  _ => null,
};

Future<void> _acceptOrder(
  BuildContext context,
  SellerStore store,
  SellerOrder order,
) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Accept this order?'),
      content: const Text('The customer will see that you accepted the order.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Accept order'),
        ),
      ],
    ),
  );
  if (accepted != true || !context.mounted) return;
  if (await store.updateOrderStatus(order.orderId, 'Accepted') &&
      context.mounted) {
    _sellerMessage(context, 'Order accepted. Set a preparation estimate.');
    await _editPrepTime(context, store, order);
  }
}

Future<void> _rejectOrder(
  BuildContext context,
  SellerStore store,
  SellerOrder order,
) async {
  const reasons = [
    'Item Unavailable',
    'Restaurant Too Busy',
    'Restaurant Closed',
    'Technical Issue',
    'Other',
  ];
  var reason = reasons.first;
  final explanation = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Reject order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: reason,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: [
                for (final item in reasons)
                  DropdownMenuItem(value: item, child: Text(item)),
              ],
              onChanged: (value) {
                if (value != null) setDialogState(() => reason = value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: explanation,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Additional explanation (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _sellerRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm rejection'),
          ),
        ],
      ),
    ),
  );
  final note = explanation.text.trim().isEmpty
      ? reason
      : '$reason — ${explanation.text.trim()}';
  explanation.dispose();
  if (confirmed != true || !context.mounted) return;
  if (await store.updateOrderStatus(order.orderId, 'Rejected', note: note) &&
      context.mounted) {
    _sellerMessage(context, 'Order rejected.');
  }
}

Future<void> _editPrepTime(
  BuildContext context,
  SellerStore store,
  SellerOrder order,
) async {
  final controller = TextEditingController(
    text: '${store.orderById(order.orderId)?.preparationMinutes ?? 25}',
  );
  final save = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Preparation estimate'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Minutes (5–180)',
          suffixText: 'min',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  final minutes = int.tryParse(controller.text);
  controller.dispose();
  if (save != true || !context.mounted) return;
  if (minutes == null) {
    _sellerMessage(context, 'Enter preparation time in minutes.');
    return;
  }
  if (minutes < 5 || minutes > 180) {
    _sellerMessage(context, 'Enter a time between 5 and 180 minutes.');
    return;
  }
  if (await store.updatePreparationTime(order.orderId, minutes) &&
      context.mounted) {
    _sellerMessage(context, 'Preparation estimate updated.');
  }
}

class SellerMenuTab extends StatefulWidget {
  const SellerMenuTab({required this.store, super.key});

  final SellerStore store;

  @override
  State<SellerMenuTab> createState() => _SellerMenuTabState();
}

class _SellerMenuTabState extends State<SellerMenuTab> {
  final _search = TextEditingController();
  String _category = 'All';
  String _sort = 'Recently Added';
  bool _includeDrafts = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final foods = widget.store.restaurantFoods.where((food) {
        final query = _search.text.trim().toLowerCase();
        return (_category == 'All' || food.category == _category) &&
            (_includeDrafts || !food.isDraft) &&
            (query.isEmpty ||
                food.name.toLowerCase().contains(query) ||
                food.description.toLowerCase().contains(query));
      }).toList();
      switch (_sort) {
        case 'Price':
          foods.sort((a, b) => a.price.compareTo(b.price));
        case 'Popularity':
          foods.sort((a, b) => b.popularity.compareTo(a.popularity));
        case 'Rating':
          foods.sort((a, b) => b.rating.compareTo(a.rating));
        default:
          foods.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return Column(
        children: [
          _SellerAppBar(
            title: 'Menu',
            trailing: const Icon(Icons.category_outlined),
            onTrailing: () => _sellerOpen(
              context,
              SellerCategoriesScreen(store: widget.store),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search menu items',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All categories'),
                          ),
                          for (final category in widget.store.categories)
                            DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _category = value ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sort,
                        decoration: const InputDecoration(
                          labelText: 'Sort by',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: [
                          for (final sort in [
                            'Recently Added',
                            'Price',
                            'Popularity',
                            'Rating',
                          ])
                            DropdownMenuItem(value: sort, child: Text(sort)),
                        ],
                        onChanged: (value) =>
                            setState(() => _sort = value ?? 'Recently Added'),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show drafts'),
                  value: _includeDrafts,
                  onChanged: (value) => setState(() => _includeDrafts = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: foods.isEmpty
                ? const _EmptyState(
                    icon: Icons.restaurant_menu,
                    title: 'No menu items found',
                    message: 'Add a food item or change your filters.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: [
                      for (final food in foods)
                        _SellerFoodCard(store: widget.store, food: food),
                    ],
                  ),
          ),
        ],
      );
    },
  );
}

class _SellerFoodCard extends StatelessWidget {
  const _SellerFoodCard({required this.store, required this.food});

  final SellerStore store;
  final SellerFood food;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: !isDirectImageUrl(food.imageUrl)
                      ? const ColoredBox(
                          color: Color(0xFFFFE6DC),
                          child: Icon(Icons.fastfood, color: _sellerOrange),
                        )
                      : Image.network(
                          food.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFFFE6DC),
                            child: Icon(Icons.fastfood, color: _sellerOrange),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (food.isDraft)
                          const _StatusChip(status: 'Draft')
                        else
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: food.available ? _sellerGreen : _sellerRed,
                          ),
                      ],
                    ),
                    Text(
                      '${food.category} · ${food.vegetarian ? 'Vegetarian' : 'Non-vegetarian'}',
                      style: const TextStyle(color: _sellerMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      food.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_money(food.price)} · ${food.rating.toStringAsFixed(1)} ★ · ${food.popularity} orders',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(food.available ? 'Available' : 'Unavailable'),
                  value: food.available,
                  activeThumbColor: _sellerGreen,
                  onChanged: food.isDraft
                      ? null
                      : (value) =>
                            store.setFoodAvailability(food.foodId, value),
                ),
              ),
              IconButton(
                tooltip: 'Edit item',
                onPressed: () => _sellerOpen(
                  context,
                  SellerFoodFormScreen(store: store, food: food),
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete item',
                onPressed: () => _deleteFood(context, store, food),
                icon: const Icon(Icons.delete_outline, color: _sellerRed),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> _deleteFood(
  BuildContext context,
  SellerStore store,
  SellerFood food,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete menu item?'),
      content: Text(
        '“${food.name}” will be removed from this restaurant menu.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _sellerRed),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) store.deleteFood(food.foodId);
}

class SellerFoodFormScreen extends StatefulWidget {
  const SellerFoodFormScreen({required this.store, super.key, this.food});

  final SellerStore store;
  final SellerFood? food;

  @override
  State<SellerFoodFormScreen> createState() => _SellerFoodFormScreenState();
}

class _SellerFoodFormScreenState extends State<SellerFoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.food?.name ?? '');
  late final _description = TextEditingController(
    text: widget.food?.description ?? '',
  );
  late final _image = TextEditingController(text: widget.food?.imageUrl ?? '');
  late final _price = TextEditingController(
    text: widget.food == null ? '' : '${widget.food!.price}',
  );
  late final _discount = TextEditingController(
    text: widget.food?.discountedPrice?.toString() ?? '',
  );
  late final _prep = TextEditingController(
    text: '${widget.food?.preparationTime ?? 20}',
  );
  late final _stock = TextEditingController(
    text: '${widget.food?.stock ?? 20}',
  );
  late String _category =
      widget.food?.category ?? widget.store.categories.first;
  late bool _available = widget.food?.available ?? true;
  late bool _vegetarian = widget.food?.vegetarian ?? true;
  late bool _bestseller = widget.food?.bestseller ?? false;
  late bool _featured = widget.food?.featured ?? false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _image.dispose();
    _price.dispose();
    _discount.dispose();
    _prep.dispose();
    _stock.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value?.trim().isNotEmpty == true ? null : 'Required field.';

  String? _validateImageUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || isDirectImageUrl(trimmed)) return null;
    return 'Use a direct http(s) image link, not a Google Images result page.';
  }

  void _save({required bool draft}) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final price = int.tryParse(_price.text);
    final prep = int.tryParse(_prep.text);
    final stock = int.tryParse(_stock.text);
    final discount = _discount.text.trim().isEmpty
        ? null
        : int.tryParse(_discount.text);
    if (price == null ||
        price <= 0 ||
        prep == null ||
        prep <= 0 ||
        stock == null ||
        stock < 0) {
      _sellerMessage(
        context,
        'Enter a valid price, prep time and stock quantity.',
      );
      return;
    }
    if (discount != null && (discount <= 0 || discount >= price)) {
      _sellerMessage(
        context,
        'Discounted price must be less than the regular price.',
      );
      return;
    }
    widget.store.saveFood(
      foodId: widget.food?.foodId,
      name: _name.text.trim(),
      description: _description.text.trim(),
      imageUrl: _image.text.trim(),
      price: price,
      discountedPrice: discount,
      category: _category,
      preparationTime: prep,
      available: _available && stock > 0 && !draft,
      vegetarian: _vegetarian,
      bestseller: _bestseller,
      featured: _featured,
      stock: stock,
      isDraft: draft,
    );
    _sellerMessage(
      context,
      draft ? 'Draft saved in this session.' : 'Menu item published.',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.food == null ? 'Add new food' : 'Edit food'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Food name'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _image,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Image URL (Firebase Storage ready)',
              helperText:
                  'Use a direct image link, not a Google Images result page.',
              prefixIcon: Icon(Icons.image_outlined),
            ),
            validator: _validateImageUrl,
          ),
          if (_image.text.trim().isNotEmpty &&
              isDirectImageUrl(_image.text.trim()))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 160,
                  child: Image.network(
                    _image.text.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFFFE6DC),
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final category in widget.store.categories)
                DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price (₹)'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _discount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Discounted price (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _prep,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Preparation time (minutes)',
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _stock,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stock quantity'),
            validator: _required,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Available for ordering'),
            value: _available,
            onChanged: (value) => setState(() => _available = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vegetarian'),
            value: _vegetarian,
            onChanged: (value) => setState(() => _vegetarian = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bestseller'),
            value: _bestseller,
            onChanged: (value) => setState(() => _bestseller = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Featured item'),
            value: _featured,
            onChanged: (value) => setState(() => _featured = value),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _sellerMessage(
              context,
              'Customization, ingredients and allergen fields will sync after backend integration.',
            ),
            icon: const Icon(Icons.tune),
            label: const Text('Customization, ingredients & allergens'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _save(draft: true),
                  child: const Text('Save as draft'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _sellerOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _save(draft: false),
                  child: Text(
                    widget.food == null ? 'Publish item' : 'Save changes',
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

class SellerInventoryScreen extends StatefulWidget {
  const SellerInventoryScreen({required this.store, super.key});

  final SellerStore store;

  @override
  State<SellerInventoryScreen> createState() => _SellerInventoryScreenState();
}

class _SellerInventoryScreenState extends State<SellerInventoryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _updateStock(SellerFood food) async {
    final controller = TextEditingController(text: '${food.stock}');
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${food.name} stock'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Portions in stock'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final value = int.tryParse(controller.text);
    controller.dispose();
    if (save != true || value == null || !mounted) return;
    if (value < 0) {
      _sellerMessage(context, 'Stock cannot be negative.');
      return;
    }
    widget.store.updateStock(food.foodId, value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inventory')),
    body: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final foods = widget.store.restaurantFoods.where(
          (food) =>
              food.name.toLowerCase().contains(_search.text.toLowerCase()),
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search food items',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            const _InfoPanel(
              icon: Icons.sync_alt,
              text:
                  'Availability and stock are synced to Firestore and reflected in the customer catalog.',
            ),
            const SizedBox(height: 10),
            for (final food in foods)
              Card(
                child: ListTile(
                  title: Text(food.name),
                  subtitle: Text(
                    food.stock == 0
                        ? 'Out of stock'
                        : food.stock <= 5
                        ? 'Low stock · ${food.stock} portions'
                        : '${food.stock} portions available',
                    style: TextStyle(
                      color: food.stock <= 5 ? _sellerRed : _sellerMuted,
                    ),
                  ),
                  leading: Icon(
                    food.stock == 0
                        ? Icons.error_outline
                        : Icons.inventory_2_outlined,
                    color: food.stock <= 5 ? _sellerRed : _sellerTeal,
                  ),
                  trailing: IconButton(
                    tooltip: 'Update stock',
                    onPressed: () => _updateStock(food),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  onTap: () => widget.store.setFoodAvailability(
                    food.foodId,
                    !food.available,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class SellerCategoriesScreen extends StatelessWidget {
  const SellerCategoriesScreen({required this.store, super.key});

  final SellerStore store;

  Future<void> _edit(BuildContext context, {String? existing}) async {
    final controller = TextEditingController(text: existing ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add category' : 'Edit category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    store.saveCategory(existing, name);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Menu categories'),
      actions: [
        IconButton(
          tooltip: 'Add category',
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoPanel(
            icon: Icons.category_outlined,
            text:
                'Categories organize this restaurant’s menu. Items in a removed category are moved to the first available category.',
          ),
          const SizedBox(height: 12),
          for (final category in store.categories)
            Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant_menu, color: _sellerTeal),
                title: Text(category),
                trailing: Wrap(
                  children: [
                    IconButton(
                      onPressed: () => _edit(context, existing: category),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: store.categories.length <= 1
                          ? null
                          : () => _confirmDelete(context, category),
                      icon: const Icon(Icons.delete_outline, color: _sellerRed),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _confirmDelete(BuildContext context, String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Menu items in $category will be reassigned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) store.deleteCategory(category);
  }
}

class SellerAnalyticsTab extends StatefulWidget {
  const SellerAnalyticsTab({required this.store, super.key});

  final SellerStore store;

  @override
  State<SellerAnalyticsTab> createState() => _SellerAnalyticsTabState();
}

class _SellerAnalyticsTabState extends State<SellerAnalyticsTab> {
  String _range = 'Last 7 days';
  DateTimeRange? _customRange;

  Future<void> _selectRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _customRange,
    );
    if (range == null) return;
    setState(() {
      _range = 'Custom range';
      _customRange = range;
    });
  }

  void _exportSummary() {
    final store = widget.store;
    final orders = _ordersForRange();
    final completed = orders
        .where(
          (order) =>
              order.orderStatus == 'Completed' ||
              order.orderStatus == 'Delivered',
        )
        .toList();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report summary'),
        content: SelectableText(
          'Restaurant: ${store.restaurant.name}\n'
          'Period: $_range\n'
          'Orders: ${orders.length}\n'
          'Completed: ${completed.length}\n'
          'Revenue: ${_money(completed.fold(0, (total, order) => total + order.totalAmount))}\n'
          'Average order value: ${_money(_averageOrderValue(orders))}\n\n'
          'This summary reflects orders synced from Firestore. File download is not connected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  List<SellerOrder> _ordersForRange() {
    final now = DateTime.now();
    late final DateTime start;
    late final DateTime end;
    if (_range == 'Today') {
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
    } else if (_range == 'Last 30 days') {
      end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      start = end.subtract(const Duration(days: 30));
    } else if (_customRange != null) {
      start = DateTime(
        _customRange!.start.year,
        _customRange!.start.month,
        _customRange!.start.day,
      );
      end = DateTime(
        _customRange!.end.year,
        _customRange!.end.month,
        _customRange!.end.day,
      ).add(const Duration(days: 1));
    } else {
      end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      start = end.subtract(const Duration(days: 7));
    }
    return widget.store.restaurantOrders
        .where(
          (order) =>
              !order.createdAt.isBefore(start) && order.createdAt.isBefore(end),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final rangeOrders = _ordersForRange();
    final completed = rangeOrders
        .where(
          (order) =>
              order.orderStatus == 'Completed' ||
              order.orderStatus == 'Delivered',
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Analytics',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: 'Export report summary',
              onPressed: _exportSummary,
              icon: const Icon(Icons.download_outlined),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final range in ['Today', 'Last 7 days', 'Last 30 days'])
              ChoiceChip(
                label: Text(range),
                selected: _range == range,
                onSelected: (_) => setState(() {
                  _range = range;
                  _customRange = null;
                }),
              ),
            ActionChip(
              avatar: const Icon(Icons.date_range, size: 18),
              label: Text(
                _customRange == null ? 'Custom dates' : 'Custom range',
              ),
              onPressed: _selectRange,
            ),
          ],
        ),
        if (_customRange != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_shortDate(_customRange!.start)} – ${_shortDate(_customRange!.end)}',
              style: const TextStyle(color: _sellerMuted),
            ),
          ),
        const SizedBox(height: 14),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 640 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.65,
              children: [
                _MetricCard(
                  title: 'Revenue',
                  value: _money(
                    completed.fold(0, (sum, order) => sum + order.totalAmount),
                  ),
                  icon: Icons.payments_outlined,
                  color: _sellerGreen,
                ),
                _MetricCard(
                  title: 'Total orders',
                  value: '${rangeOrders.length}',
                  icon: Icons.receipt_long,
                  color: _sellerTeal,
                ),
                _MetricCard(
                  title: 'Average order value',
                  value: _money(_averageOrderValue(rangeOrders)),
                  icon: Icons.shopping_bag_outlined,
                  color: _sellerOrange,
                ),
                _MetricCard(
                  title: 'Completed',
                  value: '${completed.length}',
                  icon: Icons.task_alt,
                  color: _sellerGreen,
                ),
                _MetricCard(
                  title: 'Rejected',
                  value:
                      '${rangeOrders.where((order) => order.orderStatus == 'Rejected').length}',
                  icon: Icons.block_outlined,
                  color: _sellerRed,
                ),
                _MetricCard(
                  title: 'Restaurant rating',
                  value: widget.store.restaurantReviews.isEmpty
                      ? 'No reviews'
                      : '${widget.store.averageRating.toStringAsFixed(1)} ★',
                  icon: Icons.star_outline,
                  color: Color(0xFFE6A32E),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _SellerChart(
          title: 'Revenue · last 7 days',
          values: _dailyTrend(widget.store, revenue: true),
          labels: _lastSevenDayLabels(DateTime.now()),
          color: _sellerOrange,
        ),
        const SizedBox(height: 14),
        _SellerChart(
          title: 'Orders · last 7 days',
          values: _dailyTrend(widget.store),
          labels: _lastSevenDayLabels(DateTime.now()),
          color: _sellerTeal,
        ),
        const SizedBox(height: 16),
        Text(
          'Popular food items',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        for (final food
            in widget.store.restaurantFoods.toList()..sort(
              (a, b) => _orderedQuantity(
                widget.store,
                b.foodId,
              ).compareTo(_orderedQuantity(widget.store, a.foodId)),
            ))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE5F3EC),
              child: Icon(Icons.restaurant, color: _sellerTeal),
            ),
            title: Text(food.name),
            subtitle: Text(
              '${_orderedQuantity(widget.store, food.foodId)} portions ordered',
            ),
            trailing: Text(_money(food.price)),
          ),
      ],
    );
  }
}

List<double> _dailyTrend(SellerStore store, {bool revenue = false}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final firstDay = today.subtract(const Duration(days: 6));
  final values = List<double>.filled(7, 0);
  for (final order in store.restaurantOrders) {
    final orderDay = DateTime(
      order.createdAt.year,
      order.createdAt.month,
      order.createdAt.day,
    );
    final index = orderDay.difference(firstDay).inDays;
    if (index < 0 ||
        index >= values.length ||
        (revenue &&
            order.orderStatus != 'Completed' &&
            order.orderStatus != 'Delivered')) {
      continue;
    }
    values[index] += revenue ? order.totalAmount.toDouble() : 1;
  }
  final maximum = values.fold<double>(0, (current, value) {
    return value > current ? value : current;
  });
  if (maximum == 0) return values;
  return values.map((value) => value / maximum).toList();
}

List<String> _lastSevenDayLabels(DateTime now) {
  const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(7, (index) {
    final date = today.subtract(Duration(days: 6 - index));
    return weekdays[date.weekday - 1];
  });
}

int _orderedQuantity(SellerStore store, String foodId) =>
    store.restaurantOrders.fold(
      0,
      (total, order) =>
          total +
          order.items.fold(
            0,
            (quantity, item) =>
                quantity + (item.foodId == foodId ? item.quantity : 0),
          ),
    );

int _averageOrderValue(List<SellerOrder> orders) {
  if (orders.isEmpty) return 0;
  return orders.fold(0, (sum, order) => sum + order.totalAmount) ~/
      orders.length;
}

class SellerOffersScreen extends StatelessWidget {
  const SellerOffersScreen({required this.store, super.key});

  final SellerStore store;

  Future<void> _createOffer(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final description = TextEditingController();
    final value = TextEditingController();
    final minimum = TextEditingController(text: '199');
    final maxDiscount = TextEditingController(text: '100');
    var type = 'Percentage';
    var startsAt = DateTime.now();
    var expiresAt = DateTime.now().add(const Duration(days: 30));
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create offer'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Offer name'),
                    validator: (text) =>
                        text?.trim().isNotEmpty == true ? null : 'Required',
                  ),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (text) =>
                        text?.trim().isNotEmpty == true ? null : 'Required',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Offer type'),
                    items: [
                      for (final item in [
                        'Percentage',
                        'Fixed Amount',
                        'Buy One Get One',
                        'Combo',
                        'First Order',
                      ])
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: (selected) {
                      if (selected != null) {
                        setDialogState(() => type = selected);
                      }
                    },
                  ),
                  TextFormField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount value',
                    ),
                    validator: (text) {
                      final parsed = int.tryParse(text ?? '');
                      return parsed != null && parsed > 0
                          ? null
                          : 'Enter a positive number';
                    },
                  ),
                  TextFormField(
                    controller: minimum,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimum order (₹)',
                    ),
                    validator: (text) {
                      final parsed = int.tryParse(text ?? '');
                      return parsed != null && parsed >= 0
                          ? null
                          : 'Enter a valid amount';
                    },
                  ),
                  TextFormField(
                    controller: maxDiscount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Maximum discount (₹)',
                    ),
                    validator: (text) {
                      final parsed = int.tryParse(text ?? '');
                      return parsed != null && parsed >= 0
                          ? null
                          : 'Enter a valid amount';
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Starts: ${_shortDate(startsAt)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            initialDate: startsAt,
                          );
                          if (selected != null) {
                            setDialogState(() => startsAt = selected);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Expires: ${_shortDate(expiresAt)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            firstDate: startsAt,
                            lastDate: DateTime.now().add(
                              const Duration(days: 730),
                            ),
                            initialDate: expiresAt.isBefore(startsAt)
                                ? startsAt
                                : expiresAt,
                          );
                          if (selected != null) {
                            setDialogState(() => expiresAt = selected);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                formKey.currentState?.validate() ?? false,
              ),
              child: const Text('Create offer'),
            ),
          ],
        ),
      ),
    );
    final discountValue = int.tryParse(value.text);
    final minOrder = int.tryParse(minimum.text) ?? 0;
    final cap = int.tryParse(maxDiscount.text) ?? 0;
    if (created == true && expiresAt.isBefore(startsAt) && context.mounted) {
      _sellerMessage(context, 'Expiry date cannot be before the start date.');
    } else if (created == true && discountValue != null && context.mounted) {
      store.addOffer(
        name: name.text.trim(),
        description: description.text.trim(),
        type: type,
        value: discountValue,
        minimumOrder: minOrder,
        maximumDiscount: cap,
        startsAt: startsAt,
        expiresAt: expiresAt,
      );
      _sellerMessage(context, 'Offer campaign created.');
    }
    name.dispose();
    description.dispose();
    value.dispose();
    minimum.dispose();
    maxDiscount.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Offers & discounts'),
      actions: [
        IconButton(
          tooltip: 'Create offer',
          onPressed: () => _createOffer(context),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              _StatusChip(
                status:
                    'Active ${store.restaurantOffers.where((offer) => offer.status == 'Active').length}',
              ),
              _StatusChip(
                status:
                    'Scheduled ${store.restaurantOffers.where((offer) => offer.status == 'Scheduled').length}',
              ),
              _StatusChip(
                status:
                    'Expired ${store.restaurantOffers.where((offer) => offer.status == 'Expired').length}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final offer in store.restaurantOffers)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _StatusChip(status: offer.status),
                      ],
                    ),
                    Text(offer.description),
                    const SizedBox(height: 6),
                    Text(
                      '${offer.type} · ${offer.value} · Min ${_money(offer.minimumOrder)} · Max ${_money(offer.maximumDiscount)}',
                    ),
                    Text(
                      '${_shortDate(offer.startsAt)} – ${_shortDate(offer.expiresAt)}',
                      style: const TextStyle(color: _sellerMuted),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: offer.active,
                      onChanged: (_) => store.toggleOffer(offer.offerId),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _createOffer(context),
      backgroundColor: _sellerOrange,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('New offer'),
    ),
  );
}

class SellerReviewsScreen extends StatelessWidget {
  const SellerReviewsScreen({required this.store, super.key});

  final SellerStore store;

  Future<void> _respond(BuildContext context, SellerReview review) async {
    final controller = TextEditingController(text: review.response ?? '');
    final response = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to review'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Your response'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save response'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (response?.isNotEmpty == true) {
      store.respondToReview(review.reviewId, response!);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Customer reviews')),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final reviews = store.restaurantReviews;
        final average = reviews.isEmpty
            ? 0.0
            : reviews.fold<double>(0, (sum, review) => sum + review.rating) /
                  reviews.length;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xFFFFF0D8),
              child: ListTile(
                leading: const Icon(
                  Icons.star,
                  color: Color(0xFFE6A32E),
                  size: 34,
                ),
                title: Text(
                  '${average.toStringAsFixed(1)} / 5',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text('${reviews.length} customer reviews'),
              ),
            ),
            const SizedBox(height: 8),
            for (final review in reviews)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text('${review.rating.toStringAsFixed(1)} ★'),
                        ],
                      ),
                      Text(
                        '${review.foodName} · ${_shortDate(review.createdAt)}',
                      ),
                      const SizedBox(height: 8),
                      Text(review.review),
                      if (review.response != null) ...[
                        const Divider(),
                        Text('Your response: ${review.response}'),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _respond(context, review),
                          icon: const Icon(Icons.reply),
                          label: Text(
                            review.response == null
                                ? 'Respond'
                                : 'Edit response',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const _InfoPanel(
              icon: Icons.lock_outline,
              text:
                  'Customer reviews are read-only. You can reply, but cannot edit or delete a review.',
            ),
          ],
        );
      },
    ),
  );
}

class SellerProfileTab extends StatelessWidget {
  const SellerProfileTab({required this.store, this.onSignOut, super.key});

  final SellerStore store;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      children: [
        Text(
          'Restaurant profile',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFFFE6DC),
                  child: Icon(Icons.storefront, color: _sellerOrange, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.restaurant.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(store.account.ownerName),
                      const SizedBox(height: 5),
                      _StatusChip(status: store.account.verificationStatus),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ProfileMenuItem(
          icon: Icons.store_mall_directory_outlined,
          title: 'Restaurant details',
          subtitle: 'Name, address, contact and cuisine',
          onTap: () =>
              _sellerOpen(context, SellerRestaurantProfileScreen(store: store)),
        ),
        _ProfileMenuItem(
          icon: Icons.schedule_outlined,
          title: 'Business hours',
          subtitle:
              '${store.restaurant.openingTime} – ${store.restaurant.closingTime}',
          onTap: () =>
              _sellerOpen(context, SellerBusinessHoursScreen(store: store)),
        ),
        _ProfileMenuItem(
          icon: Icons.inventory_2_outlined,
          title: 'Inventory',
          subtitle: 'Availability and stock levels',
          onTap: () =>
              _sellerOpen(context, SellerInventoryScreen(store: store)),
        ),
        _ProfileMenuItem(
          icon: Icons.category_outlined,
          title: 'Menu categories',
          subtitle: 'Organize your menu',
          onTap: () =>
              _sellerOpen(context, SellerCategoriesScreen(store: store)),
        ),
        _ProfileMenuItem(
          icon: Icons.local_offer_outlined,
          title: 'Offers and discounts',
          subtitle: 'Promotional campaigns',
          onTap: () => _sellerOpen(context, SellerOffersScreen(store: store)),
        ),
        _ProfileMenuItem(
          icon: Icons.reviews_outlined,
          title: 'Customer reviews',
          subtitle: 'Ratings and responses',
          onTap: () => _sellerOpen(context, SellerReviewsScreen(store: store)),
        ),
        _ProfileMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: '${store.unreadNotifications} unread',
          onTap: () =>
              _sellerOpen(context, SellerNotificationsScreen(store: store)),
        ),
        _ProfileMenuItem(
          icon: Icons.settings_outlined,
          title: 'Seller settings',
          subtitle: 'Account, notifications and support',
          onTap: () => _sellerOpen(
            context,
            SellerSettingsScreen(store: store, onSignOut: onSignOut),
          ),
        ),
      ],
    ),
  );
}

class SellerRestaurantProfileScreen extends StatefulWidget {
  const SellerRestaurantProfileScreen({required this.store, super.key});

  final SellerStore store;

  @override
  State<SellerRestaurantProfileScreen> createState() =>
      _SellerRestaurantProfileScreenState();
}

class _SellerRestaurantProfileScreenState
    extends State<SellerRestaurantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.store.restaurant.name);
  late final _description = TextEditingController(
    text: widget.store.restaurant.description,
  );
  late final _address = TextEditingController(
    text: widget.store.restaurant.address,
  );
  late final _cuisine = TextEditingController(
    text: widget.store.restaurant.cuisine,
  );
  late final _phone = TextEditingController(text: widget.store.account.phone);
  late final _email = TextEditingController(text: widget.store.account.email);

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _cuisine.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Restaurant details')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          OutlinedButton.icon(
            onPressed: () => _sellerMessage(
              context,
              'Image storage is not connected in this demo.',
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Update restaurant logo / cover'),
          ),
          const SizedBox(height: 12),
          for (final field in [
            _textField(_name, 'Restaurant name', validator: _requiredSeller),
            _textField(
              _description,
              'Description',
              validator: _requiredSeller,
              maxLines: 3,
            ),
            _textField(
              _phone,
              'Contact phone',
              keyboard: TextInputType.phone,
              validator: _requiredSeller,
            ),
            _textField(
              _email,
              'Contact email',
              keyboard: TextInputType.emailAddress,
              validator: _requiredSeller,
            ),
            _textField(
              _address,
              'Restaurant address',
              validator: _requiredSeller,
              maxLines: 2,
            ),
            _textField(_cuisine, 'Cuisine', validator: _requiredSeller),
          ]) ...[field, const SizedBox(height: 12)],
          const _InfoPanel(
            icon: Icons.verified_user_outlined,
            text:
                'Verification details and documents are not collected or stored. Add a secure verification workflow before requiring them.',
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Save restaurant profile',
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              widget.store.saveRestaurant(
                name: _name.text.trim(),
                description: _description.text.trim(),
                address: _address.text.trim(),
                cuisine: _cuisine.text.trim(),
                phone: _phone.text.trim(),
                email: _email.text.trim(),
              );
              _sellerMessage(context, 'Restaurant profile updated.');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class SellerBusinessHoursScreen extends StatefulWidget {
  const SellerBusinessHoursScreen({required this.store, super.key});

  final SellerStore store;

  @override
  State<SellerBusinessHoursScreen> createState() =>
      _SellerBusinessHoursScreenState();
}

class _SellerBusinessHoursScreenState extends State<SellerBusinessHoursScreen> {
  late String _opening = widget.store.restaurant.openingTime;
  late String _closing = widget.store.restaurant.closingTime;
  late bool _isOpen = widget.store.restaurant.isOpen;
  late final Set<String> _workingDays = {...widget.store.workingDays};
  late final List<DateTime> _closures = [...widget.store.scheduledClosures];

  Future<String?> _pickTime(String current) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.contains('PM') ? 18 : 10, minute: 0),
    );
    if (time == null || !mounted) return null;
    return time.format(context);
  }

  Future<void> _addClosure() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (date != null) setState(() => _closures.add(date));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Business hours')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: SwitchListTile(
            title: Text(
              _isOpen ? 'Restaurant is open' : 'Restaurant is closed',
            ),
            subtitle: const Text('Temporarily stop accepting new orders'),
            value: _isOpen,
            activeThumbColor: _sellerGreen,
            onChanged: (value) => setState(() => _isOpen = value),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Opening time'),
          trailing: OutlinedButton(
            onPressed: () async {
              final time = await _pickTime(_opening);
              if (time != null) setState(() => _opening = time);
            },
            child: Text(_opening),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Closing time'),
          trailing: OutlinedButton(
            onPressed: () async {
              final time = await _pickTime(_closing);
              if (time != null) setState(() => _closing = time);
            },
            child: Text(_closing),
          ),
        ),
        const SizedBox(height: 10),
        Text('Working days', style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 6,
          children: [
            for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
              FilterChip(
                label: Text(day),
                selected: _workingDays.contains(day),
                onSelected: (value) => setState(
                  () =>
                      value ? _workingDays.add(day) : _workingDays.remove(day),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'Holidays & closures',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: _addClosure,
              tooltip: 'Schedule closure',
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        if (_closures.isEmpty)
          const Text(
            'No upcoming closures scheduled.',
            style: TextStyle(color: _sellerMuted),
          ),
        for (final date in _closures)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_busy_outlined),
            title: Text('Closed on ${_shortDate(date)}'),
            trailing: IconButton(
              onPressed: () => setState(() => _closures.remove(date)),
              icon: const Icon(Icons.close),
            ),
          ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Save business hours',
          onPressed: () {
            if (_workingDays.isEmpty) {
              _sellerMessage(context, 'Select at least one working day.');
              return;
            }
            widget.store.saveHours(
              _opening,
              _closing,
              open: _isOpen,
              days: _workingDays,
              closures: _closures,
            );
            _sellerMessage(context, 'Business hours saved.');
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

class SellerNotificationsScreen extends StatefulWidget {
  const SellerNotificationsScreen({required this.store, super.key});

  final SellerStore store;

  @override
  State<SellerNotificationsScreen> createState() =>
      _SellerNotificationsScreenState();
}

class _SellerNotificationsScreenState extends State<SellerNotificationsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        TextButton(
          onPressed: widget.store.markAllNotificationsRead,
          child: const Text('Mark all read'),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final categories = [
          'All',
          'New Orders',
          'Order Updates',
          'Customer Cancellations',
          'Reviews',
          'Inventory Alerts',
          'Restaurant Account Updates',
          'Promotional Updates',
        ];
        final notifications = widget.store.restaurantNotifications.where(
          (notification) => _filter == 'All' || notification.type == _filter,
        );
        return Column(
          children: [
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _filter == category,
                        onSelected: (_) => setState(() => _filter = category),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? const _EmptyState(
                      icon: Icons.notifications_none,
                      title: 'You’re all caught up',
                      message: 'New restaurant updates will show here.',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        for (final notification in notifications)
                          Card(
                            color: notification.isRead
                                ? null
                                : const Color(0xFFFFF0E9),
                            child: ListTile(
                              onTap: () {
                                widget.store.markNotificationRead(
                                  notification.notificationId,
                                );
                                final order = notification.orderId == null
                                    ? null
                                    : widget.store.orderById(
                                        notification.orderId!,
                                      );
                                if (order != null) {
                                  _sellerOpen(
                                    context,
                                    SellerOrderDetailScreen(
                                      store: widget.store,
                                      order: order,
                                    ),
                                  );
                                }
                              },
                              leading: Icon(
                                _notificationIcon(notification.type),
                                color: _sellerTeal,
                              ),
                              title: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${notification.message}\n${_shortDate(notification.createdAt)} · ${TimeOfDay.fromDateTime(notification.createdAt).format(context)}',
                              ),
                              isThreeLine: true,
                              trailing: notification.isRead
                                  ? null
                                  : const Icon(
                                      Icons.circle,
                                      size: 9,
                                      color: _sellerOrange,
                                    ),
                            ),
                          ),
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _InfoPanel(
                icon: Icons.cloud_outlined,
                text:
                    'In-app order notifications are synced with Firestore. Push notifications require Firebase Cloud Messaging setup.',
              ),
            ),
          ],
        );
      },
    ),
  );
}

IconData _notificationIcon(String type) => switch (type) {
  'New Orders' => Icons.receipt_long,
  'Order Updates' => Icons.local_shipping_outlined,
  'Customer Cancellations' => Icons.cancel_outlined,
  'Reviews' => Icons.star_outline,
  'Inventory Alerts' => Icons.inventory_2_outlined,
  'Promotional Updates' => Icons.campaign_outlined,
  _ => Icons.storefront_outlined,
};

class SellerSettingsScreen extends StatefulWidget {
  const SellerSettingsScreen({required this.store, this.onSignOut, super.key});

  final SellerStore store;
  final Future<void> Function()? onSignOut;

  @override
  State<SellerSettingsScreen> createState() => _SellerSettingsScreenState();
}

class _SellerSettingsScreenState extends State<SellerSettingsScreen> {
  bool _signingOut = false;

  Future<void> _changePassword(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: _requiredSeller,
              ),
              TextFormField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (value) => (value?.length ?? 0) >= 6
                    ? null
                    : 'Use at least 6 characters.',
              ),
              TextFormField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (value) =>
                    value == next.text ? null : 'Passwords do not match.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              formKey.currentState?.validate() ?? false,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
    confirm.dispose();
    if (saved == true && context.mounted) {
      _sellerMessage(
        context,
        'Password change requires connected authentication.',
      );
    }
  }

  Future<void> _showInfo(BuildContext context, String title, String content) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );

  Future<void> _logout() async {
    if (_signingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Return to the Crave seller login screen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _signingOut = true);
      try {
        final signOut = widget.onSignOut;
        if (signOut != null) {
          await signOut();
        } else {
          _sellerOpen(context, const SellerLoginScreen(), replace: true);
        }
      } on FirebaseAuthException catch (error) {
        if (mounted) _sellerMessage(context, error.message ?? error.code);
      } on FirebaseException catch (error) {
        if (mounted) _sellerMessage(context, error.message ?? error.code);
      } finally {
        if (mounted) setState(() => _signingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Seller settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _ProfileMenuItem(
            icon: Icons.account_circle_outlined,
            title: 'Account settings',
            subtitle: widget.store.account.email,
            onTap: () => _sellerOpen(
              context,
              SellerRestaurantProfileScreen(store: widget.store),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            onTap: () => _changePassword(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.receipt_long_outlined),
            title: const Text('Order notifications'),
            value: widget.store.orderNotifications,
            onChanged: (value) =>
                widget.store.setNotificationPreference('orders', value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.reviews_outlined),
            title: const Text('Review notifications'),
            value: widget.store.reviewNotifications,
            onChanged: (value) =>
                widget.store.setNotificationPreference('reviews', value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.campaign_outlined),
            title: const Text('Promotional updates'),
            value: widget.store.promotionalNotifications,
            onChanged: (value) =>
                widget.store.setNotificationPreference('promotions', value),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy settings'),
            onTap: () => _showInfo(
              context,
              'Privacy settings',
              'Seller accounts, restaurant profiles, menus, orders, offers, and in-app notifications are stored in Firebase. Document uploads and push notifications are not configured.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help and support'),
            onTap: () => _showInfo(
              context,
              'Help and support',
              'For support, configure a verified Crave partner support contact when the backend is connected.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms and conditions'),
            onTap: () => _showInfo(
              context,
              'Terms and conditions',
              'Partner terms will be provided by Crave before production onboarding.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: _sellerRed),
            title: Text(_signingOut ? 'Logging out...' : 'Log out'),
            trailing: _signingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _signingOut ? null : _logout,
          ),
        ],
      ),
    ),
  );
}

Widget _textField(
  TextEditingController controller,
  String label, {
  String? Function(String?)? validator,
  TextInputType? keyboard,
  bool obscure = false,
  Widget? suffix,
  int maxLines = 1,
}) => TextFormField(
  controller: controller,
  keyboardType: keyboard,
  obscureText: obscure,
  maxLines: obscure ? 1 : maxLines,
  validator: validator,
  decoration: InputDecoration(labelText: label, suffixIcon: suffix),
);

String? _requiredSeller(String? value) =>
    value?.trim().isNotEmpty == true ? null : 'This field is required.';

class _SellerAppBar extends StatelessWidget {
  const _SellerAppBar({
    required this.title,
    required this.trailing,
    required this.onTrailing,
  });

  final String title;
  final Widget trailing;
  final VoidCallback onTrailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        IconButton(onPressed: onTrailing, icon: trailing),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _sellerInk,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _sellerMuted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final color =
        lower.contains('approved') ||
            lower.contains('complete') ||
            lower == 'delivered' ||
            lower.contains('active') ||
            lower == 'paid'
        ? _sellerGreen
        : lower.contains('reject') ||
              lower.contains('cancel') ||
              lower.contains('expired') ||
              lower == 'unavailable'
        ? _sellerRed
        : lower == 'new' ||
              lower.contains('pending') ||
              lower.contains('review') ||
              lower.contains('prepar')
        ? _sellerOrange
        : _sellerTeal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SellerChart extends StatelessWidget {
  const _SellerChart({
    required this.title,
    required this.values,
    required this.labels,
    required this.color,
  });

  final String title;
  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (values.every((value) => value <= 0))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No activity in this period yet.',
                style: TextStyle(color: _sellerMuted),
              ),
            )
          else
            SizedBox(
              height: 118,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < values.length; index++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: values[index].clamp(0.08, 1),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color.withValues(
                                        alpha: index == values.length - 1
                                            ? 1
                                            : 0.55,
                                      ),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              labels[index],
                              style: const TextStyle(
                                color: _sellerMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, color: _sellerTeal, size: 19),
    label: Text(label),
    onPressed: onTap,
    side: BorderSide.none,
    backgroundColor: Colors.white,
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3F1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _sellerTeal, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _sellerTeal, size: 44),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: _sellerMuted)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon, color: _sellerTeal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
