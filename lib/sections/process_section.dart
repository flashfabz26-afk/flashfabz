import 'package:flutter/material.dart';
import 'section_wrapper.dart';


class ProcessSection extends StatelessWidget {
  const ProcessSection({super.key});

  @override
  Widget build(BuildContext context) {
   
    final processes = [
      'Requirement\nAnalysis',
      'PCB\nDesign',
      'Prototype\nDevelopment',
      'Manufacturing\nPhase',
      'Testing &\nDelivery',
    ];

    return SectionWrapper(
      title: 'OUR PROCESS',
      
     
  
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, 
        
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
        
          children: processes.asMap().entries.map((entry) {
            int idx = entry.key; 
            String text = entry.value; 
           
            bool isLast = idx == processes.length - 1;

            return Row(
              children: [
                
                ProcessStep(stepNumber: idx + 1, title: text),
                
             
                if (!isLast)
                  Container(
                    width: 60,
                    height: 2,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    margin: const EdgeInsets.only(bottom: 50, left: 16, right: 16),
                  ),
              ],
            );
          }).toList(), 
        ),
      ),
    );
  }
}

class ProcessStep extends StatefulWidget {
  final int stepNumber;
  final String title;

  const ProcessStep({super.key, required this.stepNumber, required this.title});

  @override
  State<ProcessStep> createState() => _ProcessStepState();
}

class _ProcessStepState extends State<ProcessStep> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: SizedBox(
        width: 140, 
        child: Column(
          children: [
           
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
             
              width: isHovered ? 80 : 70,
              height: isHovered ? 80 : 70,
              
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHovered ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                
                
                border: Border.all(
                  color: isHovered ? Colors.transparent : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  width: 2,
                ),
                
               
                boxShadow: isHovered ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 15)] : [],
              ),
              alignment: Alignment.center, 
              
              child: Text(
                '0${widget.stepNumber}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
          
                  color: isHovered ? Colors.black : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
                     Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
