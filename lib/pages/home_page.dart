import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'feedback_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> cart = [];
  bool isLoading = false;

  String locationText = 'Mendeteksi lokasi...';
  String selectedCurrency = 'USD';
  String selectedTimeZone = 'WIB';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _getLocation();
    _initNotification();
  }

  Future<void> _initNotification() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id',
          'Steam Game Notification',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Steam Game Info',
      message,
      platformDetails,
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => locationText = 'Layanan lokasi nonaktif');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => locationText = 'Izin lokasi ditolak');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => locationText = 'Izin lokasi ditolak permanen');
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      locationText =
          'Lokasi saat ini: (${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)})';
    });
  }

  Future<void> _searchGame() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        'https://store.steampowered.com/api/storesearch/?term=$query&cc=us',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final games = data['items'] as List<dynamic>;

        searchResults = games.map((g) {
          return {
            'name': g['name'],
            'price': (g['price']?['final'] ?? 0) / 100,
            'image': g['tiny_image'] ?? '',
          };
        }).toList();
      } else {
        searchResults = [];
      }
    } catch (e) {
      print('Error fetching data: $e');
      searchResults = [];
    }

    setState(() => isLoading = false);
  }

  void _addToCart(Map<String, dynamic> game) {
    setState(() => cart.add(game));
  }

  double _calculateTotalUSD() {
    return cart.fold(0.0, (sum, g) => sum + (g['price'] ?? 0.0));
  }

  double _convertCurrency(double usd) {
    switch (selectedCurrency) {
      case 'IDR':
        return usd * 15000;
      case 'CNY':
        return usd * 7.25;
      default:
        return usd;
    }
  }

  String _getFormattedDateTime() {
    DateTime now = DateTime.now();
    DateTime adjusted;

    switch (selectedTimeZone) {
      case 'WITA':
        adjusted = now.add(const Duration(hours: 1));
        break;
      case 'WIT':
        adjusted = now.add(const Duration(hours: 2));
        break;
      case 'London':
        adjusted = now.subtract(const Duration(hours: 7));
        break;
      default:
        adjusted = now;
    }

    return DateFormat('dd MMM yyyy, HH:mm').format(adjusted);
  }

  void _calculateAndNotify() {
    final totalUSD = _calculateTotalUSD();
    final converted = _convertCurrency(totalUSD);
    final formattedDate = _getFormattedDateTime();

    final message =
        "Total harga: ${converted.toStringAsFixed(2)} $selectedCurrency\nDihitung pada: $formattedDate";
    _showNotification("Total harga game kamu berhasil dihitung!");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Total Harga'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(username: 'User')),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FeedbackPage()),
      );
    } else if (index == 3) {
      _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalUSD = _calculateTotalUSD();
    final converted = _convertCurrency(totalUSD);
    final formattedDate = _getFormattedDateTime();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Steam Game Price Calculator'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Kesan & Saran',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locationText,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari game di Steam...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _searchGame,
                  child: const Text('Cari'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ...searchResults.map(
                (g) => ListTile(
                  leading: g['image'] != ''
                      ? Image.network(g['image'], width: 50, height: 50)
                      : const Icon(Icons.videogame_asset),
                  title: Text(g['name']),
                  subtitle: Text('\$${g['price'].toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () => _addToCart(g),
                  ),
                ),
              ),
            const Divider(thickness: 2),
            const Text(
              'Keranjang:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ...cart.map(
              (g) => ListTile(
                title: Text(g['name']),
                trailing: Text('\$${g['price'].toStringAsFixed(2)}'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: selectedCurrency,
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'IDR', child: Text('IDR')),
                    DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                  ],
                  onChanged: (val) => setState(() => selectedCurrency = val!),
                ),
                DropdownButton<String>(
                  value: selectedTimeZone,
                  items: const [
                    DropdownMenuItem(value: 'WIB', child: Text('WIB')),
                    DropdownMenuItem(value: 'WITA', child: Text('WITA')),
                    DropdownMenuItem(value: 'WIT', child: Text('WIT')),
                    DropdownMenuItem(value: 'London', child: Text('London')),
                  ],
                  onChanged: (val) => setState(() => selectedTimeZone = val!),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    'Total (${selectedCurrency}): ${converted.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Dihitung pada: $formattedDate',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _calculateAndNotify,
                    child: const Text("Kirim Notifikasi"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
