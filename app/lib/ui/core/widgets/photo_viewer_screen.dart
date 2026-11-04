import 'package:flutter/material.dart';

import 'pothole_photo.dart';

class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({super.key, required this.photoUrl, this.title});

  final String photoUrl;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title ?? 'Foto del bache'),
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: PotholePhoto(
              photoUrl: photoUrl,
              fit: BoxFit.contain,
              darkPlaceholder: true,
            ),
          ),
        ),
      ),
    );
  }
}
