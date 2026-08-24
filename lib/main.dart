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
      // Quita la cinta roja de DEBUG en la esquina superior derecha
      debugShowCheckedModeBanner: false,
      title: 'Clase uno',
      // home indica cuál será la pantalla inicial de la aplicación.
      home: HomeScreen(),
    ); // MaterialApp
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Control del índice seleccionado en la barra inferior
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold proporciona la estructura básica de una pantalla
    // (body, AppBar, botones flotantes, menú inferior, etc.).
    return Scaffold(
      // ==========================================================
      // Barra superior de la aplicación (Top Bar / AppBar)
      // ==========================================================
      appBar: AppBar(
        // Color de fondo #005293
        // Equivalente RGB: R: 0, G: 82, B: 147.
        backgroundColor: const Color.fromRGBO(0, 82, 147, 1),

        // Ícono de navegación (menú hamburguesa) ubicado a la izquierda.
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: Colors.white,
          onPressed: () {},
        ), // IconButton

        // Texto que aparece en la barra superior.
        // El color del texto es blanco.
        title: const Text(
          'Clase uno',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ), // Text

        // actions permite agregar elementos al lado derecho de la barra.
        actions: [
          // PopupMenuButton crea un menú desplegable.
          // El ícono more_vert muestra los tres puntos verticales.
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ), // Icon
            // itemBuilder construye las opciones que tendrá el menú.
            itemBuilder: (BuildContext context) => [
              // Primera opción del menú: Perfil con ícono account_circle a la izquierda
              const PopupMenuItem<String>(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.account_circle),
                    SizedBox(width: 10),
                    Text('Perfil'),
                  ],
                ), // Row
              ), // PopupMenuItem

              // Segunda opción del menú: Configuración con ícono settings a la izquierda
              const PopupMenuItem<String>(
                value: 'configuracion',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 10),
                    Text('Configuración'),
                  ],
                ), // Row
              ), // PopupMenuItem

              // Ejercicio: Nuevo item - Notificaciones
              const PopupMenuItem<String>(
                value: 'notificaciones',
                child: Row(
                  children: [
                    Icon(Icons.notifications),
                    SizedBox(width: 10),
                    Text('Notificaciones'),
                  ],
                ), // Row
              ), // PopupMenuItem

              // Ejercicio: Nuevo item - Ayuda
              const PopupMenuItem<String>(
                value: 'ayuda',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 10),
                    Text('Ayuda'),
                  ],
                ), // Row
              ), // PopupMenuItem
            ],
          ), // PopupMenuButton
        ],
      ), // AppBar

      // ==========================================================
      // Contenido principal de la pantalla (body)
      // ==========================================================
      body: const Center(
        child: Text(
          'Hello World!',
          style: TextStyle(fontSize: 18),
        ),
      ), // Center

      // ==========================================================
      // bottomNavigationBar crea una barra de navegación en la parte inferior
      // ==========================================================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Mantiene fijos todos los ítems
        selectedItemColor: const Color.fromRGBO(0, 82, 147, 1),
        unselectedItemColor: Colors.grey,
        // items contiene los elementos de la barra.
        items: const [
          // Ícono de mensajes ubicado a la izquierda.
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Mensajes',
          ), // BottomNavigationBarItem

          // Ícono de búsqueda ubicado al centro.
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ), // BottomNavigationBarItem

          // Ícono Home ubicado a la derecha.
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ), // BottomNavigationBarItem

          // Ejercicio: Nuevo ícono - Favoritos
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ), // BottomNavigationBarItem

          // Ejercicio: Nuevo ícono - Perfil
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ), // BottomNavigationBarItem
        ],
      ), // BottomNavigationBar
    ); // Scaffold
  }
}
