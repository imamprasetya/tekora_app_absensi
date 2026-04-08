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
  bool obscurePassword = true;

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
      if (!mounted) return;
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

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Register berhasil")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (mounted) setState(() => isLoading = false);
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColor.primary.withOpacity(0.7)),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColor.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white12 : AppColor.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColor.primary.withOpacity(0.7)),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColor.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white12 : AppColor.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: isLoadingData
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Logo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/image/logo_tekora.png',
                          width: 60,
                          height: 60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Join Tekora Attendance System",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),

                        const SizedBox(height: 30),

                        // Card Form
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Name
                              TextField(
                                controller: nameController,
                                style: TextStyle(color: textColor),
                                decoration: _inputDecoration("Full Name", Icons.person_outline, isDark),
                              ),
                              const SizedBox(height: 14),

                              // Email
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: textColor),
                                decoration: _inputDecoration("Email Address", Icons.email_outlined, isDark),
                              ),
                              const SizedBox(height: 14),

                              // Password
                              TextField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                style: TextStyle(color: textColor),
                                decoration: _inputDecoration("Password", Icons.lock_outline, isDark).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() => obscurePassword = !obscurePassword),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Gender
                              DropdownButtonFormField<String>(
                                decoration: _dropdownDecoration("Jenis Kelamin", Icons.wc_outlined, isDark),
                                dropdownColor: cardColor,
                                items: ["L", "P"]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e == "L" ? "Laki-laki" : "Perempuan",
                                          style: TextStyle(color: textColor),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => selectedGender = val,
                              ),
                              const SizedBox(height: 14),

                              // Batch
                              DropdownButtonFormField<int>(
                                decoration: _dropdownDecoration("Batch", Icons.groups_outlined, isDark),
                                dropdownColor: cardColor,
                                value: selectedBatch,
                                items: batchList.map((item) {
                                  return DropdownMenuItem<int>(
                                    value: item['id'],
                                    child: Text(
                                      item['name'] ?? "Batch ${item['id']}",
                                      style: TextStyle(color: textColor),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => selectedBatch = val);
                                },
                              ),
                              const SizedBox(height: 14),

                              // Training
                              DropdownButtonFormField<int>(
                                decoration: _dropdownDecoration("Training", Icons.school_outlined, isDark),
                                dropdownColor: cardColor,
                                value: selectedTraining,
                                items: trainingList.map((item) {
                                  return DropdownMenuItem<int>(
                                    value: item['id'],
                                    child: Text(
                                      item['jurusan'] ??
                                          item['name'] ??
                                          item['title'] ??
                                          "Training ${item['id']}",
                                      style: TextStyle(color: textColor),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => selectedTraining = val);
                                },
                              ),

                              const SizedBox(height: 24),

                              // Register Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: AppColor.primary.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: isLoading ? null : handleRegister,
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          "Create Account",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: Text(
                              "Login",
                              style: TextStyle(
                                color: AppColor.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
        ),
    );
  }
}
