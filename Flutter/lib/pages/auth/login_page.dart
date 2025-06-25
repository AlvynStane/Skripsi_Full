import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/constants/app_strings.dart';
import 'package:skripsi/pages/auth/forget_password_page.dart';
import 'package:skripsi/providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool passwordVisible = false;

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      Provider.of<MyAuthProvider>(context, listen: false)
          .signIn(emailController.text, passwordController.text, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  AppStrings.welcomeMessage,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.loginPrompt,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.background1,
                  ),
                ),
                const SizedBox(height: 30),
                LayoutBuilder(builder: (context, constraints) {
                  double screenWidth = MediaQuery.of(context).size.width;
                  double horizontalPadding = screenWidth * 0.3;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: kIsWeb ? horizontalPadding : 30),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background2,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: "Email",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                              ),
                              onFieldSubmitted: (_) => _submitLogin(),
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: passwordController,
                              obscureText: !passwordVisible,
                              decoration: InputDecoration(
                                labelText: "Password",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    passwordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      passwordVisible = !passwordVisible;
                                    });
                                  },
                                ),
                              ),
                              onFieldSubmitted: (_) => _submitLogin(),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(color: AppColors.text1, fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgetPasswordPage()));
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: AppColors.text1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
