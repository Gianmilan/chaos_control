import 'package:flutter/material.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';

import 'home_page.dart';
import 'reminders_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _controller = SideMenuController();
  int _currentIndex = 0;

  final List<Widget> _pages = [const HomePage(), const RemindersPage()];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Row(
          children: [
            SideMenu(
              controller: _controller,
              backgroundColor: Colors.blueGrey,
              // Maybe I will enable later idk
              hasResizer: false,
              hasResizerToggle: true,
              resizerToggleData: const ResizerToggleData(
                iconSize: 20,
                iconColor: Colors.black,
                // TODO: Change topPosition based on screen height
                topPosition: 300,
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
                          Tooltip(message: "Tooltip message", child: tile),
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
                          Tooltip(message: "Tooltip message", child: tile),
                    ),
                  ],
                  footer: const Text('Footer'),
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
