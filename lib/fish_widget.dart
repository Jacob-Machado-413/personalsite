import 'dart:math';
import 'package:flutter/material.dart';

class FishPainter extends CustomPainter {
  final Color color;
  final double phase; // controls the tail wriggle
  final bool hasEyes;

  FishPainter({required this.color, required this.phase, this.hasEyes = true});

  @override
  void paint(Canvas canvas, Size size) {
    drawFish(canvas, size, color, phase, hasEyes);
  }

  static void drawFish(Canvas canvas, Size size, Color color, double phase, bool hasEyes) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // A traveling sine wave down the length of the fish body gives realistic swimming
    double headWriggle = sin(phase + 1.5) * (size.height / 8); 
    double midWriggle = sin(phase + 0.7) * (size.height / 5);
    double tailWriggle = sin(phase) * (size.height / 2.5);

    final path = Path();
    
    // Nominal horizontal distances
    double dHead = size.width * 0.35; // 0.8 - 0.45
    double dTail = size.width * 0.35; // 0.45 - 0.1
    
    double midX = size.width * 0.45;
    double midY = (size.height / 2) + midWriggle;

    // Calculate X to maintain constant distance along spine
    double headYDiff = headWriggle - midWriggle;
    double headX = midX + sqrt(max(0.0, dHead * dHead - headYDiff * headYDiff));
    double headY = (size.height / 2) + headWriggle;

    double tailYDiff = tailWriggle - midWriggle;
    double tailX = midX - sqrt(max(0.0, dTail * dTail - tailYDiff * tailYDiff));
    double tailY = (size.height / 2) + tailWriggle;

    // Tangent vectors for joints
    double hdx = headX - midX;
    double hdy = headY - midY;
    double hLen = sqrt(max(0.0001, hdx*hdx + hdy*hdy));
    double hUx = hdx / hLen;
    double hUy = hdy / hLen;
    // Top normal (points to -Y side relative to forwards vector)
    double hNx = hUy;
    double hNy = -hUx;

    double mdx = headX - tailX;
    double mdy = headY - tailY;
    double mLen = sqrt(max(0.0001, mdx*mdx + mdy*mdy));
    double mUx = mdx / mLen;
    double mUy = mdy / mLen;
    double mNx = mUy;
    double mNy = -mUx;

    double tdx = midX - tailX;
    double tdy = midY - tailY;
    double tLen = sqrt(max(0.0001, tdx*tdx + tdy*tdy));
    double tUx = tdx / tLen;
    double tUy = tdy / tLen;
    double tNx = tUy;
    double tNy = -tUx;

    // Control point thicknesses
    double headThick = size.height * 0.15;
    double midThick = size.height * 0.25;
    double tailThick = size.height * 0.1;

    // Top points
    double headTopX = headX + hNx * headThick;
    double headTopY = headY + hNy * headThick;
    double midTopX = midX + mNx * midThick;
    double midTopY = midY + mNy * midThick;
    double tailTopX = tailX + tNx * tailThick;
    double tailTopY = tailY + tNy * tailThick;

    // Bottom points
    double headBotX = headX - hNx * headThick;
    double headBotY = headY - hNy * headThick;
    double midBotX = midX - mNx * midThick;
    double midBotY = midY - mNy * midThick;
    double tailBotX = tailX - tNx * tailThick;
    double tailBotY = tailY - tNy * tailThick;

    // Tail fin points
    double tipTopX = tailX - tUx * (size.width * 0.1) + tNx * (size.height * 0.2);
    double tipTopY = tailY - tUy * (size.width * 0.1) + tNy * (size.height * 0.2);
    double tipBotX = tailX - tUx * (size.width * 0.1) - tNx * (size.height * 0.2);
    double tipBotY = tailY - tUy * (size.width * 0.1) - tNy * (size.height * 0.2);

    double finCtrlTopX = tailX - tUx * (size.width * 0.05) + tNx * (size.height * 0.15);
    double finCtrlTopY = tailY - tUy * (size.width * 0.05) + tNy * (size.height * 0.15);
    double finCtrlBotX = tailX - tUx * (size.width * 0.05) - tNx * (size.height * 0.15);
    double finCtrlBotY = tailY - tUy * (size.width * 0.05) - tNy * (size.height * 0.15);

    // Head bulge ctrl point
    double headCtrlX = headX + hUx * (size.width * 0.25);
    double headCtrlY = headY + hUy * (size.width * 0.25);

    path.moveTo(headTopX, headTopY);
    path.quadraticBezierTo(midTopX, midTopY, tailTopX, tailTopY);
    
    // Tail fin 
    path.quadraticBezierTo(finCtrlTopX, finCtrlTopY, tipTopX, tipTopY); 
    path.lineTo(tipBotX, tipBotY); 
    path.quadraticBezierTo(finCtrlBotX, finCtrlBotY, tailBotX, tailBotY); 
    
    // Curve up to head
    path.quadraticBezierTo(midBotX, midBotY, headBotX, headBotY);
    // Round head
    path.quadraticBezierTo(headCtrlX, headCtrlY, headTopX, headTopY);
    
    canvas.drawPath(path, paint);

    // Draw Pectoral Fins (side fins near head)
    final finPaint = Paint()
      ..color = color.withValues(alpha: 200 / 255.0)
      ..style = PaintingStyle.fill;

    double finAttachTopX = headX - hUx * (size.width * 0.15) + hNx * (size.height * 0.12);
    double finAttachTopY = headY - hUy * (size.width * 0.15) + hNy * (size.height * 0.12);
    double finAttachBotX = headX - hUx * (size.width * 0.15) - hNx * (size.height * 0.12);
    double finAttachBotY = headY - hUy * (size.width * 0.15) - hNy * (size.height * 0.12);

    double leftFinTipX = finAttachTopX + hUx * (size.width * 0.05) + hNx * (size.height * 0.3);
    double leftFinTipY = finAttachTopY + hUy * (size.width * 0.05) + hNy * (size.height * 0.3);
    double leftFinCtrlX = finAttachTopX - hUx * (size.width * 0.1) + hNx * (size.height * 0.3);
    double leftFinCtrlY = finAttachTopY - hUy * (size.width * 0.1) + hNy * (size.height * 0.3);

    final leftFin = Path()
      ..moveTo(finAttachTopX, finAttachTopY)
      ..quadraticBezierTo(leftFinCtrlX, leftFinCtrlY, leftFinTipX, leftFinTipY)
      ..lineTo(finAttachTopX, finAttachTopY);
    canvas.drawPath(leftFin, finPaint);

    double rightFinTipX = finAttachBotX + hUx * (size.width * 0.05) - hNx * (size.height * 0.3);
    double rightFinTipY = finAttachBotY + hUy * (size.width * 0.05) - hNy * (size.height * 0.3);
    double rightFinCtrlX = finAttachBotX - hUx * (size.width * 0.1) - hNx * (size.height * 0.3);
    double rightFinCtrlY = finAttachBotY - hUy * (size.width * 0.1) - hNy * (size.height * 0.3);

    final rightFin = Path()
      ..moveTo(finAttachBotX, finAttachBotY)
      ..quadraticBezierTo(rightFinCtrlX, rightFinCtrlY, rightFinTipX, rightFinTipY)
      ..lineTo(finAttachBotX, finAttachBotY);
    canvas.drawPath(rightFin, finPaint);

    if (hasEyes) {
      // Eye
      final eyePaint = Paint()..color = Colors.black;
      double eye1X = headX + hUx * (size.width * 0.05) + hNx * (size.height * 0.08);
      double eye1Y = headY + hUy * (size.width * 0.05) + hNy * (size.height * 0.08);
      double eye2X = headX + hUx * (size.width * 0.05) - hNx * (size.height * 0.08);
      double eye2Y = headY + hUy * (size.width * 0.05) - hNy * (size.height * 0.08);

      canvas.drawCircle(Offset(eye1X, eye1Y), size.height * 0.04, eyePaint);
      canvas.drawCircle(Offset(eye2X, eye2Y), size.height * 0.04, eyePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FishPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.phase != phase || oldDelegate.hasEyes != hasEyes;
  }
}

class Fish extends StatelessWidget {
  final Color color;
  final double size;
  final double angle;
  final double phase;
  final bool hasEyes;

  const Fish({
    super.key,
    required this.color,
    this.size = 50.0,
    this.angle = 0.0,
    this.phase = 0.0,
    this.hasEyes = true,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(size * 1.5, size), // Flatter, longer shape for koi
        painter: FishPainter(color: color, phase: phase, hasEyes: hasEyes),
      ),
    );
  }
}
