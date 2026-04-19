import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class BmiCalculatorPage extends StatefulWidget {
  const BmiCalculatorPage({
    super.key,
    this.initialWeightKg,
    this.initialHeightCm,
    this.dateOfBirth,
  });

  final double? initialWeightKg;
  final double? initialHeightCm;
  final DateTime? dateOfBirth;

  @override
  State<BmiCalculatorPage> createState() => _BmiCalculatorPageState();
}

class _BmiCalculatorPageState extends State<BmiCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;

  double? _bmi;
  String _selectedGender = 'Male'; // Default gender
  late int _currentAge;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: _formatNullable(widget.initialWeightKg),
    );
    _heightController = TextEditingController(
      text: _formatNullable(widget.initialHeightCm),
    );
    _currentAge = _computeAge(widget.dateOfBirth) ?? 25; // Default age 25 if not provided
    _ageController = TextEditingController(text: _currentAge.toString());
    _recalculate();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String _formatNullable(double? value) {
    if (value == null || value <= 0) return '';
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  void _recalculate() {
    final weight = double.tryParse(_weightController.text.trim());
    final heightRaw = double.tryParse(_heightController.text.trim());
    final age = int.tryParse(_ageController.text.trim());
    final normalizedHeightCm = _normalizeHeightCm(heightRaw);

    if (weight == null || weight <= 0 || normalizedHeightCm == null) {
      setState(() => _bmi = null);
      return;
    }

    if (age != null && age > 0) {
      _currentAge = age;
    }

    final heightMeters = normalizedHeightCm / 100;
    setState(() => _bmi = weight / (heightMeters * heightMeters));
  }

  double? _normalizeHeightCm(double? value) {
    if (value == null || value <= 0) return null;
    // Accept both cm (170) and meter input (1.70).
    return value <= 3 ? value * 100 : value;
  }

  int? _computeAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age < 0 ? null : age;
  }

  String _category(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    if (bmi < 40) return 'Obese';
    return 'Morbidly Obese';
  }

  Color _categoryColor(double bmi) {
    if (bmi < 18.5) return Colors.lightBlue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.yellow.shade700;
    if (bmi < 40) return Colors.orange;
    return Colors.red;
  }

  List<String> _suggestions(double? bmi) {
    if (bmi == null) {
      return const ['Enter your weight and height to see personalized suggestions.'];
    }

    final genderPrefix = _selectedGender == 'Female' ? 'For women' : 'For men';
    final ageGroup = _currentAge < 30 ? 'younger adults' : _currentAge < 50 ? 'middle-aged adults' : 'older adults';
    final baseAgeNote = '$genderPrefix in your age group ($ageGroup):';

    if (bmi < 18.5) {
      return [
        baseAgeNote,
        'Increase calories with nutrient-dense meals (protein + healthy fats).',
        'Do strength training 2-4 times/week to build lean mass.',
        'Track weight weekly and aim for gradual gain.',
        if (_selectedGender == 'Female') 'Women: Monitor bone health with calcium & vitamin D intake.',
        if (_selectedGender == 'Male') 'Men: Prioritize protein intake (1.6-2.2g per kg body weight).',
      ];
    }

    if (bmi < 25) {
      return [
        baseAgeNote,
        'Great range - maintain with balanced meals and regular exercise.',
        'Keep protein intake consistent to preserve muscle mass.',
        'Continue hydration and sleep habits for long-term stability.',
        if (_currentAge < 30) 'Build healthy habits now to prevent weight gain in later years.',
        if (_currentAge >= 50 && _selectedGender == 'Female') 'Monitor hormonal changes and adjust nutrition accordingly.',
        if (_currentAge >= 50 && _selectedGender == 'Male') 'Maintain muscle mass with resistance training.',
      ];
    }

    if (bmi < 30) {
      return [
        baseAgeNote,
        'Aim for a small calorie deficit (500 cal/day) and steady activity every day.',
        'Combine cardio and resistance workouts for better fat loss.',
        'Track trends weekly instead of focusing on daily fluctuations.',
        if (_selectedGender == 'Female') 'Women: Consider HIIT workouts 2-3 times per week.',
        if (_selectedGender == 'Male') 'Men: Increase strength training to maintain metabolism.',
        if (_currentAge >= 50) 'Focus on sustainable lifestyle changes rather than rapid weight loss.',
      ];
    }

    return [
      baseAgeNote,
      'Start with low-impact activity (walking, cycling) and increase gradually.',
      'Prioritize portion control and high-fiber meals to improve satiety.',
      'Consider consulting a healthcare professional for a structured plan.',
      if (_selectedGender == 'Female') 'Women: Focus on hormonal balance through nutrition.',
      if (_selectedGender == 'Male') 'Men: Aim for 30+ minutes of activity daily.',
      if (_currentAge >= 50) 'Older adults: Prevent falls and injuries with balance/flexibility exercises.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bmi = _bmi;
    final age = _computeAge(widget.dateOfBirth);

    return Scaffold(
      appBar: AppBar(title: const Text('BMI Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your BMI Indicator',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: SfRadialGauge(
                        axes: [
                          RadialAxis(
                            minimum: 12,
                            maximum: 45,
                            startAngle: 180,
                            endAngle: 0,
                            showLabels: false,
                            showTicks: false,
                            canScaleToFit: true,
                            ranges: [
                              GaugeRange(startValue: 12, endValue: 18.5, color: Colors.lightBlue, startWidth: 20, endWidth: 20),
                              GaugeRange(startValue: 18.5, endValue: 25, color: Colors.green, startWidth: 20, endWidth: 20),
                              GaugeRange(startValue: 25, endValue: 30, color: Colors.yellow.shade700, startWidth: 20, endWidth: 20),
                              GaugeRange(startValue: 30, endValue: 40, color: Colors.orange, startWidth: 20, endWidth: 20),
                              GaugeRange(startValue: 40, endValue: 45, color: Colors.red, startWidth: 20, endWidth: 20),
                            ],
                            pointers: [
                              NeedlePointer(
                                value: (bmi ?? 12).clamp(12, 45),
                                needleLength: 0.45,
                                needleStartWidth: 1,
                                needleEndWidth: 5,
                                knobStyle: const KnobStyle(knobRadius: 0.06),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // BMI Number and Category displayed below the gauge
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bmi == null ? '--' : bmi.toStringAsFixed(1),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            bmi == null ? 'No data' : _category(bmi),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: bmi == null ? theme.colorScheme.onSurfaceVariant : _categoryColor(bmi),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(label: 'Weight', value: '${_weightController.text.isEmpty ? '--' : _weightController.text} kg'),
                        _InfoChip(label: 'Height', value: '${_heightController.text.isEmpty ? '--' : _heightController.text} cm'),
                        _InfoChip(label: 'Age', value: '${_ageController.text.isEmpty ? '--' : _ageController.text}'),
                        // _InfoChip(label: 'Gender', value: _selectedGender),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Calculator',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _recalculate(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Height (cm or m)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _recalculate(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age (years)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _recalculate(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<String>(value: 'Male', child: Text('Male')),
                          DropdownMenuItem<String>(value: 'Female', child: Text('Female')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value ?? 'Male';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _recalculate,
                          child: const Text('Calculate BMI'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggestions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._suggestions(bmi).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('- $item', style: theme.textTheme.bodyMedium),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

