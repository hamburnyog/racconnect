import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    formKey.currentState?.dispose();
    super.dispose();
  }

  void signUpUser() {
    if (formKey.currentState!.validate()) {
      context.read<AuthCubit>().signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        passwordConfirm: passwordConfirmController.text.trim(),
        firstName: firstNameController.text.trim(),
        middleName: middleNameController.text.trim(),
        lastName: lastNameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo_nacc.png',
                            fit: BoxFit.contain,
                            height: 40,
                          ),
                          SizedBox(width: 5),
                          RichText(
                            text: TextSpan(
                              text: 'RACCO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                                color: Theme.of(context).primaryColor,
                              ),
                              children: [
                                TextSpan(
                                  text: 'nnect',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Regional Alternative Child Care Office Calabarzon',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 30),
                      TextFormField(
                        controller: firstNameController,
                        decoration: InputDecoration(hintText: 'First Name'),
                        onFieldSubmitted: (_) => signUpUser(),
                        validator: (value) {
                          // TODO: IMPROVE VALIDATION
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a valid first name.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: middleNameController,
                        decoration: InputDecoration(hintText: 'Middle Name'),
                        onFieldSubmitted: (_) => signUpUser(),
                        validator: (value) {
                          // TODO: IMPROVE VALIDATION
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: lastNameController,
                        decoration: InputDecoration(hintText: 'Last Name'),
                        onFieldSubmitted: (_) => signUpUser(),
                        validator: (value) {
                          // TODO: IMPROVE VALIDATION
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a valid last name.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(hintText: 'Email Address'),
                        onFieldSubmitted: (_) => signUpUser(),
                        validator: (value) {
                          // TODO: IMPROVE VALIDATION
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
                          // TODO: IMPROVE VALIDATION
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
                          // TODO: IMPROVE VALIDATION
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
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 15),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/');
                        },
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: Theme.of(context).textTheme.titleMedium,
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
          );
        },
      ),
    );
  }
}
