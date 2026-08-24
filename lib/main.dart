import 'package:flutter/material.dart';

void main() {
  // main() es el punto de inicio de la aplicación
  // runApp() inicia Flutter y le indicamos que MainApp será el widget principal
  runApp(const MainApp());
}

// Creamos una clase llamada MainApp que hereda de StatelessWidget
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Quita la cinta roja de DEBUG en la esquina superior derecha
      debugShowCheckedModeBanner: false,
      title: 'Clase uno',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variable para controlar la pestaña seleccionada en el BottomNavigationBar
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // =========================================================
      // 1. TOP BAR (AppBar)
      // =========================================================
      appBar: AppBar(
        // Color de fondo: Color.fromRGBO(0, 82, 147, 1) -> #005293
        backgroundColor: const Color.fromRGBO(0, 82, 147, 1),
        
        // Ícono de navegación (menú hamburguesa) a la izquierda
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Acción al presionar el menú hamburguesa
          },
        ),

        // Título que aparece en la barra superior
        title: const Text(
          'Clase uno',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        // actions permite agregar elementos al lado derecho de la barra
        actions: [
          // PopupMenuButton crea un menú desplegable (tres puntos verticales)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Seleccionado: $value')),
              );
            },
            itemBuilder: (BuildContext context) => [
              // Opción 1: Perfil
              const PopupMenuItem<String>(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.account_circle, color: Colors.black87),
                    SizedBox(width: 10),
                    Text('Perfil'),
                  ],
                ),
              ),

              // Opción 2: Configuración
              const PopupMenuItem<String>(
                value: 'configuracion',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.black87),
                    SizedBox(width: 10),
                    Text('Configuración'),
                  ],
                ),
              ),

              // Opción 3 (Ejercicio): Notificaciones
              const PopupMenuItem<String>(
                value: 'notificaciones',
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.black87),
                    SizedBox(width: 10),
                    Text('Notificaciones'),
                  ],
                ),
              ),

              // Opción 4 (Ejercicio): Ayuda
              const PopupMenuItem<String>(
                value: 'ayuda',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.black87),
                    SizedBox(width: 10),
                    Text('Ayuda'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // =========================================================
      // 2. CUERPO DE LA PANTALLA (Body)
      // =========================================================
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.flutter_dash,
              size: 80,
              color: Color.fromRGBO(0, 82, 147, 1),
            ),
            const SizedBox(height: 16),
            Text(
              'Hello World!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Índice seleccionado en BottomBar: $_selectedIndex',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),

      // =========================================================
      // 3. BARRA INFERIOR (BottomNavigationBar)
      // =========================================================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromRGBO(0, 82, 147, 1),
        unselectedItemColor: Colors.grey,
        items: const [
          // Ícono Mensajes
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Mensajes',
          ),
          // Ícono Buscar
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          // Ícono Inicio
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          // Ícono Perfil (Ejercicio)
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
