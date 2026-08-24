// Importa la biblioteca Material de Flutter.
import 'package:flutter/material.dart';
// main() es el punto de inicio de la aplicación.
void main() {
  // runApp() inicia Flutter.
  // Le indicamos que MainApp será el widget principal de nuestra aplicación.
  runApp(const MainApp());
}
// Creamos una clase llamada MainApp.
class MainApp extends StatelessWidget {

  // Constructor de MainApp.
  // super.key permite que Flutter identifique este widget dentro
  // del árbol de widgets.
  const MainApp({super.key});
  // @override indica que estamos utilizando y redefiniendo
  // un método que viene de StatelessWidget.
  @override
  // build() construye la interfaz visual de este widget.
  Widget build(BuildContext context) {
    // MaterialApp es el widget general de la aplicación.
    // Material Design.
    return const MaterialApp(
      // home indica cuál será la pantalla inicial de la aplicación.
      //
      // Scaffold proporciona la estructura básica de una pantalla
      // (body, AppBar, botones flotantes, menú inferior, etc.).
      //
      // body es el contenido principal de la pantalla.
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ), // Center
      ), // Scaffold

    ); // MaterialApp

  }

}
