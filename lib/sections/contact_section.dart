import 'package:flutter/material.dart';
import 'section_wrapper.dart';

class ContactSection extends StatefulWidget {
  const ContactSection({super.key});

  @override
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _msgCtrl     = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return SectionWrapper(
      title: 'GET IN TOUCH',
      backgroundColor: const Color(0xFF09090D),
      child: isMobile ? _buildMobile(context) : _buildDesktop(context),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: _buildContactInfo()),
        const SizedBox(width: 48),
        Expanded(flex: 6, child: _buildForm(context)),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      children: [
        _buildContactInfo(),
        const SizedBox(height: 40),
        _buildForm(context),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Let\'s Build Something\nAmazing Together',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
        ),
        const SizedBox(height: 20),
        const Text(
          'Have a project in mind? Send us your Gerber files or reach out to discuss your PCB requirements.',
          style: TextStyle(color: Color(0xFFB0B0C0), fontSize: 15, height: 1.7),
        ),
        const SizedBox(height: 40),
        _contactRow(Icons.email_outlined, 'Email', 'flashfabz26@gmail.com', const Color(0xFF00E5FF)),
        const SizedBox(height: 20),
        _contactRow(Icons.phone_outlined, 'Phone', '+91 80 1234 5678', const Color(0xFFFFD54F)),
        const SizedBox(height: 20),
        _contactRow(Icons.location_on_outlined, 'Location', 'Bengaluru, Karnataka, India', const Color(0xFF69FF47)),
        const SizedBox(height: 20),
        _contactRow(Icons.access_time_outlined, 'Hours', 'Mon–Sat: 9AM – 7PM IST', const Color(0xFFBB86FC)),
        const SizedBox(height: 40),
        Row(
          children: [
            _socialBtn(Icons.language, 'Website'),
            const SizedBox(width: 12),
            _socialBtn(Icons.business, 'LinkedIn'),
            const SizedBox(width: 12),
            _socialBtn(Icons.alternate_email, 'Twitter'),
          ],
        ),
      ],
    );
  }

  Widget _contactRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _socialBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    if (_submitted) return _buildSuccessCard();

    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Send a Message',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _inputField('Your Name', Icons.person_outline, _nameCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _inputField('Email Address', Icons.email_outlined, _emailCtrl)),
            ],
          ),
          const SizedBox(height: 16),
          _inputField('Subject', Icons.subject_outlined, _subjectCtrl),
          const SizedBox(height: 16),
          _inputField('Your Message', Icons.message_outlined, _msgCtrl, lines: 5),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _submitted = true);
              },
              icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
              label: const Text('Send Message',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String hint, IconData icon, TextEditingController ctrl, {int lines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555566), fontSize: 14),
        prefixIcon: lines == 1 ? Icon(icon, color: const Color(0xFF555566), size: 18) : null,
        filled: true,
        fillColor: const Color(0xFF0D0D14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF69FF47).withOpacity(0.08), const Color(0xFF00E5FF).withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF69FF47).withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF69FF47), size: 72),
          const SizedBox(height: 24),
          const Text('Message Sent!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 12),
          const Text(
            'Thank you for reaching out. Our team will get back to you within 24 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFB0B0C0), fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 28),
          TextButton(
            onPressed: () => setState(() => _submitted = false),
            child: const Text('Send Another', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
