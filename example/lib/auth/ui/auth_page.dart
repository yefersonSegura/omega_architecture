import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';

import '../../omega/app_semantics.dart';
import '../auth_agent.dart';
import '../auth_flow.dart';
import '../auth_events.dart';
import '../auth_state.dart';

class OmegaLoginPage extends StatefulWidget {
  const OmegaLoginPage({super.key, required this.authAgent});

  final AuthAgent authAgent;

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
        // UI state is driven by the flow only for semantic milestones.
        // Loading/error are rendered from AuthAgent viewState via OmegaAgentBuilder.
        uiState = exp.type == "success" ? "success" : "idle";
        uiPayload = exp.type == "success"
            ? exp.payloadAs<LoginSuccessPayload>()
            : null;
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
    final body = uiState == "success" ? _buildSuccess() : _buildLoginForm();

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
          OmegaAgentBuilder<AuthAgent, AuthViewState>(
            agent: widget.authAgent,
            builder: (context, agentState) {
              if (agentState.isLoading) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                );
              }
              if (agentState.errorMessage != null &&
                  agentState.errorMessage!.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    agentState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              return const SizedBox(height: 0);
            },
          ),
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
            data != null ? "Bienvenido ${data.user["name"]}" : "Bienvenido",
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
