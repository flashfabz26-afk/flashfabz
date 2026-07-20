import 'package:flutter/material.dart';
import 'section_wrapper.dart';

class WhyChooseUsSection extends StatelessWidget {
  const WhyChooseUsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionWrapper(
      title: 'WHY CHOOSE US',
      backgroundColor: const Color(0xFF09090D),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return isMobile ? _buildMobile() : _buildDesktop();
        },
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _FeatureItem(
          icon: Icons.engineering,
          title: 'Expert Engineers',
          description: 'Our team of certified PCB engineers with 10+ years of experience in high-power electronics.',
          color: const Color(0xFF00E5FF),
        )),
        const SizedBox(width: 20),
        Expanded(child: _FeatureItem(
          icon: Icons.verified_outlined,
          title: 'Quality Standards',
          description: 'ISO 9001:2015 certified processes with full traceability and IPC Class 2/3 compliance.',
          color: const Color(0xFFFFD54F),
        )),
        const SizedBox(width: 20),
        Expanded(child: _FeatureItem(
          icon: Icons.local_shipping_outlined,
          title: 'Fast Delivery',
          description: 'Express 5–7 day turnaround with real-time production tracking via our customer portal.',
          color: const Color(0xFF69FF47),
        )),
        const SizedBox(width: 20),
        Expanded(child: _FeatureItem(
          icon: Icons.support_agent_outlined,
          title: '24/7 Support',
          description: 'Dedicated engineering support team available around the clock for your critical projects.',
          color: const Color(0xFFBB86FC),
        )),
      ],
    );
  }

  Widget _buildMobile() {
    return Column(
      children: [
        _FeatureItem(
          icon: Icons.engineering,
          title: 'Expert Engineers',
          description: 'Our team of certified PCB engineers with 10+ years of experience in high-power electronics.',
          color: const Color(0xFF00E5FF),
        ),
        const SizedBox(height: 16),
        _FeatureItem(
          icon: Icons.verified_outlined,
          title: 'Quality Standards',
          description: 'ISO 9001:2015 certified processes with full traceability and IPC Class 2/3 compliance.',
          color: const Color(0xFFFFD54F),
        ),
        const SizedBox(height: 16),
        _FeatureItem(
          icon: Icons.local_shipping_outlined,
          title: 'Fast Delivery',
          description: 'Express 5–7 day turnaround with real-time production tracking via our customer portal.',
          color: const Color(0xFF69FF47),
        ),
        const SizedBox(height: 16),
        _FeatureItem(
          icon: Icons.support_agent_outlined,
          title: '24/7 Support',
          description: 'Dedicated engineering support team available around the clock for your critical projects.',
          color: const Color(0xFFBB86FC),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 13.5, height: 1.7)),
          const SizedBox(height: 16),
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

