import 'package:chaos_control/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';

import 'home_page.dart';
import 'network_service.dart';
import 'reminders_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<Widget> _pages = [const HomePage(), const RemindersPage()];
  final _controller = SideMenuController();
  final _networkService = NetworkService();

  int _currentIndex = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _networkService.startServer();
  }

  @override
  void dispose() {
    _networkService.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);

    int foundCount = 0;

    await _networkService.discoverDevices((service) async {
      foundCount++;
      await _networkService.syncWithDevice(service);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Synced with ${service.name}")));
      }
    });

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _isSyncing = false);
      if (foundCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No devices found on the network")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final resizerPosition = (screenHeight / 2) - 25;

    return MaterialApp(
      title: 'Chaos Control',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Row(
          children: [
            SideMenu(
              controller: _controller,
              backgroundColor: Colors.blueGrey,
              hasResizer: false,
              hasResizerToggle: true,
              resizerToggleData: ResizerToggleData(
                iconSize: 20,
                iconColor: Colors.black,
                topPosition: resizerPosition,
              ),
              mode: SideMenuMode.compact,
              builder: (data) {
                return SideMenuData(
                  defaultTileData: const SideMenuItemTileDefaults(
                    hoverColor: Colors.black,
                  ),
                  animItems: const SideMenuItemsAnimationData(),
                  items: [
                    const SideMenuItemDataTitle(
                      title: 'Navigation Menu',
                      textAlign: TextAlign.center,
                    ),
                    SideMenuItemDataTile(
                      isSelected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                      title: 'Home',
                      hoverColor: Colors.blue,
                      titleStyle: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      tooltipBuilder: (tile) =>
                          Tooltip(message: "Go to home", child: tile),
                    ),
                    SideMenuItemDataTile(
                      isSelected: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                      title: 'Reminders',
                      hoverColor: Colors.blue,
                      titleStyle: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.calendar_today_outlined),
                      selectedIcon: const Icon(Icons.calendar_today),
                      tooltipBuilder: (tile) =>
                          Tooltip(message: "Go to reminders", child: tile),
                    ),
                  ],
                  footer: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: _isSyncing
                        ? const Center(
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: _handleSync,
                            icon: const Icon(Icons.sync, color: Colors.white),
                            tooltip: "Sync with local devices",
                          ),
                  ),
                );
              },
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: _pages[_currentIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
