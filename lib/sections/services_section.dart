import 'package:flutter/material.dart';
import 'section_wrapper.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionWrapper(
      title: 'OUR SERVICES',
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth < 600
              ? 1
              : constraints.maxWidth < 1000
                  ? 2
                  : 4;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.88,
            children: const [
              _ServiceCard(
                title: 'Power PCB Design',
                icon: Icons.design_services,
                description: 'Custom layouts optimized for thermal management, high-current paths, and power delivery integrity.',
                gradient: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                tag: 'Design',
              ),
              _ServiceCard(
                title: 'PCB Manufacturing',
                icon: Icons.precision_manufacturing,
                description: 'High-quality fabrication using FR4, Rogers, and high-TG materials with 1–16 layer capability.',
                gradient: [Color(0xFFFF6B35), Color(0xFFFF0080)],
                tag: 'Fabrication',
              ),
              _ServiceCard(
                title: 'PCB Assembly',
                icon: Icons.memory,
                description: 'SMT and through-hole assembly with AOI and X-ray inspection for prototype to volume production.',
                gradient: [Color(0xFF69FF47), Color(0xFF00B4D8)],
                tag: 'Assembly',
              ),
              _ServiceCard(
                title: 'Testing & QA',
                icon: Icons.fact_check,
                description: 'Rigorous ICT, functional testing, and burn-in procedures ensuring every board meets spec.',
                gradient: [Color(0xFFBB86FC), Color(0xFFFF6B35)],
                tag: 'Quality',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final List<Color> gradient;
  final String tag;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.gradient,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      gradient[0].withOpacity(0.15),
                      gradient[1].withOpacity(0.08),
                    ]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: gradient[0].withOpacity(0.2)),
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(colors: gradient)
                        .createShader(bounds),
                    child: Icon(icon, size: 30, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: gradient[0].withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gradient[0].withOpacity(0.2)),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(color: gradient[0], fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 13.5, height: 1.7),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Learn more', style: TextStyle(color: gradient[0], fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: gradient[0], size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

