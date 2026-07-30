import 'package:flutter/material.dart';

class FullImagePage extends StatelessWidget {
  final String imageUrl;

  const FullImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(backgroundColor: Colors.black),

      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
