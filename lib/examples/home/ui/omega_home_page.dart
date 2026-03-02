// lib/omega/ecosystems/home/ui/omega_home_page.dart

import 'package:flutter/material.dart';

class OmegaHomePage extends StatelessWidget {
  const OmegaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Omega Home")),
      body: const Center(
        child: Text(
          "Bienvenido al Home (Omega Architecture)",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
