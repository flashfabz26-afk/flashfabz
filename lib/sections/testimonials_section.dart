import 'package:flutter/material.dart';
import 'section_wrapper.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionWrapper(
      title: 'TESTIMONIALS',
      backgroundColor: const Color(0xFF09090D),
      
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        
        children: const [
          TestimonialCard(
            review: 'The quality of the power boards we received was outstanding. Their thermal management solutions are top tier.',
          ),
          TestimonialCard(
            review: 'Fast delivery and excellent support. They helped us iterate our prototype quickly.',
          ),
          TestimonialCard(
            review: 'Reliable manufacturing partner. We have been using 8HRPCB for all our power electronics needs.',
          ),
        ],
      ),
    );
  }
}

class TestimonialCard extends StatelessWidget {
  final String review;

  const TestimonialCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star, color: Color(0xFFFFD54F), size: 18),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '"$review"',
            style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFFB0B0C0), fontSize: 16, height: 1.6),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                radius: 20,
                child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Happy Client',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                  Text('Verified Partner', style: TextStyle(color: Color(0xFF8B8B9E), fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
