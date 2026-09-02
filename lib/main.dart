import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'sections/hero_section.dart';
import 'sections/about_us_section.dart';
import 'sections/services_section.dart';
import 'sections/why_choose_us_section.dart';
import 'sections/process_section.dart';
import 'sections/testimonials_section.dart';
import 'sections/contact_section.dart';
import 'sections/footer_section.dart';
import 'sections/gerber_upload_section.dart';
import 'auth/login_page.dart';
import 'auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AuthService.init();

  runApp(const LionCircuitsApp());
}


class LionCircuitsApp extends StatelessWidget {
  const LionCircuitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLASHFABZ — Premium PCB Manufacturing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07070A),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFFD54F),
          surface: Color(0xFF13131A),
        ),
        fontFamily: 'Segoe UI',
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -1.5),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          bodyLarge: TextStyle(color: Color(0xFFB0B0C0), height: 1.6),
          bodyMedium: TextStyle(color: Color(0xFF8B8B9E), height: 1.5),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

 
  final GlobalKey _heroKey      = GlobalKey();
  final GlobalKey _aboutKey     = GlobalKey();
  final GlobalKey _servicesKey  = GlobalKey();
  final GlobalKey _quoteKey     = GlobalKey();
  final GlobalKey _processKey   = GlobalKey();
  final GlobalKey _contactKey   = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 750), curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _NavBar(
        onServices: () => _scrollTo(_servicesKey),
        onContact:  () => _scrollTo(_contactKey),
        onAbout:    () => _scrollTo(_aboutKey),
        onQuote:    () => _scrollTo(_quoteKey),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            HeroSection(
              key: _heroKey,
              onGetStarted: () => _scrollTo(_quoteKey),
              onLearnMore:  () => _scrollTo(_aboutKey),
            ),
            AboutUsSection(key: _aboutKey),
            ServicesSection(key: _servicesKey),
            WhyChooseUsSection(),
            GerberUploadSection(key: _quoteKey),
            ProcessSection(key: _processKey),
            TestimonialsSection(),
            ContactSection(key: _contactKey),
            FooterSection(
              onServices: () => _scrollTo(_servicesKey),
              onContact:  () => _scrollTo(_contactKey),
              onQuote:    () => _scrollTo(_quoteKey),
            ),
          ],
        ),
      ),
    );
  }
}
class _NavBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onServices;
  final VoidCallback onContact;
  final VoidCallback onAbout;
  final VoidCallback onQuote;

  const _NavBar({
    required this.onServices,
    required this.onContact,
    required this.onAbout,
    required this.onQuote,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<_NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<_NavBar> {
  String _hovered = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF07070A).withValues(alpha: 0.88),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'FLASHFABZ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _navItem('About', widget.onAbout),
            _navItem('Services', widget.onServices),
            _navItem('Contact', widget.onContact),
            if (AuthService.isLoggedIn)
              _ProfileDropdown(onLogout: () => setState(() {}))
            else
              _navItem('Login', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ).then((_) => setState(() {}));
              }),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: widget.onQuote,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.25), blurRadius: 12)],
                ),
                child: const Text(
                  'Get Quote',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String label, VoidCallback onTap) {
    final hovered = _hovered == label;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = label),
      onExit:  (_) => setState(() => _hovered = ''),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: hovered ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: hovered ? const Color(0xFF00E5FF) : Colors.white70,
              fontWeight: hovered ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Premium Profile Dropdown ─────────────────────────────────────────────────
class _ProfileDropdown extends StatefulWidget {
  final VoidCallback onLogout;
  const _ProfileDropdown({required this.onLogout});

  @override
  State<_ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<_ProfileDropdown>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _menuOpen = false;
  late AnimationController _arrowCtrl;
  late Animation<double> _arrowAnim;

  @override
  void initState() {
    super.initState();
    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _arrowAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _arrowCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    widget.onLogout();
  }

  void _onMenuOpen() {
    setState(() => _menuOpen = true);
    _arrowCtrl.forward();
  }

  void _onMenuClose() {
    setState(() => _menuOpen = false);
    _arrowCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final name     = AuthService.userName  ?? 'User';
    final email    = AuthService.userEmail ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return PopupMenuButton<String>(
      offset: const Offset(0, 58),
      onOpened:   _onMenuOpen,
      onCanceled: _onMenuClose,
      onSelected: (value) {
        _onMenuClose();
        if (value == 'logout') _handleLogout();
      },
      color: Colors.transparent,
      elevation: 0,
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _PopupCard(
            name: name,
            email: email,
            initials: initials,
            onLogout: _handleLogout,
          ),
        ),
      ],
      // ── Trigger pill button ─────────────────────────────────────────
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (_hovered || _menuOpen)
                ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: (_hovered || _menuOpen)
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing circular avatar
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: (_hovered || _menuOpen)
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: (_hovered || _menuOpen)
                      ? const Color(0xFF00E5FF)
                      : Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                ),
                child: const Text('Profile'),
              ),
              const SizedBox(width: 3),
              RotationTransition(
                turns: _arrowAnim,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: (_hovered || _menuOpen)
                      ? const Color(0xFF00E5FF)
                      : Colors.white38,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glassmorphism popup card ────────────────────────────────────────────────────
class _PopupCard extends StatefulWidget {
  final String name;
  final String email;
  final String initials;
  final VoidCallback onLogout;

  const _PopupCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.onLogout,
  });

  @override
  State<_PopupCard> createState() => _PopupCardState();
}

class _PopupCardState extends State<_PopupCard> {
  bool _logoutHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header banner ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF001A2E), Color(0xFF00122B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Row(
              children: [
                // Glowing avatar with online dot
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    // Online green dot
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0E0E14),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Active badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00E676).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                color: Color(0xFF00E676), size: 6),
                            SizedBox(width: 5),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Gradient divider ─────────────────────────────────────────
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFF00E5FF),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ── Logout button ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: MouseRegion(
              onEnter: (_) => setState(() => _logoutHovered = true),
              onExit:  (_) => setState(() => _logoutHovered = false),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onLogout();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: _logoutHovered
                        ? const LinearGradient(
                            colors: [Color(0xFFFF4D4D), Color(0xFFFF1744)],
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFFFF4D4D).withValues(alpha: 0.12),
                              const Color(0xFFFF1744).withValues(alpha: 0.12),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _logoutHovered
                          ? const Color(0xFFFF4D4D)
                          : const Color(0xFFFF4D4D).withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: _logoutHovered
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF4D4D)
                                  .withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: _logoutHovered
                            ? Colors.white
                            : const Color(0xFFFF4D4D),
                        size: 16,
                      ),
                      const SizedBox(width: 9),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: _logoutHovered
                              ? Colors.white
                              : const Color(0xFFFF4D4D),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: 0.5,
                        ),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
