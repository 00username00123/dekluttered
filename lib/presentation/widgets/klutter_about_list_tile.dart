import 'package:flutter/material.dart';

class KlutterAboutListTile extends StatelessWidget {
  const KlutterAboutListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AboutListTile(
      applicationLegalese: "Many thanks to gotson for creating Komga",
      applicationName: "Dekluttered",
      icon: Icon(Icons.help),
      applicationVersion: "0.7.0",
    );
  }
}
