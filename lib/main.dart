import 'package:flutter/material.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LionCircuitsApp());
}


class LionCircuitsApp extends StatelessWidget {
  const LionCircuitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '8HRPCB — Premium PCB Manufacturing',
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
        color: const Color(0xFF07070A).withOpacity(0.88),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
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
                  '8HRPCB',
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
            _navItem(AuthService.isLoggedIn ? 'Profile' : 'Login', () {
              if (AuthService.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Already signed in')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ).then((_) => setState(() {}));
              }
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
                  boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.25), blurRadius: 12)],
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
            color: hovered ? Colors.white.withOpacity(0.06) : Colors.transparent,
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
