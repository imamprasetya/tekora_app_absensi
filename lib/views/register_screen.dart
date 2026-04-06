import 'package:flutter/material.dart';
import 'package:tekora_app_absensi/services/auth/register_service.dart';
import 'package:tekora_app_absensi/utils/app_colors.dart';
import 'package:tekora_app_absensi/views/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? selectedGender;
  int? selectedBatch;
  int? selectedTraining;

  bool isLoading = false;

  Future<void> handleRegister() async {
    if (selectedGender == null ||
        selectedBatch == null ||
        selectedTraining == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field harus diisi")));
      return;
    }

    setState(() => isLoading = true);

    try {
      await register(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        jenisKelamin: selectedGender!,
        batchId: selectedBatch!,
        trainingId: selectedTraining!,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Register berhasil")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset('assets/image/logo_tekora.png', width: 120),

            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 16),

            // JENIS KELAMIN
            DropdownButtonFormField<String>(
              hint: const Text("Jenis Kelamin"),
              items: ["L", "P"]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e == "L" ? "Laki-laki" : "Perempuan"),
                    ),
                  )
                  .toList(),
              onChanged: (val) => selectedGender = val,
            ),

            const SizedBox(height: 16),

            // BATCH
            DropdownButtonFormField<int>(
              hint: const Text("Batch"),
              items: [1, 2, 3]
                  .map(
                    (e) => DropdownMenuItem(value: e, child: Text("Batch $e")),
                  )
                  .toList(),
              onChanged: (val) => selectedBatch = val,
            ),

            const SizedBox(height: 16),

            // TRAINING
            DropdownButtonFormField<int>(
              hint: const Text("Training"),
              items: [1, 2, 3]
                  .map(
                    (e) =>
                        DropdownMenuItem(value: e, child: Text("Training $e")),
                  )
                  .toList(),
              onChanged: (val) => selectedTraining = val,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : handleRegister,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Create Account"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
