import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/cubit/libraries_info_cubit.dart';
import 'package:klutter/data/models/librarydto.dart';
import 'package:klutter/presentation/screens/downloads_screen.dart';
import 'package:klutter/presentation/screens/library_screen.dart';
import 'package:klutter/presentation/screens/server_home.dart';
import 'package:klutter/presentation/screens/server_picker.dart';
import 'package:klutter/presentation/widgets/klutter_drawer_header.dart';
import 'package:klutter/presentation/widgets/select_theme_tile.dart';
import 'klutter_about_list_tile.dart';

class ServerDrawer extends StatefulWidget {
  const ServerDrawer({
    Key? key,
  }) : super(key: key);

  @override
  _ServerDrawerState createState() => _ServerDrawerState();
}

class _ServerDrawerState extends State<ServerDrawer> {
  void _openSecondary(BuildContext context, String routeName,
      {Object? arguments}) {
    final current = ModalRoute.of(context)?.settings.name;
    Navigator.of(context).pop(); // close drawer first
    if (current == routeName) return;

    // Keep ServerHome alive underneath secondary screens so returning home is
    // instant and does not refetch every feed/thumbnail.
    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  void _goHome(BuildContext context) {
    final current = ModalRoute.of(context)?.settings.name;
    Navigator.of(context).pop(); // close drawer
    if (current == ServerHome.routeName) return;

    // If Home is already in the stack, pop back to the existing instance.
    bool foundHome = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == ServerHome.routeName) {
        foundHome = true;
        return true;
      }
      return route.isFirst;
    });

    // Fallback for unusual entry paths where Home is not in the stack.
    if (!foundHome) {
      Navigator.of(context).pushReplacementNamed(ServerHome.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LibraryDto? currentLibrary =
        ModalRoute.of(context)?.settings.arguments as LibraryDto?;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    const Color amber = Color(0xFFE5A614);

    return Drawer(
      child: Container(
        color: const Color(0xFF0D0D0D),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const KlutterDrawerHeader(),
            const Divider(color: Color(0xFF222222), height: 1),
            ListTile(
              dense: true,
              selected: currentRoute == ServerHome.routeName,
              selectedColor: amber,
              selectedTileColor: amber.withOpacity(0.12),
              leading: Icon(
                Icons.home,
                color: currentRoute == ServerHome.routeName
                    ? amber
                    : Colors.white70,
              ),
              title: Text(
                "Home",
                style: TextStyle(
                  color: currentRoute == ServerHome.routeName
                      ? amber
                      : Colors.white,
                  fontWeight: currentRoute == ServerHome.routeName
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              onTap: () => _goHome(context),
            ),
            ListTile(
              dense: true,
              selected: currentRoute == DownloadsScreen.routeName,
              selectedColor: amber,
              selectedTileColor: amber.withOpacity(0.12),
              leading: Icon(
                Icons.offline_pin,
                color: currentRoute == DownloadsScreen.routeName
                    ? amber
                    : Colors.white70,
              ),
              title: Text(
                "Downloads",
                style: TextStyle(
                  color: currentRoute == DownloadsScreen.routeName
                      ? amber
                      : Colors.white,
                  fontWeight: currentRoute == DownloadsScreen.routeName
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              onTap: () => _openSecondary(context, DownloadsScreen.routeName),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: amber,
                    width: 4,
                  ),
                ),
              ),
              child: const Text(
                'LIBRARIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: amber,
                ),
              ),
            ),
            ListTile(
              dense: true,
              selected: currentLibrary == null &&
                  currentRoute == LibraryScreen.routeName,
              selectedColor: amber,
              selectedTileColor: amber.withOpacity(0.12),
              leading: Icon(
                Icons.library_books,
                color: currentLibrary == null &&
                        currentRoute == LibraryScreen.routeName
                    ? amber
                    : Colors.white70,
              ),
              title: Text(
                "All Libraries",
                style: TextStyle(
                  color: currentLibrary == null &&
                          currentRoute == LibraryScreen.routeName
                      ? amber
                      : Colors.white,
                  fontWeight: currentLibrary == null &&
                          currentRoute == LibraryScreen.routeName
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              onTap: () => _openSecondary(
                context,
                LibraryScreen.routeName,
                arguments: null,
              ),
            ),
            BlocBuilder<LibrariesInfoCubit, LibrariesInfoState>(
              bloc: LibrariesInfoCubit()..getAllLibraries(),
              builder: (context, state) {
                if (state is LibrariesInfoReady) {
                  return Column(
                    children: state.libraries.map((e) {
                      final bool isSelected = currentLibrary?.id == e.id;
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.only(left: 28, right: 16),
                        leading: Icon(
                          Icons.folder_open,
                          size: 20,
                          color: isSelected ? amber : Colors.white60,
                        ),
                        selected: isSelected,
                        selectedColor: amber,
                        selectedTileColor: amber.withOpacity(0.12),
                        title: Text(
                          e.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? amber : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () => _openSecondary(
                          context,
                          LibraryScreen.routeName,
                          arguments: e,
                        ),
                      );
                    }).toList(),
                  );
                }
                return Container();
              },
            ),
            const Divider(color: Color(0xFF222222), height: 16),
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text(
                "Change server",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                ServerPicker.routeName,
                (Route<dynamic> route) => false,
              ),
            ),
            const Divider(color: Color(0xFF222222), height: 16),
            const KlutterAboutListTile(),
            const SelectThemeTile(),
          ],
        ),
      ),
    );
  }
}
