import 'package:flutter/material.dart';
import 'section_wrapper.dart';

class AboutUsSection extends StatelessWidget {
  const AboutUsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return SectionWrapper(
      title: 'ABOUT US',
      backgroundColor: const Color(0xFF09090D),
      child: isMobile ? _buildMobile(context) : _buildDesktop(context),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: _buildText(context)),
        const SizedBox(width: 60),
        Expanded(flex: 4, child: _buildStatsGrid(context)),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      children: [
        _buildText(context),
        const SizedBox(height: 40),
        _buildStatsGrid(context),
      ],
    );
  }

  Widget _buildText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Built for Engineers,\nPowered by Precision.',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
        ),
        const SizedBox(height: 24),
        const Text(
          'FLASHFABZ is a premier provider of Power PCB design, manufacturing, and testing services. With a commitment to innovation and precision, we bridge the gap between complex engineering concepts and physical realization.',
          style: TextStyle(color: Color(0xFFB0B0C0), fontSize: 16, height: 1.8),
        ),
        const SizedBox(height: 16),
        const Text(
          'Our expertise ensures your high-power applications run efficiently and safely, meeting the most rigorous industry standards from IPC to ISO.',
          style: TextStyle(color: Color(0xFF8B8B9E), fontSize: 15, height: 1.8),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _badge(Icons.verified, 'ISO 9001:2015'),
            const SizedBox(width: 12),
            _badge(Icons.military_tech, 'IPC Certified'),
            const SizedBox(width: 12),
            _badge(Icons.eco, 'RoHS Compliant'),
          ],
        ),
      ],
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF00E5FF), size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: const [
        _StatCard(value: '10K+', label: 'Boards Shipped', color: Color(0xFF00E5FF)),
        _StatCard(value: '8+', label: 'Years Experience', color: Color(0xFFFFD54F)),
        _StatCard(value: '99.8%', label: 'Quality Rate', color: Color(0xFF69FF47)),
        _StatCard(value: '500+', label: 'Happy Clients', color: Color(0xFFBB86FC)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
