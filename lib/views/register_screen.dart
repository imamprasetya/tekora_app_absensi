import 'package:flutter/material.dart';
import 'package:tekora_app_absensi/services/api/get_batch.dart';
import 'package:tekora_app_absensi/services/api/get_trainings.dart';
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

  List<dynamic> batchList = [];
  List<dynamic> trainingList = [];

  bool isLoading = false;
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    loadDropdownData();
  }

  Future<void> loadDropdownData() async {
    try {
      final batches = await getBatch();
      final trainings = await getTraining();

      setState(() {
        batchList = batches;
        trainingList = trainings;
        isLoadingData = false;
      });
    } catch (e) {
      setState(() => isLoadingData = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal load data: $e")));
    }
  }

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
      body: isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    value: selectedBatch,
                    items: batchList.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['id'],
                        child: Text(item['name'] ?? "Batch ${item['id']}"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedBatch = val;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // TRAINING (FIX DI SINI)
                  DropdownButtonFormField<int>(
                    hint: const Text("Training"),
                    value: selectedTraining,
                    items: trainingList.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['id'],
                        child: Text(
                          item['jurusan'] ??
                              item['name'] ??
                              item['title'] ??
                              "Training ${item['id']}",
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedTraining = val;
                      });
                    },
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
