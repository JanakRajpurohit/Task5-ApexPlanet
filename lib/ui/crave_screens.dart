import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/food.dart';
import '../state/crave_store.dart';
import 'account_screens.dart';
import 'crave_widgets.dart';
import 'seller_screens.dart';

const _coral = Color(0xFFFF7043);
const _teal = Color(0xFF205E59);
const _ink = Color(0xFF292321);
const _muted = Color(0xFF77716D);

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void _openFood(BuildContext context, CraveStore store, Food food) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FoodDetailsScreen(store: store, food: food),
    ),
  );
}

void _openMain(BuildContext context, CraveStore store) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => MainShell(store: store)),
    (route) => false,
  );
}

void _showSearchFilters(BuildContext context, CraveStore store) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CategoryPicker(store: store),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.store, super.key});

  final CraveStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const CraveWordmark(),
              const SizedBox(height: 30),
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 96,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Good Food,\nGreat Mood!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Discover delicious meals delivered right to your doorstep.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 16),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Login',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LoginScreen(store: store),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Create an account',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SignupScreen(store: store),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.store, super.key});

  final CraveStore store;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = false;
  bool _passwordVisible = false;
  bool _loading = false;

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authService = widget.store.authService;
    if (authService == null) {
      _message(context, 'Firebase Authentication is not configured.');
      return;
    }
    setState(() => _loading = true);
    try {
      await authService.signInCustomer(
        email: _email.text,
        password: _password.text,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) _message(context, error.message ?? error.code);
    } on FirebaseException catch (error) {
      if (mounted) _message(context, error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _message(context, 'Enter your email address first.');
      return;
    }
    final authService = widget.store.authService;
    if (authService == null) {
      _message(context, 'Firebase Authentication is not configured.');
      return;
    }
    try {
      await authService.sendPasswordReset(email);
      if (mounted) _message(context, 'Password reset email sent.');
    } on FirebaseAuthException catch (error) {
      if (mounted) _message(context, error.message ?? error.code);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
              Text(
                'Welcome Back!',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              const Text('Login to continue your food journey.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _passwordVisible = !_passwordVisible;
                    }),
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) => (value?.isNotEmpty ?? false)
                    ? null
                    : 'Password cannot be empty.',
              ),
              Row(
                children: [
                  Checkbox(
                    value: _remember,
                    onChanged: (value) =>
                        setState(() => _remember = value ?? false),
                    activeColor: _coral,
                  ),
                  const Expanded(child: Text('Remember me')),
                  TextButton(
                    onPressed: _resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Login',
                onPressed: _loading ? null : _login,
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Are you a Restaurant Owner?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                label: 'Login as Restaurant Partner',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SellerLoginScreen(
                      onCustomerLogin: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SellerRegistrationScreen(),
                    ),
                  ),
                  child: const Text('Register Your Restaurant'),
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Continue with Google',
                onPressed: () => _message(
                  context,
                  'Google sign-in will be available when authentication is connected.',
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Wrap(
                  children: [
                    const Text('New to Crave? '),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SignupScreen(store: widget.store),
                        ),
                      ),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: _coral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({required this.store, super.key});

  final CraveStore store;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _acceptedTerms = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;

  Future<void> _createAccount() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!_acceptedTerms) {
      _message(context, 'Please accept the terms to continue.');
      return;
    }
    if (!valid) return;
    final authService = widget.store.authService;
    if (authService == null) {
      _message(context, 'Firebase Authentication is not configured.');
      return;
    }
    setState(() => _loading = true);
    try {
      await authService.createCustomerAccount(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
      );
      if (mounted) {
        widget.store.setProfile(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) _message(context, error.message ?? error.code);
    } on FirebaseException catch (error) {
      if (mounted) _message(context, error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
              const CraveWordmark(),
              const SizedBox(height: 24),
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              const Text('Join Crave and find your new favourite.'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value?.trim().isNotEmpty ?? false)
                    ? null
                    : 'Enter your full name.',
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) =>
                    RegExp(
                      r'^[+]?[0-9][0-9\s-]{7,14}$',
                    ).hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Enter a valid phone number.',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _password,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _passwordVisible = !_passwordVisible;
                    }),
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
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirm,
                obscureText: !_confirmVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _confirmVisible = !_confirmVisible;
                    }),
                    icon: Icon(
                      _confirmVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) =>
                    value == _password.text ? null : 'Passwords do not match.',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _coral,
                value: _acceptedTerms,
                onChanged: (value) =>
                    setState(() => _acceptedTerms = value ?? false),
                title: const Text('I agree to the Terms & Conditions'),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Create Account',
                onPressed: _loading ? null : _createAccount,
              ),
              const SizedBox(height: 18),
              Center(
                child: Wrap(
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: _coral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({required this.store, super.key, this.initialIndex = 0});

  final CraveStore store;
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  void selectTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeTab(store: widget.store, onSearch: () => selectTab(1)),
            SearchTab(store: widget.store),
            CartTab(store: widget.store),
            FavouritesTab(store: widget.store),
            ProfileTab(store: widget.store),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: selectTab,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: widget.store.cartItemCount > 0,
                label: Text('${widget.store.cartItemCount}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: widget.store.cartItemCount > 0,
                label: Text('${widget.store.cartItemCount}'),
                child: const Icon(Icons.shopping_bag),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favourites',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({required this.store, required this.onSearch, super.key});

  final CraveStore store;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final foods = store.category == 'All'
            ? store.foods.take(5).toList()
            : store.foods
                  .where((food) => food.category == store.category)
                  .toList();
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Good Evening!',
                          style: TextStyle(color: _muted),
                        ),
                        Text(
                          store.profileName.isEmpty
                              ? 'Welcome!'
                              : store.profileName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _message(context, 'You’re all caught up!'),
                    icon: const Icon(Icons.notifications_none, color: _teal),
                  ),
                  IconButton(
                    onPressed: () => context
                        .findAncestorStateOfType<_MainShellState>()
                        ?.selectTab(2),
                    icon: Badge(
                      isLabelVisible: store.cartItemCount > 0,
                      label: Text('${store.cartItemCount}'),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: _teal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (context) => LocationPicker(store: store),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _coral,
                      size: 19,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Delivering to ',
                      style: TextStyle(color: _muted),
                    ),
                    Text(
                      store.selectedAddress.city.isEmpty
                          ? 'Add address'
                          : store.selectedAddress.city,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: _muted),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: onSearch,
                borderRadius: BorderRadius.circular(16),
                child: IgnorePointer(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for burgers, pizza, fries...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: const Icon(Icons.tune, color: _coral),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (store.catalogLoading && store.foods.isEmpty)
                const LinearProgressIndicator(),
              if (store.catalogError != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline, color: _coral),
                    title: const Text('Could not load the menu'),
                    subtitle: Text(store.catalogError.toString()),
                    trailing: IconButton(
                      tooltip: 'Retry',
                      onPressed: store.startCatalog,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
              if (!store.catalogLoading &&
                  store.catalogError == null &&
                  store.foods.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'The menu is empty. Published dishes will appear here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
              _SectionHeading(
                title: 'Categories',
                action: 'See all',
                onTap: onSearch,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: store.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = store.categories[index];
                    return _CategoryChip(
                      label: category,
                      selected: category == store.category,
                      onTap: () {
                        store.setCategory(category);
                        store.setQuery('');
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeading(
                title: store.category == 'All'
                    ? 'Popular Food'
                    : store.category,
                action: 'See all',
                onTap: onSearch,
              ),
              const SizedBox(height: 12),
              for (final food in foods)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FoodCard(
                    store: store,
                    food: food,
                    onTap: () => _openFood(context, store, food),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SearchTab extends StatelessWidget {
  const SearchTab({required this.store, super.key});

  final CraveStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find your craving',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 5),
                  const Text('Fresh picks, just a search away.'),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('food-search'),
                    onChanged: store.setQuery,
                    onSubmitted: store.recordSearch,
                    decoration: InputDecoration(
                      hintText: 'Search for burgers, pizza, fries...',
                      prefixIcon: const Icon(Icons.search),
                      suffix: store.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () => store.setQuery(''),
                              icon: const Icon(Icons.close),
                            ),
                      suffixIcon: IconButton(
                        onPressed: () => _showSearchFilters(context, store),
                        icon: const Icon(Icons.tune, color: _coral),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Popular searches',
                    style: TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final item in store.recentSearches)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: const Icon(Icons.history, size: 16),
                              label: Text(item),
                              onPressed: () {
                                store.setCategory('All');
                                store.setQuery(item);
                              },
                            ),
                          ),
                        for (final item in store.categories.skip(1))
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CategoryChip(
                              label: item,
                              selected:
                                  store.query.toLowerCase() ==
                                  item.toLowerCase(),
                              onTap: () {
                                store.setCategory('All');
                                store.setQuery(item);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (store.recentSearches.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: store.clearRecentSearches,
                        child: const Text('Clear recent'),
                      ),
                    ),
                  const SizedBox(height: 18),
                  _SectionHeading(
                    title: store.query.isEmpty
                        ? 'Popular Food'
                        : 'Search results',
                  ),
                ],
              ),
            ),
            Expanded(
              child: store.filteredFoods.isEmpty
                  ? _EmptyState(
                      emoji: '🔎',
                      title: 'No dishes found',
                      description:
                          'Try another food or browse a different category.',
                      buttonLabel: 'Clear search',
                      onPressed: () {
                        store.setQuery('');
                        store.setCategory('All');
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        for (final food in store.filteredFoods)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: FoodCard(
                              store: store,
                              food: food,
                              onTap: () => _openFood(context, store, food),
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
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.store});

  final CraveStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Filter and sort',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'CATEGORY',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
              ),
            ),
            for (final category in store.categories)
              ListTile(
                dense: true,
                title: Text(category),
                trailing: store.category == category
                    ? const Icon(Icons.check_circle, color: _teal)
                    : null,
                onTap: () => store.setCategory(category),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'SORT BY',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
              ),
            ),
            RadioGroup<FoodSort>(
              groupValue: store.sort,
              onChanged: (value) {
                if (value != null) store.setSort(value);
              },
              child: Column(
                children: [
                  for (final sort in FoodSort.values)
                    RadioListTile<FoodSort>(
                      dense: true,
                      value: sort,
                      activeColor: _coral,
                      title: Text(switch (sort) {
                        FoodSort.popular => 'Popular',
                        FoodSort.priceLowToHigh => 'Price: Low to High',
                        FoodSort.priceHighToLow => 'Price: High to Low',
                        FoodSort.highestRated => 'Highest Rated',
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: PrimaryButton(
                label: 'Show ${store.filteredFoods.length} dishes',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartTab extends StatelessWidget {
  const CartTab({required this.store, super.key});

  final CraveStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'My Cart',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              const Text('The good stuff is almost yours.'),
              const SizedBox(height: 16),
              if (store.cartItems.isEmpty)
                Expanded(
                  child: _EmptyState(
                    emoji: '🛍️',
                    title: 'Your cart is hungry',
                    description:
                        'Add something delicious and it will show up here.',
                    buttonLabel: 'Explore food',
                    onPressed: () => context
                        .findAncestorStateOfType<_MainShellState>()
                        ?.selectTab(0),
                  ),
                )
              else ...[
                Expanded(
                  child: ListView(
                    children: [
                      for (final item in store.cartItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CartItemCard(store: store, item: item),
                        ),
                      _PriceSummary(store: store),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
                PrimaryButton(
                  label: 'Proceed to Checkout',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CheckoutScreen(store: store),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FavouritesTab extends StatelessWidget {
  const FavouritesTab({required this.store, super.key});

  final CraveStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your favourites',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              const Text('The dishes you love, all in one place.'),
              const SizedBox(height: 16),
              if (store.favouriteFoods.isEmpty)
                Expanded(
                  child: _EmptyState(
                    emoji: '♡',
                    title: 'No favourites yet',
                    description:
                        'Tap the heart on a dish to save it for later.',
                    buttonLabel: 'Explore food',
                    onPressed: () => context
                        .findAncestorStateOfType<_MainShellState>()
                        ?.selectTab(0),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      for (final food in store.favouriteFoods)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: FoodCard(
                            store: store,
                            food: food,
                            onTap: () => _openFood(context, store, food),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({required this.store, super.key});

  final CraveStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          children: [
            Text(
              'My Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5),
            const Text('Your Crave account at a glance.'),
            const SizedBox(height: 18),
            Card(
              color: Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  radius: 31,
                  backgroundColor: const Color(0xFFFFE4D9),
                  child: Text(
                    store.profileName.isEmpty
                        ? 'C'
                        : store.profileName[0].toUpperCase(),
                    style: const TextStyle(
                      color: _coral,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(store.profileName),
                subtitle: Text('${store.profileEmail}\n${store.profilePhone}'),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 14),
            _ProfileOption(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your name and phone number',
              onTap: () => _editProfile(context),
            ),
            _ProfileOption(
              icon: Icons.receipt_long,
              title: 'My Orders',
              subtitle: 'Check your recent orders',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => OrderHistoryScreen(store: store),
                ),
              ),
            ),
            _ProfileOption(
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              subtitle: 'Manage your delivery locations',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AddressBookScreen(store: store),
                ),
              ),
            ),
            _ProfileOption(
              icon: Icons.favorite_border,
              title: 'Favourite Foods',
              subtitle: 'Your saved dishes',
              onTap: () => context
                  .findAncestorStateOfType<_MainShellState>()
                  ?.selectTab(3),
            ),
            _ProfileOption(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Notifications and preferences',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(store: store),
                ),
              ),
            ),
            _ProfileOption(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: "We're here to help",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const HelpSupportScreen(),
                ),
              ),
            ),
            _ProfileOption(
              icon: Icons.info_outline,
              title: 'About Crave',
              subtitle: 'App information',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AboutCraveScreen(),
                ),
              ),
            ),
            _ProfileOption(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of this account',
              tint: _coral,
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text('You can sign in again any time.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        try {
                          await store.authService?.signOut();
                        } on FirebaseAuthException catch (error) {
                          if (context.mounted) {
                            _message(context, error.message ?? error.code);
                          }
                        }
                      },
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => EditProfileScreen(store: store)),
    );
  }
}

class FoodDetailsScreen extends StatefulWidget {
  const FoodDetailsScreen({required this.store, required this.food, super.key});

  final CraveStore store;
  final Food food;

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  int _quantity = 1;
  String _spice = 'Medium';
  final TextEditingController _instructions = TextEditingController();

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  List<String> get _customizations => [
    '$_spice spice',
    if (_instructions.text.trim().isNotEmpty)
      'Note: ${_instructions.text.trim()}',
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => Scaffold(
        body: Column(
          children: [
            Stack(
              children: [
                FoodImage(
                  food: widget.food,
                  height: 340,
                  width: double.infinity,
                  borderRadius: 0,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _RoundIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context),
                        ),
                        _RoundIconButton(
                          icon: widget.store.favourites.contains(widget.food.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              widget.store.favourites.contains(widget.food.id)
                              ? _coral
                              : _ink,
                          onTap: () =>
                              widget.store.toggleFavourite(widget.food.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Text(
                    widget.food.category.toUpperCase(),
                    style: const TextStyle(
                      color: _coral,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.food.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFB300),
                        size: 19,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.food.rating}  ·  ${widget.food.reviews} reviews',
                      ),
                      const Spacer(),
                      Icon(
                        widget.food.isVegetarian
                            ? Icons.eco_outlined
                            : Icons.lunch_dining_outlined,
                        color: widget.food.isVegetarian ? _teal : _coral,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.food.isVegetarian ? 'Veg' : 'Non-veg',
                        style: TextStyle(
                          color: widget.food.isVegetarian ? _teal : _coral,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.food.description,
                    style: const TextStyle(color: _muted, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: _teal, size: 19),
                      const SizedBox(width: 6),
                      Text(
                        'Ready in ${widget.food.preparationMinutes}–${widget.food.preparationMinutes + 5} minutes',
                        style: const TextStyle(
                          color: _teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (widget.food.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Ingredients',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.food.ingredients.join(' · '),
                      style: const TextStyle(color: _muted),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text(
                    'Spice level',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final spice in ['Mild', 'Medium', 'Hot'])
                        ChoiceChip(
                          label: Text(spice),
                          selected: _spice == spice,
                          onSelected: (_) => setState(() => _spice = spice),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _instructions,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Special instructions (optional)',
                      hintText: 'Anything else we should know?',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Quantity',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_quantity',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: _coral,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(color: _muted, fontSize: 11),
                          ),
                          Text(
                            '₹${widget.food.effectivePrice * _quantity}',
                            style: const TextStyle(
                              color: _teal,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        label: widget.food.isAvailable
                            ? 'Add to Cart'
                            : 'Currently unavailable',
                        onPressed: widget.food.isAvailable
                            ? () {
                                try {
                                  widget.store.addToCart(
                                    widget.food,
                                    quantity: _quantity,
                                    customizations: _customizations,
                                  );
                                } on StateError {
                                  _message(
                                    context,
                                    'This food item is currently unavailable.',
                                  );
                                  return;
                                }
                                _message(
                                  context,
                                  '${widget.food.name} added to cart',
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({required this.store, super.key});

  final CraveStore store;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _instructions = TextEditingController();
  bool _placingOrder = false;

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_placingOrder) return;
    setState(() => _placingOrder = true);
    try {
      final order = await widget.store.placeCashOnDeliveryOrder(
        instructions: _instructions.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OrderSuccessScreen(store: widget.store, order: order),
        ),
      );
    } on FirebaseException catch (error) {
      if (mounted) {
        _message(
          context,
          error.message ?? 'Could not place your order (${error.code}).',
        );
      }
    } on StateError catch (error) {
      if (mounted) _message(context, error.message);
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final allItemsAvailable = store.cartItems.every(
          (item) => item.food.isAvailable,
        );
        final hasAddress = store.selectedAddress.id.isNotEmpty;
        return Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: store.cartItems.isEmpty
              ? _EmptyState(
                  emoji: '🛍️',
                  title: 'Nothing to checkout',
                  description: 'Add food to your cart before placing an order.',
                  buttonLabel: 'Continue shopping',
                  onPressed: () => Navigator.pop(context),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          if (!allItemsAvailable)
                            const Card(
                              color: Color(0xFFFFE6DC),
                              child: ListTile(
                                leading: Icon(
                                  Icons.inventory_2_outlined,
                                  color: _coral,
                                ),
                                title: Text('An item is unavailable'),
                                subtitle: Text(
                                  'Remove unavailable items from your cart to continue.',
                                ),
                              ),
                            ),
                          _CheckoutHeading('Delivery address'),
                          Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: _coral,
                              ),
                              title: Text(
                                hasAddress
                                    ? store.selectedAddress.type
                                    : 'Add delivery address',
                              ),
                              subtitle: Text(
                                hasAddress
                                    ? '${store.selectedAddress.name} · ${store.selectedAddress.phone}\n${store.selectedAddress.fullAddress}'
                                    : 'A delivery address is required to place this order.',
                              ),
                              trailing: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => AddressBookScreen(
                                      store: store,
                                      selectOnTap: true,
                                    ),
                                  ),
                                ),
                                child: Text(hasAddress ? 'Change' : 'Add'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _CheckoutHeading('Delivery instructions'),
                          TextField(
                            controller: _instructions,
                            maxLines: 2,
                            onChanged: (value) =>
                                store.deliveryInstructions = value,
                            decoration: const InputDecoration(
                              hintText: 'Leave at the door, call on arrival...',
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _CheckoutHeading('Order summary'),
                          for (final item in store.cartItems)
                            Column(
                              children: [
                                _SummaryRow(
                                  label: '${item.food.name} × ${item.quantity}',
                                  amount: item.total,
                                ),
                                if (item.customizations.isNotEmpty)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8,
                                        right: 12,
                                      ),
                                      child: Text(
                                        item.customizations.join(' · '),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          const Divider(height: 24),
                          _SummaryRow(
                            label: 'Subtotal',
                            amount: store.cartSubtotal,
                          ),
                          _SummaryRow(
                            label: 'Total amount',
                            amount: store.cartTotal,
                            bold: true,
                          ),
                          const SizedBox(height: 18),
                          const Card(
                            child: ListTile(
                              leading: Icon(Icons.payments_outlined),
                              title: Text('Cash on Delivery'),
                              subtitle: Text(
                                'Pay the order total in cash when it is delivered.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                        child: PrimaryButton(
                          label: _placingOrder
                              ? 'Placing order...'
                              : !hasAddress
                              ? 'Add delivery address to continue'
                              : 'Place COD order · ₹${store.cartTotal}',
                          onPressed:
                              !allItemsAvailable || !hasAddress || _placingOrder
                              ? null
                              : _placeOrder,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    required this.store,
    required this.order,
    super.key,
  });

  final CraveStore store;
  final CraveOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2F2E9),
                        shape: BoxShape.circle,
                      ),
                      child: child,
                    ),
                  ),
                  child: const Icon(Icons.check, size: 68, color: _teal),
                ),
                const SizedBox(height: 24),
                Text(
                  'Order Placed\nSuccessfully!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                const Text('Your delicious food is on its way.'),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('ORDER ID', style: TextStyle(color: _muted)),
                        Text(
                          order.id,
                          style: const TextStyle(
                            color: _teal,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '${order.estimatedMinutes} min estimated delivery',
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${order.paymentMethod} · ₹${order.total}',
                          style: const TextStyle(color: _muted),
                        ),
                        if (order.deliveryAddress case final address?) ...[
                          const SizedBox(height: 7),
                          Text(
                            '${address.name} · ${address.phone}\n${address.fullAddress}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (order.deliveryInstructions.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Text(
                            'Note: ${order.deliveryInstructions}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 12),
                        for (final item in order.items)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${item.food.name} × ${item.quantity}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                PrimaryButton(
                  label: 'Track Order',
                  onPressed: () => _message(
                    context,
                    'Your order is being prepared. We’ll keep you updated!',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => OrderHistoryScreen(store: store),
                    ),
                  ),
                  child: const Text('View Order'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => _openMain(context, store),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoodCard extends StatelessWidget {
  const FoodCard({
    required this.store,
    required this.food,
    required this.onTap,
    super.key,
  });

  final CraveStore store;
  final Food food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  FoodImage(
                    food: food,
                    height: 170,
                    width: double.infinity,
                    borderRadius: 0,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: AnimatedScale(
                      scale: store.favourites.contains(food.id) ? 1.08 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: _RoundIconButton(
                        icon: store.favourites.contains(food.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: store.favourites.contains(food.id)
                            ? _coral
                            : _ink,
                        onTap: () {
                          store.toggleFavourite(food.id);
                          _message(
                            context,
                            store.favourites.contains(food.id)
                                ? 'Added to favourites'
                                : 'Removed from favourites',
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFB300),
                          size: 18,
                        ),
                        Text(
                          ' ${food.rating}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          ' (${food.reviews})',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      food.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '₹${food.effectivePrice}',
                          style: const TextStyle(
                            color: _teal,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: food.isAvailable
                              ? () {
                                  try {
                                    store.addToCart(food);
                                    _message(
                                      context,
                                      '${food.name} added to cart',
                                    );
                                  } on StateError catch (error) {
                                    _message(context, error.message);
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(food.isAvailable ? 'Add' : 'Unavailable'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _coral,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.store, required this.item});

  final CraveStore store;
  final CartLine item;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            FoodImage(food: item.food, width: 84, height: 84),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '₹${item.unitPrice} each',
                    style: const TextStyle(color: _muted),
                  ),
                  if (item.customizations.isNotEmpty)
                    Text(
                      item.customizations.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => store.changeQuantity(item.lineId, -1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => store.changeQuantity(item.lineId, 1),
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: _coral,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove item',
                  onPressed: () => store.removeFromCart(item.lineId),
                  icon: const Icon(Icons.delete_outline, color: _muted),
                ),
                Text(
                  '₹${item.total}',
                  style: const TextStyle(
                    color: _teal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.store});

  final CraveStore store;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Price Details',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 13),
            _SummaryRow(label: 'Subtotal', amount: store.cartSubtotal),
            const Divider(height: 20),
            _SummaryRow(
              label: 'Total amount',
              amount: store.cartTotal,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  final String label;
  final int amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? _ink : _muted,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '₹$amount',
            style: TextStyle(
              color: bold ? _teal : _ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String emoji;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: PrimaryButton(label: buttonLabel, onPressed: onPressed),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onTap});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(action!)),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _teal,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : _ink,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.color = _ink,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tint = _teal,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: tint),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: _muted),
      ),
    );
  }
}

class _CheckoutHeading extends StatelessWidget {
  const _CheckoutHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
