import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:photo_view/photo_view.dart';

import 'animal_malay_content.dart';
import 'platform/browser_photo_stub.dart'
    if (dart.library.html) 'platform/browser_photo_web.dart'
    as browser_photo;

const _forest = Color(0xFF28745B);
const _forestDark = Color(0xFF153E37);
const _accent = Color(0xFFF0B451);
const _canvas = Color(0xFFF7F4EC);
const _surface = Color(0xFFFFFEFA);
const _surfaceRaised = Color(0xFFF8F7F1);
const _textPrimary = Color(0xFF1D332E);
const _textMuted = Color(0xFF65756F);
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.100.17/BruneiGoOnlineApps/wildlife_api',
);

String? _animalPhotoUrl(String baseUrl, dynamic storedPath) {
  final path = storedPath?.toString().trim() ?? '';
  if (path.isEmpty) return null;
  final remote = Uri.tryParse(path);
  if (remote != null &&
      remote.hasAuthority &&
      (remote.scheme == 'https' || remote.scheme == 'http')) {
    return Uri.parse(
      '$baseUrl/animal_image.php',
    ).replace(queryParameters: {'url': path}).toString();
  }
  final fileName = path.replaceAll('\\', '/').split('/').last;
  if (fileName.isEmpty) return null;
  return Uri.parse(
    '$baseUrl/animal_image.php',
  ).replace(queryParameters: {'file': fileName}).toString();
}

Widget _buildMalayIntroduction(AnimalMalayContent content) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(15),
  decoration: BoxDecoration(
    color: const Color(0xFFF4F7F0),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFDCE8D8)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'PENGENALAN DALAM BAHASA MELAYU',
        style: TextStyle(
          color: _forest,
          fontSize: 10,
          letterSpacing: .7,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        content.commonName,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        content.introduction,
        style: const TextStyle(color: _textMuted, fontSize: 13, height: 1.55),
      ),
      const SizedBox(height: 10),
      Text(
        'Habitat: ${content.habitat}',
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Status pemuliharaan: ${content.conservationStatus}',
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
);

Widget _buildOnlineMalayIntroduction(String name, String introduction) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE8D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PENGENALAN DALAM BAHASA MELAYU',
            style: TextStyle(
              color: _forest,
              fontSize: 10,
              letterSpacing: .7,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            introduction,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 12,
              height: 1.55,
            ),
          ),
        ],
      ),
    );

class _BruneiPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('673') && digits.length >= 10)
      digits = digits.substring(3);
    if (digits.length > 7) digits = digits.substring(0, 7);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WildlifeApp());
}

class WildlifeApp extends StatelessWidget {
  const WildlifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _forest,
          brightness: Brightness.light,
        ).copyWith(
          primary: _forest,
          onPrimary: Colors.white,
          secondary: _accent,
          surface: _surface,
          onSurface: _textPrimary,
        );
    return MaterialApp(
      title: 'Brunei Go Online Apps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: _surface,
          foregroundColor: _textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 68,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceRaised,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD8E2D8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD8E2D8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _forest, width: 1.5),
          ),
          hintStyle: const TextStyle(color: _textMuted),
          labelStyle: const TextStyle(color: _textMuted),
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFDCE5DC)),
          ),
        ),
      ),
      home: const AppEntryGate(),
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  Map<String, dynamic>? _user;
  bool _guest = false;

  void _continueAsGuest() => setState(() {
    _user = null;
    _guest = true;
  });

  void _signOut() => setState(() {
    _user = null;
    _guest = false;
  });

  @override
  Widget build(BuildContext context) {
    if (_user == null && !_guest) {
      return AuthScreen(
        onAuthenticated: (user) => setState(() {
          _user = user;
          _guest = false;
        }),
        onGuest: _continueAsGuest,
      );
    }
    return HomePage(account: _user, isGuest: _guest, onSignOut: _signOut);
  }
}

class WildlifeBackdrop extends StatelessWidget {
  final Widget child;

  const WildlifeBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9EC), _canvas, Color(0xFFEAF2EC)],
          stops: [0, .52, 1],
        ),
      ),
      child: CustomPaint(painter: WildlifePatternPainter(), child: child),
    );
  }
}

class WildlifePatternPainter extends CustomPainter {
  const WildlifePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final warmGlow = Paint()..color = _accent.withValues(alpha: .055);
    final greenGlow = Paint()..color = _forest.withValues(alpha: .045);
    canvas.drawCircle(
      Offset(size.width * 1.02, size.height * .08),
      size.shortestSide * .24,
      warmGlow,
    );
    canvas.drawCircle(
      Offset(-size.width * .02, size.height * .96),
      size.shortestSide * .20,
      greenGlow,
    );
  }

  @override
  bool shouldRepaint(covariant WildlifePatternPainter oldDelegate) => false;
}

class AuthScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onAuthenticated;
  final VoidCallback onGuest;

  const AuthScreen({
    super.key,
    required this.onAuthenticated,
    required this.onGuest,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registering = false;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_apiBaseUrl/${_registering ? 'register' : 'login'}.php',
            ),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': _usernameController.text.trim(),
              if (_registering) 'contact': _contactController.text.trim(),
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['status'] != 'success') {
        throw Exception(
          data['message'] ?? 'Unable to continue. Please try again.',
        );
      }
      final user = Map<String, dynamic>.from(data['user'] as Map);
      widget.onAuthenticated(user);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      setState(
        () => _error =
            message.contains('SocketException') ||
                message.contains('TimeoutException')
            ? 'Could not reach the server. Check that XAMPP is running and the API address is correct.'
            : message,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (!RegExp(r'^[A-Za-z0-9_]{3,30}$').hasMatch(username)) {
      return 'Use 3–30 letters, numbers, or underscores';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = _registering ? 'Create your account' : 'Welcome back';
    return Scaffold(
      body: WildlifeBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: _forest,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.forest_rounded,
                                color: Colors.white,
                                size: 31,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Center(
                            child: Text(
                              'Brunei Go Online Apps',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Center(
                            child: Text(
                              _registering
                                  ? 'Join the community protecting Brunei wildlife.'
                                  : 'Sign in to report and protect local wildlife.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 27),
                          Text(
                            title,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 17),
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: _registering
                                ? TextInputAction.next
                                : TextInputAction.next,
                            textCapitalization: TextCapitalization.none,
                            autofillHints: const [AutofillHints.username],
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                              hintText: 'e.g. nature_lover',
                            ),
                            validator: _validateUsername,
                          ),
                          if (_registering) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _contactController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumberNational,
                              ],
                              inputFormatters: [_BruneiPhoneFormatter()],
                              decoration: const InputDecoration(
                                labelText: 'Contact number',
                                prefixText: '+673  ',
                                prefixIcon: Icon(Icons.phone_outlined),
                                hintText: '7123456',
                                helperText: '7 digits, starting with 7 or 8',
                              ),
                              validator: (value) =>
                                  RegExp(
                                    r'^[78]\d{6}$',
                                  ).hasMatch(value?.trim() ?? '')
                                  ? null
                                  : 'Enter a valid 7-digit Brunei number',
                            ),
                            const SizedBox(height: 14),
                          ] else
                            const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: [
                              _registering
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            onFieldSubmitted: (_) =>
                                _loading ? null : _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (_registering && (value?.length ?? 0) < 8)
                                return 'Use at least 8 characters';
                              if (!_registering && (value?.isEmpty ?? true))
                                return 'Enter your password';
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 13),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0EC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _error ??
                                    'Unable to continue. Please try again.',
                                style: const TextStyle(
                                  color: Color(0xFF9B3D2B),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: _forestDark,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 21,
                                    height: 21,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _registering ? 'Create account' : 'Sign in',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() {
                                    _registering = !_registering;
                                    _error = null;
                                    _formKey.currentState?.reset();
                                  }),
                            child: Text(
                              _registering
                                  ? 'Already have an account? Sign in'
                                  : 'New here? Create an account',
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _loading ? null : widget.onGuest,
                            icon: const Icon(Icons.explore_outlined),
                            label: const Text('Continue as guest'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _forestDark,
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(color: Color(0xFFD1DDD1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Guests can explore freely. Reports require your contact details.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? account;
  final bool isGuest;
  final VoidCallback onSignOut;

  const HomePage({
    super.key,
    required this.account,
    required this.isGuest,
    required this.onSignOut,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  CameraDescription? _camera;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadCamera();
  }

  Future<void> _loadCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        CameraDescription? rearCamera;
        for (final camera in cameras) {
          if (camera.lensDirection == CameraLensDirection.back) {
            rearCamera = camera;
            break;
          }
        }
        if (mounted) setState(() => _camera = rearCamera ?? cameras.first);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      'Wildlife guide',
      'Report an encounter',
      'Learn and protect',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _forest,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.forest_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Brunei Go Online Apps',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  pages[_selectedIndex],
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account options',
            onSelected: (_) => widget.onSignOut(),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  widget.isGuest
                      ? 'Guest session'
                      : 'Signed in as ${widget.account?['username'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              PopupMenuItem<String>(
                value: 'leave',
                child: Text(
                  widget.isGuest ? 'Sign in or register' : 'Sign out',
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFE5F0EA),
                child: Icon(
                  widget.isGuest ? Icons.person_outline : Icons.person,
                  color: _forestDark,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
      body: WildlifeBackdrop(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            AnimalLibrary(baseUrl: _apiBaseUrl),
            ComplaintForm(camera: _camera, account: widget.account),
            const AwarenessScreen(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: .98),
              border: const Border(top: BorderSide(color: Color(0xFFDCE5DC))),
              boxShadow: [
                BoxShadow(
                  color: _forestDark.withValues(alpha: .07),
                  blurRadius: 18,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _navigationItem(
                        0,
                        Icons.pets_outlined,
                        Icons.pets_rounded,
                        'Wildlife',
                      ),
                      _navigationItem(
                        1,
                        Icons.add_a_photo_outlined,
                        Icons.add_a_photo_rounded,
                        'Report',
                      ),
                      _navigationItem(
                        2,
                        Icons.volunteer_activism_outlined,
                        Icons.volunteer_activism_rounded,
                        'Awareness',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigationItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final selected = _selectedIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF3D98C) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _forestDark.withValues(alpha: .09),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 21,
                  color: selected ? _forestDark : _textMuted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? _forestDark : _textMuted,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimalLibrary extends StatefulWidget {
  final String baseUrl;
  const AnimalLibrary({super.key, required this.baseUrl});

  @override
  State<AnimalLibrary> createState() => _AnimalLibraryState();
}

class _AnimalLibraryState extends State<AnimalLibrary> {
  List<Map<String, dynamic>> _animals = [];
  Map<String, dynamic>? _selectedAnimal;
  String? _selectedCategory;
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse('${widget.baseUrl}/animals.php'))
          .timeout(const Duration(seconds: 15));
      final data = json.decode(response.body);
      if (response.statusCode != 200 || data['status'] != 'success') {
        throw const FormatException('The wildlife guide could not be loaded.');
      }
      final loaded = List<Map<String, dynamic>>.from(data['animals'] as List);
      if (!mounted) return;
      setState(() {
        _animals = loaded;
        if (_selectedAnimal != null) {
          final selected = _selectedAnimal;
          if (selected == null) return;
          final selectedId = '${selected['id']}';
          _selectedAnimal = null;
          for (final animal in loaded) {
            if ('${animal['id']}' == selectedId) {
              _selectedAnimal = animal;
              break;
            }
          }
        }
      });
    } catch (error) {
      if (mounted)
        setState(
          () => _error =
              'Could not load wildlife profiles from ${widget.baseUrl}. Make sure this phone is on the same Wi-Fi as the server, Apache is running, and the server allows connections from your phone. ($error)',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _imageUrl(dynamic path) {
    return _animalPhotoUrl(widget.baseUrl, path);
  }

  String _categoryOf(Map<String, dynamic> animal) {
    final category = (animal['category'] ?? '').toString().trim();
    return category.isEmpty ? 'Other wildlife' : category;
  }

  List<String> get _visibleCategories {
    final categories = _visibleAnimals.map(_categoryOf).toSet().toList();
    categories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categories;
  }

  List<Map<String, dynamic>> get _animalsInSelectedCategory {
    final category = _selectedCategory?.toLowerCase();
    if (category == null) return const [];
    return _visibleAnimals
        .where((animal) => _categoryOf(animal).toLowerCase() == category)
        .toList();
  }

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();
    if (value.contains('bird')) return Icons.air_rounded;
    if (value.contains('fish')) return Icons.water_drop_rounded;
    if (value.contains('amphib')) return Icons.water_drop_rounded;
    if (value.contains('mammal')) return Icons.pets_rounded;
    if (value.contains('reptile')) return Icons.pets_rounded;
    return Icons.category_rounded;
  }

  List<Map<String, dynamic>> get _visibleAnimals {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _animals;
    return _animals
        .where(
          (animal) =>
              [
                animal['name'],
                animal['scientific_name'],
                animal['category'],
              ].any(
                (value) =>
                    (value ?? '').toString().toLowerCase().contains(query),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final heading = _selectedAnimal != null
        ? 'Species profile'
        : _selectedCategory ?? 'Choose a species group';
    final shownCount = _selectedCategory == null
        ? _visibleCategories.length
        : _animalsInSelectedCategory.length;
    final groupWord = shownCount == 1 ? 'group' : 'groups';
    final countLabel = _selectedAnimal != null
        ? '1 profile'
        : _selectedCategory == null
        ? '$shownCount $groupWord'
        : '$shownCount species';
    return RefreshIndicator(
      onRefresh: _fetch,
      color: _forest,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGuideHero(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (_selectedCategory != null)
                          IconButton(
                            tooltip: _selectedAnimal == null
                                ? 'Back to species groups'
                                : 'Back to ${_selectedCategory ?? 'species group'}',
                            onPressed: () => setState(() {
                              if (_selectedAnimal != null) {
                                _selectedAnimal = null;
                              } else {
                                _selectedCategory = null;
                              }
                            }),
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: _forest,
                            visualDensity: VisualDensity.compact,
                          ),
                        Expanded(
                          child: Text(
                            heading,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        if (!_loading)
                          Text(
                            countLabel,
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _selectedAnimal != null
                          ? 'Learn about this animal and its habitat.'
                          : _selectedCategory != null
                          ? 'Choose an animal to view its profile.'
                          : 'Browse Brunei wildlife by group, then choose an animal to explore.',
                      style: const TextStyle(color: _textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search by name or species',
                        prefixIcon: Icon(Icons.search_rounded),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _buildMessage(
                        Icons.wifi_off_rounded,
                        _error ?? 'The wildlife guide could not be loaded.',
                        action: TextButton.icon(
                          onPressed: _fetch,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      )
                    else if (_animals.isEmpty)
                      _buildMessage(
                        Icons.pets_outlined,
                        'Species profiles will appear here when the wildlife team publishes them in the animal library.',
                      )
                    else if (_visibleAnimals.isEmpty)
                      _buildMessage(
                        Icons.search_off_rounded,
                        'No species match your search. Try another.',
                      )
                    else if (_selectedAnimal != null)
                      _buildAnimalDetails(
                        _selectedAnimal ?? const <String, dynamic>{},
                      )
                    else if (_selectedCategory != null &&
                        _animalsInSelectedCategory.isNotEmpty)
                      _buildSpeciesGrid(_animalsInSelectedCategory)
                    else if (_selectedCategory != null)
                      _buildMessage(
                        Icons.search_off_rounded,
                        'There are no matching animals in this group. Try another search.',
                      )
                    else
                      _buildCategoryGrid(_visibleCategories),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideHero() {
    final featuredImage = _animals.isEmpty
        ? null
        : _imageUrl(_animals.first['image_path']) ??
              _imageUrl(_animals.first['poster_path']);
    return Container(
      height: 238,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (featuredImage != null)
            Image.network(
              featuredImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _heroPlaceholder(),
            ),
          if (featuredImage == null) _heroPlaceholder(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0xEE0D1510)],
                stops: [0.05, 1],
              ),
            ),
          ),
          Positioned(
            right: 15,
            top: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: _accent),
                  SizedBox(width: 4),
                  Text(
                    'BRUNEI DARUSSALAM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 19,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'WILDLIFE FIELD GUIDE',
                    style: TextStyle(
                      color: _forestDark,
                      fontSize: 9,
                      letterSpacing: .9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Discover Brunei's wild side",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Choose a species to explore its story.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPlaceholder() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_forest, _forestDark],
      ),
    ),
    child: const Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Icon(Icons.forest_rounded, size: 120, color: Color(0x33FFFFFF)),
      ),
    ),
  );

  Widget _buildCategoryGrid(List<String> categories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700
            ? 3
            : constraints.maxWidth > 430
            ? 2
            : 1;
        return GridView.builder(
          itemCount: categories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 2.5 : 1.55,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            final count = _visibleAnimals
                .where(
                  (animal) =>
                      _categoryOf(animal).toLowerCase() ==
                      category.toLowerCase(),
                )
                .length;
            final examples = _visibleAnimals
                .where(
                  (animal) =>
                      _categoryOf(animal).toLowerCase() ==
                      category.toLowerCase(),
                )
                .take(2)
                .map((animal) => animal['name']?.toString() ?? 'Wildlife')
                .join(' / ');
            final groupAnimals = _visibleAnimals
                .where(
                  (animal) =>
                      _categoryOf(animal).toLowerCase() ==
                      category.toLowerCase(),
                )
                .toList();
            final cover = groupAnimals.isEmpty
                ? null
                : _imageUrl(groupAnimals.first['image_path']) ??
                      _imageUrl(groupAnimals.first['poster_path']);
            return Material(
              color: _forestDark,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                onTap: () => setState(() {
                  _selectedCategory = category;
                  _selectedAnimal = null;
                }),
                borderRadius: BorderRadius.circular(17),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (cover != null)
                        Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _categoryImageFallback(category),
                        )
                      else
                        _categoryImageFallback(category),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xE610211A), Color(0x7A10211A)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Icon(
                                _categoryIcon(category),
                                color: Colors.white,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$count ${count == 1 ? 'animal' : 'animals'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    examples,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpeciesGrid(List<Map<String, dynamic>> animals) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700
            ? 4
            : constraints.maxWidth > 480
            ? 3
            : 2;
        return GridView.builder(
          itemCount: animals.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: .94,
          ),
          itemBuilder: (context, index) {
            final animal = animals[index];
            final selected = '${_selectedAnimal?['id']}' == '${animal['id']}';
            final image =
                _imageUrl(animal['image_path']) ??
                _imageUrl(animal['poster_path']);
            return InkWell(
              onTap: () => setState(() => _selectedAnimal = animal),
              borderRadius: BorderRadius.circular(17),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: selected ? _forest : const Color(0xFFDCE5DC),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _forest.withValues(alpha: .10),
                            blurRadius: 14,
                          ),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (image != null)
                            Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            )
                          else
                            _imagePlaceholder(),
                          if (selected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 25,
                                height: 25,
                                decoration: const BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: _forestDark,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            animal['name']?.toString() ?? 'Wildlife',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            animal['category']?.toString().isNotEmpty == true
                                ? animal['category'].toString()
                                : 'Brunei wildlife',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFE9F1EC),
    child: const Center(
      child: Icon(Icons.pets_rounded, size: 34, color: _forest),
    ),
  );

  Widget _categoryImageFallback(String category) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_forest, _forestDark],
      ),
    ),
    child: Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          _categoryIcon(category),
          size: 100,
          color: Colors.white.withValues(alpha: .12),
        ),
      ),
    ),
  );

  Widget _buildAnimalDetails(Map<String, dynamic> animal) {
    final image =
        _imageUrl(animal['image_path']) ?? _imageUrl(animal['poster_path']);
    final malayContent = animalMalayContent(animal);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: image == null
                ? _imagePlaceholder()
                : Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  ),
          ),
          if ((animal['image_credit'] ?? '').toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 8, 19, 0),
              child: Text(
                'Photo: ${animal['image_credit']}',
                style: const TextStyle(color: _textMuted, fontSize: 10),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((animal['category'] ?? '').toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFE4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      animal['category'].toString(),
                      style: const TextStyle(
                        color: _forestDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(height: 11),
                Text(
                  animal['name']?.toString() ?? 'Wildlife species',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    height: 1.15,
                  ),
                ),
                if ((animal['scientific_name'] ?? '')
                    .toString()
                    .isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    animal['scientific_name'].toString(),
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: _textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (malayContent != null) ...[
                  const SizedBox(height: 16),
                  _buildMalayIntroduction(malayContent),
                ],
                const SizedBox(height: 16),
                Text(
                  (animal['description'] ??
                          'More information about this species will be added soon.')
                      .toString(),
                  style: const TextStyle(
                    height: 1.65,
                    color: _textMuted,
                    fontSize: 14,
                  ),
                ),
                if ((animal['habitat'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _detailRow(
                    Icons.landscape_outlined,
                    'Habitat',
                    animal['habitat'].toString(),
                  ),
                ],
                if ((animal['conservation_status'] ?? '')
                    .toString()
                    .isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _detailRow(
                    Icons.shield_outlined,
                    'Conservation status',
                    animal['conservation_status'].toString(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EFE4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: _forest),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: _textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildMessage(IconData icon, String text, {Widget? action}) =>
      Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE5DC)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _forest, size: 30),
            const SizedBox(height: 9),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMuted, height: 1.45),
            ),
            if (action != null) action,
          ],
        ),
      );
}

class AwarenessScreen extends StatelessWidget {
  const AwarenessScreen({super.key});

  void _openPoster(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Wildlife awareness'),
          ),
          body: PhotoView(
            imageProvider: AssetImage(path),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [_forest, _forestDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARE FOR OUR WILD NEIGHBOURS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Small actions help\nprotect wildlife.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 9),
                        Text(
                          'Learn how to respond thoughtfully and keep people and animals safe.',
                          style: TextStyle(color: Colors.white70, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Learn and protect',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Explore these awareness resources.',
                    style: TextStyle(color: _textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  _posterTile(
                    context,
                    'images/awarenessaction.png',
                    'Living alongside wildlife',
                    'Practical ways to respect wild animals and their habitats.',
                  ),
                  const SizedBox(height: 13),
                  _posterTile(
                    context,
                    'images/primate.png',
                    'Protecting our primates',
                    'Learn why forests and wildlife corridors matter.',
                  ),
                  const SizedBox(height: 13),
                  _posterTile(
                    context,
                    'images/crocodiles.jpg',
                    'Stay safe near waterways',
                    'Give wildlife space and follow local safety guidance.',
                  ),
                  const SizedBox(height: 13),
                  _posterTile(
                    context,
                    'images/crocodile.png',
                    'Respect wildlife from a distance',
                    'Never approach, feed, or attempt to handle wild animals.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _posterTile(
    BuildContext context,
    String image,
    String title,
    String description,
  ) {
    return InkWell(
      onTap: () => _openPoster(context, image),
      borderRadius: BorderRadius.circular(18),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
              child: Image.asset(
                image,
                width: 112,
                height: 112,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 112,
                  height: 112,
                  color: _surfaceRaised,
                  child: const Icon(
                    Icons.nature_people_outlined,
                    color: _forest,
                    size: 34,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text(
                          'View resource',
                          style: TextStyle(
                            color: _forest,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: _forest,
                        ),
                      ],
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

class ComplaintForm extends StatefulWidget {
  final CameraDescription? camera;
  final Map<String, dynamic>? account;
  const ComplaintForm({super.key, required this.camera, required this.account});

  @override
  _ComplaintFormState createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _gpsController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _complaintController = TextEditingController();

  ImageAndLocationData? capturedData;
  bool _isLoading = false;
  String? _capturedDateTime;
  List<Map<String, dynamic>> animals = [];
  Map<String, dynamic>? selectedAnimal;

  final String baseUrl = _apiBaseUrl;

  @override
  void initState() {
    super.initState();
    final username = widget.account?['username']?.toString();
    final contact = widget.account?['contact']?.toString();
    if (username != null) _nameController.text = username;
    if (contact != null)
      _phoneController.text = contact.replaceFirst(RegExp(r'^\+?673'), '');
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/animals.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data['status'] == 'success') {
          setState(
            () => animals = List<Map<String, dynamic>>.from(data['animals']),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _uploadReport() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final chosenAnimal = selectedAnimal;
    if (capturedData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture a photo and location first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final capture = capturedData;
    if (capture == null) return;

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/upload_report.php"),
      );

      request.fields['fullname'] = _nameController.text.trim();
      request.fields['contact'] = '+673${_phoneController.text.trim()}';
      request.fields['aduan'] = _complaintController.text.trim();
      request.fields['latitude'] = capture.latitude?.toString() ?? '0.0';
      request.fields['longitude'] = capture.longitude?.toString() ?? '0.0';
      request.fields['location'] = capture.locationName ?? 'Unknown Location';
      request.fields['tarikh'] = _capturedDateTime ?? DateTime.now().toString();
      if (chosenAnimal != null) {
        if (chosenAnimal['id'] != null) {
          request.fields['animal_id'] = chosenAnimal['id'].toString();
        }
        request.fields['animal_name'] = chosenAnimal['name'].toString();
      }

      final imageBytes = capture.imageBytes;
      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'picture',
            imageBytes,
            filename: capture.imageFileName ?? 'wildlife-report.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('picture', capture.imagePath),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = json.decode(responseBody);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["message"]),
              backgroundColor: Colors.green,
            ),
          );
          _formKey.currentState?.reset();
          if (widget.account == null) {
            _nameController.clear();
            _phoneController.clear();
          } else {
            _nameController.text =
                widget.account?['username']?.toString() ?? _nameController.text;
            _phoneController.text =
                (widget.account?['contact']?.toString() ??
                        _phoneController.text)
                    .replaceFirst(RegExp(r'^\+?673'), '');
          }
          _locationController.clear();
          _gpsController.clear();
          _complaintController.clear();
          setState(() {
            capturedData = null;
            _capturedDateTime = null;
            selectedAnimal = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["message"] ?? 'Failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final captureData = capturedData;
    final selectedSpecies = selectedAnimal;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shadowColor: const Color(0x18104D38),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_forest, _forestDark],
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'COMMUNITY FIELD REPORT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Report a wildlife encounter',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Your report helps local teams respond and protect wildlife.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .82),
                                    height: 1.4,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 23),
                    _sectionHeading(
                      '01',
                      'Evidence and location',
                      'Capture a photo so the team can understand the encounter.',
                    ),
                    const SizedBox(height: 13),

                    FilledButton.icon(
                      onPressed: widget.camera == null && !kIsWeb
                          ? null
                          : () async {
                              if (animals.isEmpty) await _loadAnimals();
                              if (!mounted) return;
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CameraMapScreen(
                                    camera: widget.camera,
                                    animals: animals,
                                    apiBaseUrl: baseUrl,
                                  ),
                                ),
                              );
                              final capture = result;
                              if (capture != null) {
                                final now = DateTime.now();
                                final formattedDateTime =
                                    "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
                                    "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

                                setState(() {
                                  capturedData = capture;
                                  selectedAnimal = capture.suggestedAnimal;
                                  _capturedDateTime = formattedDateTime;
                                  _locationController.text =
                                      capture.locationName ??
                                      "Unknown Location";
                                  _gpsController.text =
                                      "Lat: ${capture.latitude?.toStringAsFixed(6)}, Lon: ${capture.longitude?.toStringAsFixed(6)}";
                                });
                              }
                            },
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(
                        capturedData == null
                            ? 'Capture photo and location'
                            : 'Retake photo and location',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: _forest,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 1,
                      ),
                    ),
                    if (widget.camera == null && !kIsWeb) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Camera is unavailable on this device.',
                        style: TextStyle(
                          color: Color(0xFFE4A58C),
                          fontSize: 12,
                        ),
                      ),
                    ],

                    if (captureData != null) ...[
                      const SizedBox(height: 20),
                      _buildCapturedPreview(),
                      if (captureData.scanMessage != null) ...[
                        const SizedBox(height: 10),
                        _buildScanMessage(captureData),
                      ],
                      const SizedBox(height: 15),
                      _sectionHeading(
                        'i',
                        selectedSpecies == null
                            ? 'Animal identification'
                            : 'Identified animal',
                        selectedSpecies == null
                            ? 'The photo scan could not confidently match a published profile. You can still submit the report for wildlife team review.'
                            : 'The camera matched this photo to a published wildlife profile.',
                      ),
                      if (selectedSpecies != null) ...[
                        const SizedBox(height: 12),
                        _buildMatchedAnimalCard(selectedSpecies),
                      ],
                      const SizedBox(height: 15),
                      _buildReadOnlyField(
                        _gpsController,
                        'GPS Coordinates',
                        Icons.my_location,
                      ),
                      const SizedBox(height: 15),
                      _buildReadOnlyField(
                        _locationController,
                        'Detected Location',
                        Icons.map_outlined,
                        maxLines: 2,
                      ),
                      if (_capturedDateTime != null) ...[
                        const SizedBox(height: 15),
                        TextFormField(
                          initialValue: _capturedDateTime,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date & Time Captured',
                            prefixIcon: const Icon(Icons.access_time),
                            filled: true,
                            fillColor: _surfaceRaised,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 26),
                    if (widget.account == null) ...[
                      _sectionHeading(
                        '02',
                        'Your contact details',
                        'We may use these details if the team needs more information.',
                      ),
                      const SizedBox(height: 13),
                      _buildInputField(
                        _nameController,
                        'Full Name *',
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      _buildPhoneField(),
                    ] else ...[
                      _sectionHeading(
                        '02',
                        'Your account details',
                        'Your registered contact information will be attached to this report.',
                      ),
                      const SizedBox(height: 13),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD6E4D3)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: _forest,
                              child: Icon(
                                Icons.verified_user_outlined,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nameController.text,
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+673 ${_phoneController.text}',
                                    style: const TextStyle(
                                      color: _textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: _forest,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 26),
                    _sectionHeading(
                      '03',
                      'Tell us what happened',
                      'Add the details that will help the response team.',
                    ),
                    const SizedBox(height: 13),
                    _buildInputField(
                      _complaintController,
                      'Complaint Details *',
                      Icons.description_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    FilledButton.icon(
                      onPressed: _isLoading ? null : _uploadReport,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: _forestDark,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isLoading
                            ? 'Sending report...'
                            : 'Submit wildlife report',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: _textMuted,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Your contact details are used for report follow-up.',
                          style: TextStyle(fontSize: 11, color: _textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(String number, String title, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 31,
        height: 31,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EFE4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: _forestDark,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildMatchedAnimalCard(Map<String, dynamic> animal) {
    final suggestion = capturedData?.suggestedAnimal;
    final isSuggestion = suggestion != null &&
        (suggestion['source'] == 'online_ai' ||
            '${suggestion['id']}' == '${animal['id']}');
    final isOnlineSuggestion = animal['source'] == 'online_ai';
    final malayContent = animalMalayContent(animal);
    final malayIntroduction = animal['introduction_ms']?.toString() ?? '';
    final imagePath = animal['image_path']?.toString() ?? '';
    final imageUrl = _animalPhotoUrl(baseUrl, imagePath);
    final confidence = capturedData?.matchConfidence;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E5D4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: imageUrl == null
                      ? const ColoredBox(
                          color: _surfaceRaised,
                          child: Icon(Icons.pets, color: _accent),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: _surfaceRaised,
                            child: Icon(Icons.pets, color: _accent),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnlineSuggestion
                          ? 'ONLINE AI SUGGESTION'
                          : isSuggestion
                              ? 'CAMERA SUGGESTION'
                              : 'SELECTED SPECIES',
                      style: const TextStyle(
                        color: _forest,
                        fontSize: 9,
                        letterSpacing: .9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      animal['name']?.toString() ?? 'Wildlife species',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if ((animal['scientific_name'] ?? '').toString().isNotEmpty)
                      Text(
                        animal['scientific_name'].toString(),
                        style: const TextStyle(
                          color: _textMuted,
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                        ),
                      ),
                    if ((animal['malay_name'] ?? '').toString().isNotEmpty)
                      Text(
                        animal['malay_name'].toString(),
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                        ),
                      ),
                    if (confidence != null && isSuggestion)
                      Text(
                        '${(confidence * 100).round()}% AI estimate - staff review recommended',
                        style: const TextStyle(color: _textMuted, fontSize: 10),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (malayContent != null) ...[
            const SizedBox(height: 13),
            _buildMalayIntroduction(malayContent),
          ] else if (malayIntroduction.isNotEmpty) ...[
            const SizedBox(height: 13),
            _buildOnlineMalayIntroduction(
              animal['malay_name']?.toString() ?? 'Nama Melayu',
              malayIntroduction,
            ),
          ],
          if ((animal['habitat'] ?? animal['habitat_ms'] ?? '').toString().isNotEmpty ||
              (animal['conservation_status'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                if ((animal['habitat'] ?? '').toString().isNotEmpty)
                  _profileTag(
                    Icons.landscape_outlined,
                    animal['habitat'].toString(),
                  ),
                if ((animal['habitat'] ?? '').toString().isEmpty &&
                    (animal['habitat_ms'] ?? '').toString().isNotEmpty)
                  _profileTag(
                    Icons.landscape_outlined,
                    animal['habitat_ms'].toString(),
                  ),
                if ((animal['conservation_status'] ?? '').toString().isNotEmpty)
                  _profileTag(
                    Icons.shield_outlined,
                    animal['conservation_status'].toString(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanMessage(ImageAndLocationData capture) {
    final matched = capture.suggestedAnimal != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: matched ? const Color(0xFFE8F1E5) : _surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            matched ? Icons.auto_awesome : Icons.info_outline_rounded,
            size: 17,
            color: _forest,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              capture.scanMessage ??
                  'The report will be reviewed by the wildlife team.',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTag(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFE6EEE4),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _forest),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      textInputAction: TextInputAction.next,
      inputFormatters: [_BruneiPhoneFormatter()],
      decoration: InputDecoration(
        labelText: 'Brunei mobile number *',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EEE4),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'BN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _forestDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '+673',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(width: 11),
              Container(width: 1, height: 24, color: Color(0xFFD8E2D8)),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: '712 3456',
        helperText:
            'Enter 7 digits, starting with 7 or 8. You can paste a number with +673 too.',
        helperStyle: const TextStyle(fontSize: 11, color: _textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _surfaceRaised,
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter your Brunei mobile number';
        }
        if (!RegExp(r'^[78]\d{6}$').hasMatch(value)) {
          return 'Enter valid Brunei number (e.g., 7123456)';
        }
        return null;
      },
    );
  }

  Widget _buildInputField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isPhone = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      textCapitalization: label.toLowerCase().contains('name')
          ? TextCapitalization.words
          : TextCapitalization.sentences,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: maxLines > 1
            ? 'Include when and where it happened, if known.'
            : null,
        prefixIcon: maxLines == 1 ? Icon(icon, color: _forest) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _surfaceRaised,
        alignLabelWithHint: maxLines > 1,
      ),
      keyboardType: maxLines > 1
          ? TextInputType.multiline
          : isPhone
          ? TextInputType.phone
          : TextInputType.text,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Please complete this field' : null,
    );
  }

  Widget _buildReadOnlyField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      maxLines: maxLines,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _surfaceRaised,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCapturedPreview() {
    final capture = capturedData;
    if (capture == null) return const SizedBox.shrink();
    final imageBytes = capture.imageBytes;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: imageBytes != null
          ? Image.memory(
              imageBytes,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : Image.file(
              File(capture.imagePath),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }
}

class CameraMapScreen extends StatefulWidget {
  final CameraDescription? camera;
  final List<Map<String, dynamic>> animals;
  final String apiBaseUrl;
  const CameraMapScreen({
    super.key,
    required this.camera,
    required this.animals,
    required this.apiBaseUrl,
  });

  @override
  State<CameraMapScreen> createState() => _CameraMapScreenState();
}

class _SpeciesScanResult {
  final Map<String, dynamic>? animal;
  final double? confidence;
  final String? label;
  final String message;

  const _SpeciesScanResult({
    this.animal,
    this.confidence,
    this.label,
    required this.message,
  });
}

class _CameraMapScreenState extends State<CameraMapScreen> {
  CameraController? _controller;
  browser_photo.BrowserCameraController? _browserCamera;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String? _cameraError;
  String _currentLocation = 'Getting your location';
  double? _latitude;
  double? _longitude;
  final Location _location = Location();
  final geo.Geocoding _geocoding = geo.Geocoding();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeBrowserCamera();
    } else {
      if (widget.camera != null) _initializeCamera();
      _getCurrentLocation();
    }
  }

  Future<void> _initializeBrowserCamera() async {
    final camera = browser_photo.BrowserCameraController();
    _browserCamera = camera;
    try {
      await camera.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraError =
              'Allow camera access in your browser to take a live wildlife photo.';
        });
      }
    }
    final location = await camera.getLocation();
    if (!mounted || location == null) {
      if (mounted && location == null) {
        setState(() => _currentLocation = 'GPS permission unavailable');
      }
      return;
    }
    setState(() {
      _latitude = location.latitude;
      _longitude = location.longitude;
      _currentLocation = 'GPS location captured';
    });
  }

  Future<void> _initializeCamera() async {
    final description = widget.camera;
    if (description == null) {
      if (mounted) {
        setState(() => _cameraError = 'No camera is available on this device.');
      }
      return;
    }
    try {
      final controller = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (_) {
      if (mounted)
        setState(
          () => _cameraError =
              'The camera could not be started. Check camera permission and try again.',
        );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      var serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        if (mounted)
          setState(() => _currentLocation = 'Location services are turned off');
        return;
      }

      var permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied)
        permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        if (mounted)
          setState(
            () => _currentLocation = 'Location permission is unavailable',
          );
        return;
      }

      final data = await _location.getLocation();
      if (!mounted) return;
      final latitude = data.latitude;
      final longitude = data.longitude;
      setState(() {
        _latitude = latitude;
        _longitude = longitude;
        _currentLocation = latitude != null && longitude != null
            ? 'Finding your place…'
            : 'GPS coordinates unavailable';
      });
      if (latitude == null || longitude == null) return;

      try {
        final places = await _geocoding.placemarkFromCoordinates(
          latitude,
          longitude,
        );
        if (!mounted || places.isEmpty) return;
        final place = places.first;
        final placeName =
            [
                  place.subLocality,
                  place.locality,
                  place.subAdministrativeArea,
                  place.administrativeArea,
                  place.country,
                ]
                .whereType<String>()
                .map((part) => part.trim())
                .where((part) => part.isNotEmpty)
                .toSet()
                .join(', ');
        if (placeName.isNotEmpty) setState(() => _currentLocation = placeName);
      } catch (_) {
        // Keep coordinates visible when the device cannot resolve an address.
        if (mounted)
          setState(() => _currentLocation = 'GPS location available');
      }
    } catch (_) {
      if (mounted) setState(() => _currentLocation = 'Location is unavailable');
    }
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<_SpeciesScanResult> _scanSpecies(String imagePath) async {
    if (widget.animals.isEmpty) {
      return const _SpeciesScanResult(
        message: 'No published wildlife profiles are available to match.',
      );
    }

    ImageLabeler? labeler;
    try {
      labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.50),
      );
      final labels = await labeler.processImage(
        InputImage.fromFilePath(imagePath),
      );
      const genericLabels = {
        'animal',
        'wildlife',
        'nature',
        'reptile',
        'mammal',
        'bird',
        'pet',
        'fauna',
        'organism',
        'crocodile',
        'crocodilian',
        'gharial',
        'turtle',
        'sea turtle',
        'monkey',
        'primate',
        'bear',
        'pig',
        'boar',
        'hornbill',
      };
      final matches =
          <
            ({
              Map<String, dynamic> animal,
              double confidence,
              String label,
              double score,
            })
          >[];

      for (final animal in widget.animals) {
        final name = _normalize(animal['name']?.toString() ?? '');
        final scientificName = _normalize(
          animal['scientific_name']?.toString() ?? '',
        );
        var bestMatch = 0.0;
        var bestConfidence = 0.0;
        var bestLabel = '';

        for (final detected in labels) {
          final label = _normalize(detected.label);
          if (label.isEmpty ||
              genericLabels.contains(label) ||
              detected.confidence < 0.60)
            continue;

          var similarity = 0.0;
          if (label == name ||
              (scientificName.isNotEmpty && label == scientificName)) {
            similarity = 1.0;
          } else if (label.length >= 4 &&
              (name.split(' ').contains(label) ||
                  label.split(' ').contains(name))) {
            similarity = 0.88;
          } else if (label.length >= 4 && name.contains(label)) {
            similarity = 0.86;
          }

          if (similarity * detected.confidence > bestMatch) {
            bestMatch = similarity * detected.confidence;
            bestConfidence = detected.confidence;
            bestLabel = detected.label;
          }
        }

        if (bestConfidence >= 0.60 && bestMatch >= 0.50) {
          matches.add((
            animal: animal,
            confidence: bestConfidence,
            label: bestLabel,
            score: bestMatch,
          ));
        }
      }

      matches.sort((a, b) => b.score.compareTo(a.score));
      if (matches.isEmpty) {
        return const _SpeciesScanResult(
          message:
              'No confident species match. The report can be submitted for wildlife team review.',
        );
      }
      if (matches.length > 1 &&
          matches[1].score >= matches.first.score - 0.08) {
        return const _SpeciesScanResult(
          message:
              'The scan found more than one possible match. The report can be submitted for wildlife team review.',
        );
      }

      final match = matches.first;
      return _SpeciesScanResult(
        animal: match.animal,
        confidence: match.confidence,
        label: match.label,
        message:
            'The camera identified a likely match from published wildlife profiles.',
      );
    } catch (_) {
      return const _SpeciesScanResult(
        message:
            'Automatic identification is unavailable on this device. The report can be submitted for wildlife team review.',
      );
    } finally {
      await labeler?.close();
    }
  }

  Future<_SpeciesScanResult> _scanSpeciesOnline(
    Uint8List imageBytes, {
    String fileName = 'wildlife-report.jpg',
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.apiBaseUrl}/identify_animal.php'),
      )..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: fileName,
          ),
      );
      final streamed = await request.send().timeout(
        const Duration(seconds: 85),
      );
      final response = await http.Response.fromStream(streamed);
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || data['status'] != 'identified') {
        return _SpeciesScanResult(
          message: data['message']?.toString() ??
              'The online scan could not confidently identify the animal. The report can still be sent for wildlife team review.',
        );
      }

      final onlineAnimal = Map<String, dynamic>.from(data['animal'] as Map);
      final scientificName = _normalize(
        onlineAnimal['scientific_name']?.toString() ?? '',
      );
      Map<String, dynamic>? catalogMatch;
      for (final animal in widget.animals) {
        if (scientificName.isNotEmpty &&
            _normalize(animal['scientific_name']?.toString() ?? '') == scientificName) {
          catalogMatch = animal;
          break;
        }
      }
      final resultAnimal = catalogMatch == null
          ? onlineAnimal
          : Map<String, dynamic>.from(catalogMatch)
            ..['source'] = 'online_ai';
      resultAnimal['source'] = 'online_ai';
      final confidence = resultAnimal['confidence'];
      return _SpeciesScanResult(
        animal: resultAnimal,
        confidence: confidence is num ? confidence.toDouble() : null,
        label: 'Online wildlife identification',
        message: data['message']?.toString() ??
            'Online AI found a likely species match. Wildlife staff should verify the identification.',
      );
    } catch (_) {
      return const _SpeciesScanResult(
        message:
            'The online identification service is unavailable. The report can still be sent for wildlife team review.',
      );
    }
  }

  Future<void> _captureImage() async {
    if (kIsWeb) {
      final camera = _browserCamera;
      if (camera == null || !_isCameraInitialized || _isCapturing) return;
      setState(() => _isCapturing = true);
      try {
        final photo = await camera.capture();
        final scan = await _scanSpeciesOnline(
          photo.bytes,
          fileName: photo.fileName,
        );
        final result = ImageAndLocationData(
          imagePath: '',
          imageBytes: photo.bytes,
          imageFileName: photo.fileName,
          latitude: _latitude,
          longitude: _longitude,
          locationName: _latitude != null && _longitude != null
              ? _currentLocation
              : 'Location unavailable',
          timestamp: DateTime.now(),
          suggestedAnimal: scan.animal,
          matchConfidence: scan.confidence,
          detectedLabel: scan.label,
          scanMessage: scan.message,
        );
        if (mounted) Navigator.pop(context, result);
      } catch (_) {
        if (mounted) {
          setState(() => _isCapturing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The live photo could not be captured. Please try again.',
              ),
            ),
          );
        }
      }
      return;
    }
    final controller = _controller;
    if (!_isCameraInitialized || controller == null || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final image = await controller.takePicture();
      var scan = await _scanSpecies(image.path);
      if (scan.animal == null) {
        scan = await _scanSpeciesOnline(
          await image.readAsBytes(),
          fileName: image.name,
        );
      }
      final result = ImageAndLocationData(
        imagePath: image.path,
        latitude: _latitude,
        longitude: _longitude,
        locationName: _latitude != null && _longitude != null
            ? _currentLocation
            : 'Location unavailable',
        timestamp: DateTime.now(),
        suggestedAnimal: scan.animal,
        matchConfidence: scan.confidence,
        detectedLabel: scan.label,
        scanMessage: scan.message,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not capture this photo. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _browserCamera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildBrowserCapture();
    if (_cameraError != null) {
      return Scaffold(
        backgroundColor: _canvas,
        appBar: AppBar(title: const Text('Capture evidence')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  color: _accent,
                  size: 46,
                ),
                const SizedBox(height: 14),
                Text(
                  _cameraError ?? 'Camera could not start.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textPrimary, height: 1.5),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _cameraError = null;
                      _isCameraInitialized = false;
                    });
                    _initializeCamera();
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final controller = _controller;
    if (!_isCameraInitialized || controller == null) {
      return const Scaffold(
        backgroundColor: _canvas,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Capture evidence',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.black.withValues(alpha: .32),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x80000000),
                  Colors.transparent,
                  Color(0xCC000000),
                ],
                stops: [0, .32, 1],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 74,
            left: 18,
            right: 18,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .42),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: _accent, size: 15),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Unknown animal photos may be sent to online AI for identification',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: IgnorePointer(
              child: Container(
                width: 250,
                height: 270,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 1.2),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 220,
            child: _buildLocationCard(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _isCapturing ? null : _captureImage,
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .9),
                          width: 2,
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accent,
                        ),
                        child: Center(
                          child: _isCapturing
                              ? const SizedBox(
                                  width: 27,
                                  height: 27,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _forestDark,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: _forestDark,
                                  size: 29,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCapturing ? 'SCANNING PHOTO' : 'TAP TO CAPTURE AND SCAN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isCapturing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: .60),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _accent),
                      SizedBox(height: 16),
                      Text(
                        'Checking the wildlife profiles...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'This may take a moment',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBrowserCapture() => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text('Capture wildlife evidence'),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    body: _cameraError != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.no_photography_outlined,
                    color: _accent,
                    size: 48,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _cameraError ?? 'Camera access is unavailable.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use localhost or HTTPS, then allow camera permission.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        : !_isCameraInitialized
        ? const Center(child: CircularProgressIndicator(color: _accent))
        : Stack(
            fit: StackFit.expand,
            children: [
              _browserCamera?.preview ?? const SizedBox.shrink(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Colors.transparent,
                      Color(0xCC000000),
                    ],
                    stops: [0, .35, 1],
                  ),
                ),
              ),
              Positioned(
                top: 18,
                left: 18,
                right: 18,
                child: Text(
                  _latitude != null
                      ? 'GPS ready • $_currentLocation'
                      : 'Waiting for GPS permission…',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 30,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Center the animal in the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isCapturing ? null : _captureImage,
                      child: Container(
                        width: 78,
                        height: 78,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accent,
                          ),
                          child: Center(
                            child: _isCapturing
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: _forestDark,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: _forestDark,
                                    size: 30,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
  );

  Widget _buildLocationCard() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xE6171D19),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Colors.white24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .24),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF344438),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.location_on_outlined,
            color: _accent,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LOCATION',
                style: TextStyle(
                  color: _accent,
                  fontSize: 9,
                  letterSpacing: .9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _currentLocation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_latitude != null && _longitude != null)
                Text(
                  '${_latitude?.toStringAsFixed(5) ?? '—'}, ${_longitude?.toStringAsFixed(5) ?? '—'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          DateFormat('h:mm a').format(DateTime.now()),
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    ),
  );
}

class ImageAndLocationData {
  final String imagePath;
  final Uint8List? imageBytes;
  final String? imageFileName;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime? timestamp;
  final Map<String, dynamic>? suggestedAnimal;
  final double? matchConfidence;
  final String? detectedLabel;
  final String? scanMessage;

  ImageAndLocationData({
    required this.imagePath,
    this.imageBytes,
    this.imageFileName,
    this.latitude,
    this.longitude,
    this.locationName,
    this.timestamp,
    this.suggestedAnimal,
    this.matchConfidence,
    this.detectedLabel,
    this.scanMessage,
  });
}
