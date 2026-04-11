import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';

import '../../omega/app_runtime_ids.dart';

class ProviderPage extends StatelessWidget {
  const ProviderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OmegaFlowActivator(
      flowId: AppFlowId.Provider,
      child: Scaffold(
        appBar: AppBar(title: const Text("Provider Page")),
        body: const Center(child: Text("Provider Ecosystem")),
      ),
    );
  }
}
