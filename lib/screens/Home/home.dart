import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; //rever isso

import 'home_mobile.dart';
import 'home_desktop.dart';

import '../../Routes/routes.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return const HomeDesktop();
        } else {
          return const HomeMobile();
        }
      },
    );
  }
}
