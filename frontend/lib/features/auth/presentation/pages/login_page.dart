import 'package:flutter/material.dart';

class loginWidget extends StatefulWidget {
  const loginWidget({super.key});
  @override
  State<StatefulWidget> createState() {
    return loginMain();
  }
}

class loginMain extends State<loginWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: logo());
  }
}

class logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return (Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage('assets/logo.png')),
          ),
        ),
        Positioned(top: 0, left: 12, child: Text("aaa")),
      ],
    ));
  }
}
