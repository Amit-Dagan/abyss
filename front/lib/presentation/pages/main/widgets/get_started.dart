import 'package:flutter/material.dart';
import 'package:todo_list/core/style/app_colors.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GetStartedText(text: 'Looks like you don\'t have any tasks yet', fontSize: 24),
          SizedBox(height: 30),
          GetStartedText(text: 'Tap the + button to add your first task', fontSize: 16),
        ],
      ),
    );
  }
}

class GetStartedText extends StatelessWidget {
  final String text;
  final double fontSize;

  const GetStartedText({
    super.key, required this.text, required this.fontSize,
  });
  
  @override
  Widget build(BuildContext context) {
    return Text(text, 
    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold,color: AppColors.primaryColor),
    textAlign: TextAlign.center,);
  }
}