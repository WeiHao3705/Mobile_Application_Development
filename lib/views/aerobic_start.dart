import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_application_development/theme/app_colors.dart';
import 'live_map.dart';

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