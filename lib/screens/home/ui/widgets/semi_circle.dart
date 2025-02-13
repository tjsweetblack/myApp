import 'package:flutter/material.dart';

class SemicircleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String logoAsset;
  final Color backgroundColor;
  final double size;
  final String text;

  const SemicircleButton({
    Key? key,
    required this.onPressed,
    required this.logoAsset,
    required this.text,
    this.backgroundColor = Colors.orange,
    this.size = 70.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.vertical(top: Radius.circular(size / 2)),
      child: SizedBox(
        width: size,
        height: size / 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(size / 2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 5,
                    spreadRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: CustomPaint(
                size: Size(size, size / 2),
                painter: SemicirclePainter(backgroundColor),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size * 0.05),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Add this
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: size * 0.15, // Fixed height for image
                    child: Image.asset(
                      logoAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: size * 0.02),
                  Flexible(
                    // Wrap text in Flexible
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: size * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SemicirclePainter extends CustomPainter {
  final Color color;

  SemicirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final radius = size.width / 2; // Calculate radius based on width

    final path = Path()
      ..moveTo(0, radius) // Start at the left edge, middle vertically
      ..arcToPoint(Offset(size.width, radius),
          radius: Radius.circular(radius), clockwise: true) // Semicircle arc
      ..lineTo(size.width, size.height) // Line to bottom-right
      ..lineTo(0, size.height) // Line to bottom-left
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
