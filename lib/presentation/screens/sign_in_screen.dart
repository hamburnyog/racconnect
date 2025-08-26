import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'package:racconnect/logic/cubit/auth_cubit.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscureText = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    formKey.currentState?.dispose();
    super.dispose();
  }

  void signInUser() {
    if (formKey.currentState!.validate()) {
      context.read<AuthCubit>().signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Padding(
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
                              child: RichText(
                                text: TextSpan(
                                  text: 'RACCO',
                                  style: GoogleFonts.righteous(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'nnect',
                                      style: GoogleFonts.righteous(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30,
                                        color: Theme.of(context).disabledColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Email Address',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onFieldSubmitted: (_) => signInUser(),
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
                          StatefulBuilder(
                            builder: (context, setState) {
                              return TextFormField(
                                controller: passwordController,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  suffixIcon: IconButton(
                                    hoverColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    icon: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 10.0,
                                      ),
                                      child: Icon(
                                        _obscureText
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                ),
                                onFieldSubmitted: (_) => signInUser(),
                                obscureText: _obscureText,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      value.length < 8) {
                                    return 'Please enter a valid password.';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                          SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: signInUser,
                            child: Text(
                              'SIGN IN',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 15),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                            ),
                            icon: Image.asset(
                              'assets/images/google_logo.png',
                              height: 24,
                              width: 24,
                            ),
                            label: const Text('SIGN IN WITH GOOGLE'),
                            onPressed: () {
                              context.read<AuthCubit>().signInWithGoogle();
                            },
                          ),
                          SizedBox(height: 15),
                          GestureDetector(
                            onTap: () {
                              if (ModalRoute.of(context)?.settings.name !=
                                  '/signup') {
                                Navigator.of(context).pushNamed('/signup');
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Don\'t have an account? ',
                                    style: GoogleFonts.ubuntuMono(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign Up',
                                        style: GoogleFonts.ubuntuMono(
                                          fontSize: 12,
                                          color: Theme.of(context).primaryColor,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 15),
                          GestureDetector(
                            onTap: () {
                              if (ModalRoute.of(context)?.settings.name !=
                                  '/forgot-password') {
                                Navigator.of(
                                  context,
                                ).pushNamed('/forgot-password');
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Forgot Password? ',
                                    style: GoogleFonts.ubuntuMono(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Reset Password',
                                        style: GoogleFonts.ubuntuMono(
                                          fontSize: 12,
                                          color: Theme.of(context).primaryColor,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
