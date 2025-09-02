import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/presentation/widgets/logo_widget.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    formKey.currentState?.dispose();
    super.dispose();
  }

  void signUpUser() {
    if (formKey.currentState!.validate()) {
      context.read<AuthCubit>().requestPasswordReset(
        emailController.text.trim(),
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
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: LogoWithVersion(),
                          ),
                          SizedBox(height: 30),
                          TextFormField(
                            controller: emailController,
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
                          ElevatedButton(
                            onPressed: signUpUser,
                            child: Text(
                              'SEND PASSWORD RESET LINK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Click here to ',
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
