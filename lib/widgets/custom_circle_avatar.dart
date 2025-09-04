import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/avatar_frame.dart';

/// カスタムCircleAvatarウィジェット（フレーム付き）
class CustomCircleAvatar extends StatefulWidget {
  final String? frameId;
  final Widget? child;
  final String? backgroundImage;
  final Color? backgroundColor;
  final double radius;
  final String? heroTag;
  final Widget Function(double size)? designBuilder;

  const CustomCircleAvatar({
    super.key,
    this.frameId,
    this.child,
    this.backgroundImage,
    this.backgroundColor,
    this.radius = 20,
    this.heroTag,
    this.designBuilder,
  });

  @override
  State<CustomCircleAvatar> createState() => _CustomCircleAvatarState();
}

class _CustomCircleAvatarState extends State<CustomCircleAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // アニメーションが必要なフレームの場合のみアニメーションを開始
    final frame = AvatarFrames.getById(widget.frameId ?? '');
    if (frame?.hasAnimation == true) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = AvatarFrames.getById(widget.frameId ?? '');
    
    Widget avatarContent;
    if (widget.designBuilder != null) {
      avatarContent = widget.designBuilder!(widget.radius * 1.2);
    } else {
      avatarContent = widget.child ?? Container();
    }
    
    Widget avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: widget.backgroundImage != null
          ? NetworkImage(widget.backgroundImage!)
          : null,
      child: widget.designBuilder != null ? avatarContent : widget.child,
    );

    if (widget.heroTag != null) {
      avatar = Hero(
        tag: widget.heroTag!,
        child: avatar,
      );
    }

    if (frame == null || frame.style == FrameStyle.none) {
      return avatar;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _FramePainter(
            frame: frame,
            radius: widget.radius,
            pulseValue: _pulseAnimation.value,
            rotationValue: _rotationAnimation.value,
            shimmerValue: _shimmerAnimation.value,
          ),
          child: Padding(
            padding: EdgeInsets.all(frame.hasAnimation ? 4.0 : 2.0),
            child: avatar,
          ),
        );
      },
    );
  }
}

/// フレーム描画用のCustomPainter
class _FramePainter extends CustomPainter {
  final AvatarFrame frame;
  final double radius;
  final double pulseValue;
  final double rotationValue;
  final double shimmerValue;

  _FramePainter({
    required this.frame,
    required this.radius,
    required this.pulseValue,
    required this.rotationValue,
    required this.shimmerValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final effectiveRadius = radius + (frame.hasAnimation ? 4 : 2);
    final paint = Paint()..style = PaintingStyle.stroke;

    switch (frame.style) {
      case FrameStyle.none:
        break;

      case FrameStyle.simple:
        paint
          ..color = frame.primaryColor
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, effectiveRadius, paint);
        break;

      case FrameStyle.classic:
        paint
          ..color = frame.primaryColor
          ..strokeWidth = 3;
        canvas.drawCircle(center, effectiveRadius, paint);
        break;

      case FrameStyle.soft:
        paint
          ..color = frame.primaryColor.withValues(alpha: 0.6)
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(center, effectiveRadius, paint);
        break;

      case FrameStyle.modern:
        final rrect = RRect.fromRectAndRadius(
          Rect.fromCircle(center: center, radius: effectiveRadius),
          const Radius.circular(12),
        );
        paint
          ..color = frame.primaryColor
          ..strokeWidth = 2.5;
        canvas.drawRRect(rrect, paint);
        break;

      case FrameStyle.elegant:
        paint
          ..color = frame.primaryColor
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, effectiveRadius, paint);
        paint.strokeWidth = 0.5;
        canvas.drawCircle(center, effectiveRadius - 2, paint);
        canvas.drawCircle(center, effectiveRadius + 2, paint);
        break;

      case FrameStyle.pop:
        paint.strokeWidth = 3;
        // ドット柄を描画
        for (int i = 0; i < 12; i++) {
          final angle = (i * 30) * math.pi / 180;
          final dotCenter = Offset(
            center.dx + effectiveRadius * math.cos(angle),
            center.dy + effectiveRadius * math.sin(angle),
          );
          paint.color = HSVColor.fromAHSV(1, (i * 30) % 360, 0.8, 0.9).toColor();
          canvas.drawCircle(dotCenter, 2, paint..style = PaintingStyle.fill);
        }
        break;

      case FrameStyle.gradient:
        final gradient = SweepGradient(
          colors: [
            frame.primaryColor,
            frame.secondaryColor!,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            frame.primaryColor,
          ],
          transform: GradientRotation(rotationValue),
        );
        paint
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: effectiveRadius),
          )
          ..strokeWidth = 3;
        canvas.drawCircle(center, effectiveRadius, paint);
        break;

      case FrameStyle.neon:
        final neonRadius = effectiveRadius * pulseValue;
        paint
          ..color = frame.primaryColor.withValues(alpha: 0.8)
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
        canvas.drawCircle(center, neonRadius, paint);
        paint
          ..color = frame.secondaryColor!
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
        canvas.drawCircle(center, neonRadius, paint);
        break;

      case FrameStyle.japanese:
        paint
          ..color = frame.primaryColor
          ..strokeWidth = 3;
        // 和風の菱形パターン
        for (int i = 0; i < 8; i++) {
          final angle = (i * 45) * math.pi / 180;
          final start = Offset(
            center.dx + (effectiveRadius - 5) * math.cos(angle),
            center.dy + (effectiveRadius - 5) * math.sin(angle),
          );
          final end = Offset(
            center.dx + (effectiveRadius + 5) * math.cos(angle),
            center.dy + (effectiveRadius + 5) * math.sin(angle),
          );
          canvas.drawLine(start, end, paint);
        }
        break;

      case FrameStyle.cyber:
        paint
          ..color = frame.primaryColor
          ..strokeWidth = 2;
        // デジタル風の点線
        final dashCount = 16;
        for (int i = 0; i < dashCount; i++) {
          final startAngle = (i * 2 * math.pi / dashCount) + rotationValue;
          final endAngle = startAngle + (math.pi / dashCount);
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: effectiveRadius),
            startAngle,
            endAngle - startAngle,
            false,
            paint,
          );
        }
        break;

      case FrameStyle.floral:
        paint
          ..color = frame.primaryColor
          ..strokeWidth = 2;
        // 花びらパターン
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60) * math.pi / 180;
          final petalCenter = Offset(
            center.dx + (effectiveRadius * 0.7) * math.cos(angle),
            center.dy + (effectiveRadius * 0.7) * math.sin(angle),
          );
          canvas.drawCircle(petalCenter, 8, paint);
        }
        break;

      case FrameStyle.diamond:
        paint
          ..color = frame.primaryColor
          ..strokeWidth = 2;
        // キラキラエフェクト
        for (int i = 0; i < 8; i++) {
          final angle = (i * 45 + rotationValue * 180 / math.pi) * math.pi / 180;
          final sparkleLength = 3 + 2 * math.sin(shimmerValue * 2 * math.pi);
          final start = Offset(
            center.dx + (effectiveRadius - sparkleLength) * math.cos(angle),
            center.dy + (effectiveRadius - sparkleLength) * math.sin(angle),
          );
          final end = Offset(
            center.dx + (effectiveRadius + sparkleLength) * math.cos(angle),
            center.dy + (effectiveRadius + sparkleLength) * math.sin(angle),
          );
          paint.color = frame.primaryColor.withValues(alpha: 0.5 + 0.5 * shimmerValue);
          canvas.drawLine(start, end, paint);
        }
        break;

      case FrameStyle.fire:
        // 炎エフェクト
        for (int i = 0; i < 12; i++) {
          final angle = (i * 30) * math.pi / 180;
          final flameHeight = 3 + 2 * math.sin(rotationValue + i);
          final flameBase = Offset(
            center.dx + effectiveRadius * math.cos(angle),
            center.dy + effectiveRadius * math.sin(angle),
          );
          final flameTip = Offset(
            center.dx + (effectiveRadius + flameHeight) * math.cos(angle),
            center.dy + (effectiveRadius + flameHeight) * math.sin(angle),
          );
          
          paint
            ..color = Color.lerp(frame.primaryColor, frame.secondaryColor!, 
                (flameHeight - 3) / 2)!.withValues(alpha: 0.8)
            ..strokeWidth = 2;
          canvas.drawLine(flameBase, flameTip, paint);
        }
        break;

      case FrameStyle.water:
        // 波紋エフェクト
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (int i = 0; i < 3; i++) {
          final waveRadius = effectiveRadius + i * 3 * pulseValue;
          paint.color = frame.primaryColor.withValues(alpha: 1.0 - i * 0.3);
          canvas.drawCircle(center, waveRadius, paint);
        }
        break;

      case FrameStyle.star:
        // 回転する星
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(rotationValue);
        paint
          ..color = frame.primaryColor
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;
        
        final path = Path();
        for (int i = 0; i < 10; i++) {
          final radius = i.isEven ? effectiveRadius : effectiveRadius * 0.6;
          final angle = (i * 36 - 90) * math.pi / 180;
          final point = Offset(radius * math.cos(angle), radius * math.sin(angle));
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.restore();
        break;

      case FrameStyle.waseda:
        // 早稲田カラーの二重線
        paint
          ..color = frame.primaryColor
          ..strokeWidth = 3;
        canvas.drawCircle(center, effectiveRadius, paint);
        paint
          ..color = frame.secondaryColor!
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, effectiveRadius - 3, paint);
        break;

      case FrameStyle.platinum:
        // プラチナの光沢
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            frame.primaryColor,
            Colors.grey.shade400,
            frame.primaryColor,
          ],
        );
        paint
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: effectiveRadius),
          )
          ..strokeWidth = 3;
        canvas.drawCircle(center, effectiveRadius, paint);
        break;

      case FrameStyle.hologram:
        // ホログラム効果
        final hologramGradient = SweepGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.indigo,
            Colors.purple,
            Colors.red,
          ],
          transform: GradientRotation(rotationValue),
        );
        paint
          ..shader = hologramGradient.createShader(
            Rect.fromCircle(center: center, radius: effectiveRadius),
          )
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2);
        canvas.drawCircle(center, effectiveRadius * pulseValue, paint);
        break;

      case FrameStyle.master:
        // マスターフレーム（複雑なアニメーション）
        paint.strokeWidth = 3;
        
        // 外側の回転リング
        final outerGradient = SweepGradient(
          colors: [
            Colors.black,
            Colors.grey.shade800,
            Colors.black,
          ],
          transform: GradientRotation(rotationValue),
        );
        paint.shader = outerGradient.createShader(
          Rect.fromCircle(center: center, radius: effectiveRadius),
        );
        canvas.drawCircle(center, effectiveRadius, paint);
        
        // 内側の逆回転リング
        final innerGradient = SweepGradient(
          colors: [
            const Color(0xFFFFD700), // Gold
            Colors.amber,
            const Color(0xFFFFD700), // Gold
          ],
          transform: GradientRotation(-rotationValue),
        );
        paint
          ..shader = innerGradient.createShader(
            Rect.fromCircle(center: center, radius: effectiveRadius - 3),
          )
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, effectiveRadius - 3, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.rotationValue != rotationValue ||
        oldDelegate.shimmerValue != shimmerValue ||
        oldDelegate.frame != frame;
  }
}