import 'package:flutter/material.dart';
import 'package:hoopster/screens/recording_screen.dart';
import 'package:hoopster/screens/stats_screen.dart';
import 'package:hoopster/screens/settings_screen.dart';
import 'package:hoopster/screens/about_screen.dart';

class HomeScreen extends StatelessWidget {
  final firstCamera;

  const HomeScreen(this.firstCamera);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildButton(
                context,
                'Start Recording',
                RecordingScreen(
                  camera: firstCamera,
                )),
            _buildButton(context, 'View Stats', StatsScreen()),
            _buildButton(context, 'Settings', SettingsScreen()),
            _buildButton(context, 'About', AboutScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Widget screen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Text(text),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          textStyle: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
