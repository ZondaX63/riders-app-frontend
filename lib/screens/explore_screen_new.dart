import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'riders_map_screen.dart';
import 'riders_explore_tab.dart';
import 'map_pins_tab.dart';
import 'group_rides_tab.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryOrange,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.search),
              text: 'Ara',
            ),
            Tab(
              icon: Icon(Icons.map),
              text: 'Harita',
            ),
            Tab(
              icon: Icon(Icons.place),
              text: 'Noktalar',
            ),
            Tab(
              icon: Icon(Icons.two_wheeler),
              text: 'Grup Sürüşleri',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RidersExploreTab(),
          RidersMapScreen(),
          MapPinsTab(),
          GroupRidesTab(),
        ],
      ),
    );
  }
}
