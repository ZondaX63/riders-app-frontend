import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/route.dart';
import '../models/group_chat.dart';
import '../widgets/route_card.dart';
import '../widgets/async_state_builder.dart';
import '../screens/create_route_screen.dart';
import '../screens/route_details_screen.dart';
import '../screens/group_chat_screen.dart';

class GroupRidesScreen extends StatefulWidget {
  const GroupRidesScreen({super.key});

  @override
  State<GroupRidesScreen> createState() => _GroupRidesScreenState();
}

class _GroupRidesScreenState extends State<GroupRidesScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Grup Sürüşleri'),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryOrange,
            labelColor: AppTheme.primaryOrange,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(text: 'Rotalar'),
              Tab(text: 'Gruplarım'),
            ],
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          ],
        ),
        body: const TabBarView(
          children: [
            _RoutesTab(),
            _GroupsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateRouteScreen(),
              ),
            );
            if (result == true) {
              // Usually we'd want to refresh the routes tab.
              // Using a simple event bus or provider would be better,
              // but for now, we'll just let the user pull to refresh.
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Rota Paylaş'),
          backgroundColor: AppTheme.primaryOrange,
        ),
      ),
    );
  }
}

class _RoutesTab extends StatefulWidget {
  const _RoutesTab();

  @override
  State<_RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends State<_RoutesTab> {
  List<RidersRoute> _routes = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final routes = await context.read<ApiService>().getPublicRoutes();
      if (mounted) {
        setState(() {
          _routes = routes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStateBuilder(
      isLoading: _isLoading,
      error: _error,
      isEmpty: _routes.isEmpty && !_isLoading,
      emptyMessage: 'Henüz planlanmış sürüş yok',
      onRetry: _loadRoutes,
      child: RefreshIndicator(
        onRefresh: _loadRoutes,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _routes.length,
          itemBuilder: (context, index) => RouteCard(
            route: _routes[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RouteDetailsScreen(route: _routes[index]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GroupsTab extends StatefulWidget {
  const _GroupsTab();

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
  List<GroupChat> _groups = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await context.read<ApiService>().getGroupChats();
      if (mounted) {
        setState(() {
          _groups = (data as List).map((e) => GroupChat.fromJson(e)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStateBuilder(
      isLoading: _isLoading,
      error: _error,
      isEmpty: _groups.isEmpty && !_isLoading,
      emptyMessage: 'Henüz bir gruba dahil değilsiniz',
      onRetry: _loadGroups,
      child: RefreshIndicator(
        onRefresh: _loadGroups,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _groups.length,
          itemBuilder: (context, index) {
            final group = _groups[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryOrange,
                  child: Icon(Icons.group, color: Colors.white),
                ),
                title: Text(group.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(group.description ?? 'Sürüş grubu'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatScreen(
                        groupId: group.id,
                        groupName: group.name,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
