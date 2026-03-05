import 'package:flutter/material.dart';
import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';
import 'package:omega_architecture/omega/flows/omega_flow_manager.dart';
import 'package:omega_architecture/omega/ui/flutter/omega_scope.dart';

import '../auth_flow.dart';

class OmegaLoginPage extends StatefulWidget {
  const OmegaLoginPage({super.key});

  @override
  State<OmegaLoginPage> createState() => _OmegaLoginPageState();
}

class _OmegaLoginPageState extends State<OmegaLoginPage> {
  late AuthFlow flow;
  late OmegaFlowManager flowManager;

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String uiState = "idle";
  dynamic uiPayload;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Obtener FlowManager desde OmegaScope
    flowManager = OmegaScope.of(context).flowManager;

    // Obtener el flow
    flow = flowManager.getFlow("authFlow") as AuthFlow;

    // escuchar expresiones del Flow
    flow.expressions.listen((exp) {
      setState(() {
        uiState = exp.type;
        uiPayload = exp.payload;
      });
    });
  }

  void _login() {
    final intent = OmegaIntent(
      id: "loginIntent",
      name: "auth.login",
      payload: {
        "email": emailCtrl.text.trim(),
        "password": passCtrl.text.trim(),
      },
    );

    flowManager.handleIntent(intent);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    switch (uiState) {
      case "idle":
        body = _buildLoginForm();
        break;

      case "loading":
        body = const Center(child: CircularProgressIndicator());
        break;

      case "success":
        body = _buildSuccess();
        break;

      case "error":
        body = _buildError();
        break;

      default:
        body = _buildLoginForm();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Omega Login")),
      body: body,
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Password"),
          ),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _login, child: const Text("Login (Omega)")),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            uiPayload?.toString() ?? "Error desconocido",
            style: const TextStyle(color: Colors.red, fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              flow.emitExpression("idle");
            },
            child: const Text("Volver"),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 20),
          Text(
            "Bienvenido ${uiPayload["user"]["name"]}",
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              flowManager.handleIntent(
                OmegaIntent(id: "logoutIntent", name: "auth.logout"),
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
