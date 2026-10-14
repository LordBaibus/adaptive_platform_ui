import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_icons.dart';
import '../core/app_theme.dart';
import '../core/device_layout.dart';
import '../models/task.dart';
import '../services/task_controller.dart';
import '../widgets/task_editor.dart';
import '../widgets/task_list_view.dart';
import 'account_view.dart';
import 'home_view.dart';

/// Cupertino-style slide on iOS / macOS, a simple fade elsewhere.
Route<T> _adaptiveRoute<T>(Widget page) {
  return isCupertinoPlatform
      ? CupertinoPageRoute<T>(builder: (_) => page)
      : PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondary) => page,
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _homeTab = 0;
  static const int _tasksTab = 1;

  final TaskController _tasks = TaskController();
  int _tab = _homeTab;

  // Two-pane state (tablets, unfolded / half-open foldables).
  String? _selectedId;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _tasks.load();
  }

  @override
  void dispose() {
    _tasks.dispose();
    super.dispose();
  }

  bool get _singlePane => DeviceLayout.of(context).paneMode == PaneMode.single;

  void _newTask() {
    if (_singlePane) {
      _pushEditor(null);
    } else {
      setState(() {
        _tab = _tasksTab;
        _selectedId = null;
        _creating = true;
      });
    }
  }

  void _openTask(Task task) {
    if (_singlePane) {
      _pushEditor(task);
    } else {
      setState(() {
        _tab = _tasksTab;
        _selectedId = task.id;
        _creating = false;
      });
    }
  }

  void _closePane() => setState(() {
        _selectedId = null;
        _creating = false;
      });

  void _pushEditor(Task? task) {
    final navigator = Navigator.of(context);
    navigator.push(
      _adaptiveRoute<void>(
        Builder(
          builder: (context) => AdaptiveScaffold(
            backgroundColor: AppColors.background.resolveFrom(context),
            appBar: AdaptiveAppBar(title: task == null ? 'Create a Task' : 'Edit Task'),
            body: AppBackdrop(
              child: TaskEditor(
                controller: _tasks,
                task: task,
                onDone: () => navigator.pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tasksBody() {
    return ListenableBuilder(
      listenable: _tasks,
      builder: (context, _) {
        final list = TaskListView(
          controller: _tasks,
          selectedId: _selectedId,
          onOpen: _openTask,
        );

        if (DeviceLayout.of(context).paneMode == PaneMode.single) return list;

        Task? selected;
        for (final task in _tasks.tasks) {
          if (task.id == _selectedId) selected = task;
        }

        final Widget detail = (_creating || selected != null)
            ? TaskEditor(
                key: ValueKey(selected?.id ?? 'new'),
                controller: _tasks,
                task: selected,
                embedded: true,
                onDone: _closePane,
                onSaved: (saved) => setState(() {
                  _selectedId = saved.id;
                  _creating = false;
                }),
              )
            : const _EmptyDetail();

        return AdaptiveTwoPane(primary: list, secondary: detail);
      },
    );
  }

  Widget _body() {
    switch (_tab) {
      case _homeTab:
        return ListenableBuilder(
          listenable: _tasks,
          builder: (context, _) => HomeView(
            controller: _tasks,
            onCreate: _newTask,
            onOpen: _openTask,
          ),
        );
      case _tasksTab:
        return _tasksBody();
      default:
        return const AccountView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onTasks = _tab == _tasksTab;
    const titles = ['Home', 'My Task', 'Profile'];

    return AdaptiveScaffold(
      backgroundColor: AppColors.background.resolveFrom(context),
      appBar: AdaptiveAppBar(
        title: titles[_tab],
        tintColor: CupertinoColors.label.resolveFrom(context),
        actions: [
          // iOS / macOS: "+" lives in the toolbar. Others get a FAB below.
          if (onTasks && isCupertinoPlatform)
            AdaptiveAppBarAction(
              iosSymbol: AppIcons.addSymbol,
              icon: AppIcons.add,
              tintColor: CupertinoColors.label.resolveFrom(context),
              onPressed: _newTask,
            ),
          // Action menu (popup) in the app bar.
          AdaptiveAppBarAction(
            iosSymbol: AppIcons.moreSymbol,
            icon: AppIcons.more,
            tintColor: CupertinoColors.label.resolveFrom(context),
            menuItems: [
              AdaptivePopupMenuItem<String>(
                label: 'Refresh',
                icon: AppIcons.pick(AppIcons.refreshSymbol, AppIcons.refresh),
                value: 'refresh',
              ),
              AdaptivePopupMenuItem<String>(
                label: 'Sign out',
                icon: AppIcons.pick(AppIcons.signOutSymbol, AppIcons.signOut),
                value: 'signout',
                isDestructive: true,
              ),
            ],
            onMenuItemSelected: (index, item) {
              if (index == 0) {
                _tasks.load();
              } else {
                Supabase.instance.client.auth.signOut();
              }
            },
          ),
        ],
      ),
      floatingActionButton: onTasks && !isCupertinoPlatform
          ? AdaptiveFloatingActionButton(
              onPressed: _newTask,
              backgroundColor: AppColors.orange,
              foregroundColor: CupertinoColors.white,
              child: Icon(AppIcons.add),
            )
          : null,
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: _tab,
        onTap: (index) => setState(() => _tab = index),
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.secondaryText(context),
        items: [
          AdaptiveNavigationDestination(
            icon: AppIcons.pick(AppIcons.homeSymbol, AppIcons.home),
            label: 'Home',
          ),
          AdaptiveNavigationDestination(
            icon: AppIcons.pick(AppIcons.tasksSymbol, AppIcons.tasks),
            label: 'My Task',
          ),
          AdaptiveNavigationDestination(
            icon: AppIcons.pick(AppIcons.accountSymbol, AppIcons.account),
            label: 'Profile',
          ),
        ],
      ),
      body: AppBackdrop(child: _body()),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Select a task or tap + to create one',
        style: TextStyle(fontSize: 16, color: AppColors.secondaryText(context)),
      ),
    );
  }
}
