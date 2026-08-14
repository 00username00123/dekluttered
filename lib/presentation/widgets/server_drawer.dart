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
    LibraryDto? currentLibrary =
        ModalRoute.of(context)?.settings.arguments as LibraryDto?;
    return Drawer(
      child: Container(
        width: 50,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            KlutterDrawerHeader(),
            Divider(),
            ListTile(
              selected:
                  ModalRoute.of(context)?.settings.name == ServerHome.routeName,
              leading: Icon(Icons.home),
              title: Text("Home"),
              onTap: () => _goHome(context),
            ),
            ListTile(
              selected: ModalRoute.of(context)?.settings.name ==
                  DownloadsScreen.routeName,
              leading: Icon(Icons.offline_pin),
              title: Text("Downloads"),
              onTap: () => _openSecondary(context, DownloadsScreen.routeName),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                'LIBRARIES',
                style: Theme.of(context).textTheme.caption,
              ),
            ),
            ListTile(
              selected: currentLibrary == null &&
                  ModalRoute.of(context)?.settings.name ==
                      LibraryScreen.routeName,
              leading: Icon(Icons.library_books),
              title: Text("All Libraries"),
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
                      children: state.libraries
                          .map((e) => ListTile(
                                contentPadding:
                                    const EdgeInsets.only(left: 28, right: 16),
                                leading: Icon(Icons.folder_open),
                                selected: currentLibrary?.id == e.id,
                                title: Text(
                                  e.name,
                                  style: TextStyle(fontSize: 12),
                                ),
                                onTap: () => _openSecondary(
                                  context,
                                  LibraryScreen.routeName,
                                  arguments: e,
                                ),
                              ))
                          .toList());
                }
                return Container();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Change server"),
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  ServerPicker.routeName, (Route<dynamic> route) => false),
            ),
            Divider(),
            KlutterAboutListTile(),
            SelectThemeTile(),
          ],
        ),
      ),
    );
  }
}
