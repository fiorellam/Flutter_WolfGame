import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SendSMS extends StatelessWidget {
  final String phoneNumber = "1234567890"; // Número de teléfono
  final String message = "Hola, este es un mensaje de prueba desde Flutter."; // Mensaje de texto

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enviar SMS'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            String url = "sms:$phoneNumber?body=${Uri.encodeComponent(message)}";
            if (await canLaunch(url)) {
              await launch(url);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("No se pudo abrir la aplicación de SMS")),
              );
            }
          },
          child: Text('Enviar SMS'),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SendSMS(),
  ));
}
