import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  final String? text;

  const LoadingDialog({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            if (text != null) Text(text!),
          ],
        ),
      ),
    );
  }
}

class CustomLoader {
  static void show(BuildContext context, {String? text}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(text: text),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
