import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Placeholder Screen'),
      ),
      body: Center(
        child: Text('This is a placeholder screen.'),
      ),
    );
  }
}
