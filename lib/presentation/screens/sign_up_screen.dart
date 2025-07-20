import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    nameController.dispose();
    formKey.currentState?.dispose();
    super.dispose();
  }

  void signUpUser() {
    if (formKey.currentState!.validate()) {
      context.read<AuthCubit>().signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        passwordConfirm: passwordConfirmController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;

    return Scaffold(
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: SingleChildScrollView(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: isSmallScreen ? 1 : 0.85,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/animations/welcome.json',
                            fit: BoxFit.cover,
                            height:
                                (!Platform.isAndroid && !Platform.isIOS)
                                    ? MediaQuery.of(context).size.height * .3
                                    : null,
                            frameRate: FrameRate.max,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/logo_bp.png',
                                    width: 50,
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          text: 'RACCO',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 30,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'nnect',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 30,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).disabledColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        isSmallScreen
                                            ? 'RACCO IV-A Calabarzon'
                                            : 'Regional Alternative Child Care Office IV-A Calabarzon',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Image.asset(
                                    'assets/images/logo_nacc.png',
                                    width: 50,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          TextFormField(
                            controller: nameController,
                            keyboardType: TextInputType.name,
                            decoration: InputDecoration(
                              hintText: 'Display Name',
                            ),
                            onFieldSubmitted: (_) => signUpUser(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a valid display name.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Email Address',
                            ),
                            onFieldSubmitted: (_) => signUpUser(),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(hintText: 'Password'),
                            obscureText: true,
                            onFieldSubmitted: (_) => signUpUser(),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  value.length < 8) {
                                return 'Please enter a valid pasword.';
                              }
                              if (value != passwordConfirmController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: passwordConfirmController,
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                            ),
                            onFieldSubmitted: (_) => signUpUser(),
                            obscureText: true,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  value.length < 8) {
                                return 'Please enter a valid pasword.';
                              }
                              if (value != passwordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: signUpUser,
                            child: Text(
                              'SIGN UP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'By registering, you agree to the ',
                                style: GoogleFonts.ubuntuMono(fontSize: 12),
                              ),
                              GestureDetector(
                                onTap: () {
                                  launchUrl(
                                    Uri.parse(
                                      'https://privacy.codecarpentry.com/',
                                    ),
                                  );
                                },
                                child: Text(
                                  'privacy policy',
                                  style: GoogleFonts.ubuntuMono(
                                    fontSize: 12,
                                    color: Theme.of(context).primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Text('.', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          SizedBox(height: 15),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: GoogleFonts.ubuntuMono(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: GoogleFonts.ubuntuMono(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
