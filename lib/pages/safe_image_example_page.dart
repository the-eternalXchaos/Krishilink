import 'package:flutter/material.dart';
import '../widgets/safe_network_image.dart';

/// Example page demonstrating SafeNetworkImage usage
class SafeImageExamplePage extends StatelessWidget {
  const SafeImageExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe Image Loading Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valid Image URL:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SafeNetworkImage(
              imageUrl: 'https://picsum.photos/300/200',
              width: 300,
              height: 200,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 24),

            const Text(
              'Empty Image URL (shows fallback):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SafeNetworkImage(
              imageUrl: '',
              width: 300,
              height: 200,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 24),

            const Text(
              'Invalid Image URL (shows error widget):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SafeNetworkImage(
              imageUrl: 'https://invalid-url-that-will-fail.com/image.jpg',
              width: 300,
              height: 200,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 24),

            const Text(
              'Circular Avatar Example:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SafeCircularNetworkImage(
                  imageUrl: 'https://picsum.photos/100/100',
                  radius: 30,
                ),
                const SizedBox(width: 16),
                SafeCircularNetworkImage(
                  imageUrl: '', // Empty URL - shows fallback
                  radius: 30,
                ),
                const SizedBox(width: 16),
                SafeCircularNetworkImage(
                  imageUrl: 'invalid-url',
                  radius: 30,
                  fallbackAsset: 'assets/images/default_avatar.png',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
