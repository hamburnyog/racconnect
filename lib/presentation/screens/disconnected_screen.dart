import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class DisconnectedScreen extends StatefulWidget {
  const DisconnectedScreen({super.key});

  @override
  State<DisconnectedScreen> createState() => _DisconnectedScreenState();
}

class _DisconnectedScreenState extends State<DisconnectedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
              Lottie.asset(
                'assets/animations/dino.json',
                fit: BoxFit.cover,
                height:
                    (!Platform.isAndroid && !Platform.isIOS)
                        ? MediaQuery.of(context).size.height * .3
                        : MediaQuery.of(context).size.height * .2,
                frameRate: FrameRate.max,
              ),
              SizedBox(height: 20),
              Text('We\'re having trouble connecting to the server.'),
              Text('Attempting to reconnect ...'),
            ],
          ),
        ),
      ),
    );
  }
}
