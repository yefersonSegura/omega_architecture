import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';

import '../../omega/app_semantics.dart';
import '../auth_flow.dart';
import '../models.dart';

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

    flowManager = OmegaScope.of(context).flowManager;

    flowManager.activate("authFlow");
    flow = flowManager.getFlow("authFlow") as AuthFlow;
    flow.expressions.listen((exp) {
      setState(() {
        uiState = exp.type;
        // Payload tipado: en "success" usar payloadAs<LoginSuccessPayload>()
        uiPayload = exp.type == "success"
            ? exp.payloadAs<LoginSuccessPayload>()
            : exp.payload;
      });
    });
  }

  void _login() {
    final intent = OmegaIntent.fromName(
      AppIntent.authLogin,
      payload: LoginCredentials(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      ),
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
    // uiPayload ya viene tipado por payloadAs<LoginSuccessPayload>() en el listener
    final data = uiPayload as LoginSuccessPayload?;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 20),
          Text(
            data != null
                ? "Bienvenido ${data.user["name"]}"
                : "Bienvenido",
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              flowManager.handleIntent(
                OmegaIntent.fromName(AppIntent.authLogout),
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
