import 'package:flutter/material.dart';

class FooterSection extends StatelessWidget {
  final VoidCallback? onServices;
  final VoidCallback? onContact;
  final VoidCallback? onQuote;

  const FooterSection({super.key, this.onServices, this.onContact, this.onQuote});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF050508),
        border: Border(top: BorderSide(color: Color(0xFF1A1A24))),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : size.width * 0.08,
              vertical: 60,
            ),
            child: isMobile ? _buildMobile() : _buildDesktop(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: _buildBrand()),
        const SizedBox(width: 60),
        Expanded(flex: 2, child: _buildColumn('Services', [
          _FooterLink(label: 'PCB Design', onTap: onServices),
          _FooterLink(label: 'PCB Manufacturing', onTap: onServices),
          _FooterLink(label: 'PCB Assembly', onTap: onServices),
          _FooterLink(label: 'Testing & QA', onTap: onServices),
        ])),
        const SizedBox(width: 40),
        Expanded(flex: 2, child: _buildColumn('Company', [
          _FooterLink(label: 'About Us', onTap: null),
          _FooterLink(label: 'Blog', onTap: null),
          _FooterLink(label: 'Careers', onTap: null),
          _FooterLink(label: 'Partners', onTap: null),
        ])),
        const SizedBox(width: 40),
        Expanded(flex: 2, child: _buildColumn('Contact', [
          _FooterLink(label: 'Get a Quote', onTap: onQuote),
          _FooterLink(label: 'Contact Us', onTap: onContact),
          _FooterLink(label: 'Support', onTap: onContact),
          _FooterLink(label: 'Track Order', onTap: null),
        ])),
      ],
    );
  }

  Widget _buildMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrand(),
        const SizedBox(height: 40),
        _buildColumn('Services', [
          _FooterLink(label: 'PCB Design', onTap: onServices),
          _FooterLink(label: 'PCB Manufacturing', onTap: onServices),
          _FooterLink(label: 'PCB Assembly', onTap: onServices),
        ]),
        const SizedBox(height: 32),
        _buildColumn('Contact', [
          _FooterLink(label: 'Get a Quote', onTap: onQuote),
          _FooterLink(label: 'Contact Us', onTap: onContact),
          _FooterLink(label: 'Support', onTap: onContact),
        ]),
      ],
    );
  }

  Widget _buildBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0072FF)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'FLASHFABZ',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.5, color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Premium Power PCB Design & Manufacturing solutions engineered for reliability and scale.',
          style: TextStyle(color: Color(0xFF555566), fontSize: 14, height: 1.7),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['ISO 9001', 'IPC Class 2', 'RoHS', 'REACH'].map((c) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1A1A24)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(c, style: const TextStyle(color: Color(0xFF555566), fontSize: 11, fontWeight: FontWeight.w600)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColumn(String title, List<Widget> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(width: 28, height: 2, color: const Color(0xFF00E5FF)),
        const SizedBox(height: 16),
        ...links,
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1A1A24))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '© 2026 FLASHFABZ. All rights reserved.',
            style: TextStyle(color: Color(0xFF555566), fontSize: 12),
          ),
          Row(
            children: [
              _SimpleLink('Privacy Policy'),
              const SizedBox(width: 20),
              _SimpleLink('Terms of Service'),
              const SizedBox(width: 20),
              _SimpleLink('Sitemap'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleLink extends StatelessWidget {
  final String label;
  const _SimpleLink(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(color: Color(0xFF555566), fontSize: 12));
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _FooterLink({required this.label, this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              color: _hovered ? const Color(0xFF00E5FF) : const Color(0xFF555566),
              fontSize: 14,
              fontWeight: _hovered ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
