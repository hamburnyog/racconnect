import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DisconnectedScreen extends StatefulWidget {
  const DisconnectedScreen({super.key});

  @override
  State<DisconnectedScreen> createState() => _DisconnectedScreenState();
}

class _DisconnectedScreenState extends State<DisconnectedScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo_bp.png', width: 50),
                      const SizedBox(width: 10),
                      Column(
                        children: [
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
                      const SizedBox(width: 10),
                      Image.asset('assets/images/logo_nacc.png', width: 50),
                    ],
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
