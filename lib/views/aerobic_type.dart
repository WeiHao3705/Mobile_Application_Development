import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'live_map.dart';
import '../controllers/auth_controller.dart';

class AerobicStartPage extends StatefulWidget {

  final int userId;
  const AerobicStartPage({super.key, required this.userId});

  @override
  State<AerobicStartPage> createState() => _AerobicStartPageState();
}

class _AerobicStartPageState extends State<AerobicStartPage> {

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LiveMap(userId: widget.userId)),
                  );
                },
                child: const Text('Start Map'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget{
  const _Header();

  @override
  Widget build(BuildContext context){
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: _iconBtn(
            child: const Icon(Icons.chevron_left, color: AppColors.lime, size: 18),
          ),
        ),
        const SizedBox(width: 3),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: const Text(
            'Choose Your Exercise',
            style: TextStyle(
              color: AppColors.lavender,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        )

      ],
    );
  }
  Widget _iconBtn({required Widget child}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lavender.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

