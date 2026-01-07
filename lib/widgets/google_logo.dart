import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;
  
  const GoogleLogo({
    Key? key,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: GoogleLogoPainter(),
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    
    // Google G shape
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Blue (bottom right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.57, 1.57, true, paint);
    
    // Red (top right)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -1.57, -1.57, true, paint);
    
    // Yellow (top left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 3.14, 1.57, true, paint);
    
    // Green (bottom left)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.57, 1.57, true, paint);
    
    // White center circle
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.6, paint);
    
    // Draw G letter
    paint.color = const Color(0xFF4285F4);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * 0.08;
    
    final gRect = Rect.fromCircle(center: center, radius: radius * 0.45);
    canvas.drawArc(gRect, 0.5, 4.5, false, paint);
    
    // G horizontal line
    paint.style = PaintingStyle.fill;
    final lineRect = Rect.fromLTWH(
      center.dx, 
      center.dy - size.width * 0.04, 
      radius * 0.35, 
      size.width * 0.08
    );
    canvas.drawRect(lineRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleLogoIcon extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  
  const GoogleLogoIcon({
    Key? key,
    this.size = 20,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(size * 0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simplified Google "G" using text
          Text(
            'G',
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4285F4),
              fontFamily: 'Arial',
            ),
          ),
        ],
      ),
    );
  }
}

// Even simpler version using just colored containers
class SimpleGoogleLogo extends StatelessWidget {
  final double size;
  
  const SimpleGoogleLogo({
    Key? key,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          // Google colors arranged in a simple pattern
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: const BoxDecoration(
                color: Color(0xFFEA4335), // Red
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: const BoxDecoration(
                color: Color(0xFFFBBC05), // Yellow
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(100),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: const BoxDecoration(
                color: Color(0xFF4285F4), // Blue
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: const BoxDecoration(
                color: Color(0xFF34A853), // Green
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(100),
                ),
              ),
            ),
          ),
          // Center white circle with G
          Center(
            child: Container(
              width: size * 0.6,
              height: size * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4285F4),
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
