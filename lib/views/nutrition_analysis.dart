import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'package:mobile_application_development/views/widgets/custom_bottom_nav_bar.dart';

void main() {
  runApp(const NutritionApp());
}

class NutritionApp extends StatelessWidget {
  const NutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition Analysis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.nutritionDarkBg,
      ),
      home: const NutritionScreen(),
    );
  }
}

class NutritionScreen extends StatefulWidget {
  final int? initialNavIndex;

  const NutritionScreen({super.key, this.initialNavIndex});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 1; // Weekly selected by default
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _selectedNavIndex = 2; // Default to Diet (nutrition) tab

  final List<double> _calorieData = [
    1800, 2000, 1600, 1900, 2400, 2600, 2100
  ];
  final List<String> _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex ?? 2;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    // Navigate to the appropriate page based on index
    // This will be handled by the parent navigation context
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nutritionDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildCalorieTrendCard(),
                      const SizedBox(height: 14),
                      _buildMacroCard(),
                      const SizedBox(height: 14),
                      _buildSummaryCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: _onNavTapped,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.chevron_left, color: AppColors.nutritionNeonGreen, size: 26),
          ),
          const SizedBox(width: 4),
          const Text(
            'Nutrition Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.nutritionCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: ['Daily', 'Weekly', 'Monthly'].asMap().entries.map((e) {
            final isSelected = e.key == _selectedTab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.nutritionNeonGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.nutritionDarkBg
                          : AppColors.nutritionSubtleText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCalorieTrendCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Daily Calorie Trend',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.nutritionNeonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.trending_up, color: AppColors.nutritionNeonGreen, size: 13),
                    SizedBox(width: 3),
                    Text(
                      '+5%',
                      style: TextStyle(
                        color: AppColors.nutritionNeonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '2,100',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Text(
            'kcal avg',
            style: TextStyle(
              color: AppColors.nutritionSubtleText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _CalorieChartPainter(data: _calorieData),
              size: const Size(double.infinity, 110),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _days
                .map((d) => Text(
              d,
              style: TextStyle(
                color: AppColors.nutritionSubtleText,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMacroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macro Distribution',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutChartPainter(),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _macroLegendRow(AppColors.nutritionNeonGreen, 'Carbs', '50%'),
                    const SizedBox(height: 14),
                    _macroLegendRow(AppColors.nutritionPurple, 'Protein', '25%'),
                    const SizedBox(height: 14),
                    _macroLegendRow(AppColors.nutritionCyan, 'Fat', '25%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroLegendRow(Color color, String label, String pct) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        Text(pct,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.nutritionCardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Summary',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.nutritionNeonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'On track',
                  style: TextStyle(
                    color: AppColors.nutritionNeonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Average',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Target: 2,250 kcal',
                    style: TextStyle(color: AppColors.nutritionSubtleText, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '2,100',
                    style: TextStyle(
                      color: AppColors.nutritionNeonGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '93% of goal',
                    style: TextStyle(
                      color: AppColors.nutritionSubtleText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.93,
              backgroundColor: AppColors.nutritionProgressBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.nutritionNeonGreen),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Painters ---

class _CalorieChartPainter extends CustomPainter {
  final List<double> data;
  _CalorieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = maxVal - minVal;

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y = size.height - ((data[i] - minVal) / range) * (size.height * 0.8) - size.height * 0.05;
      points.add(Offset(x, y));
    }

    // Build smooth path using cubic bezier
    final linePath = Path();
    final fillPath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) / 2,
        points[i].dy,
      );
      final cp2 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) / 2,
        points[i + 1].dy,
      );
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.nutritionNeonGreen.withOpacity(0.35),
          AppColors.nutritionNeonGreen.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Line stroke
    final linePaint = Paint()
      ..color = AppColors.nutritionNeonGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Highlight dot on last point
    final dotPaint = Paint()..color = AppColors.nutritionNeonGreen;
    canvas.drawCircle(points.last, 5, dotPaint);
    canvas.drawCircle(
      points.last,
      5,
      Paint()
        ..color = AppColors.nutritionNeonGreen.withOpacity(0.3)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 14.0;

    final segments = [
      (0.50, AppColors.nutritionNeonGreen),   // Carbs 50%
      (0.25, AppColors.nutritionPurple),      // Protein 25%
      (0.25, AppColors.nutritionCyan),        // Fat 25%
    ];

    double startAngle = -pi / 2;
    const gap = 0.03;

    for (final seg in segments) {
      final sweepAngle = seg.$1 * 2 * pi - gap;
      final paint = Paint()
        ..color = seg.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle + gap;
    }

    // Center text
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Total\n',
        style: TextStyle(
          color: AppColors.nutritionSubtleText,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: '100%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
