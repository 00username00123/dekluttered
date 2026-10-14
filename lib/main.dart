import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:klutter/business_logic/cubit/theme_cubit.dart';
import 'package:klutter/data/dataproviders/client/api_client.dart';
import 'package:klutter/presentation/screens/book_screen.dart';
import 'package:klutter/presentation/screens/collection_screen.dart';
import 'package:klutter/presentation/screens/downloads_screen.dart';
import 'package:klutter/presentation/screens/library_screen.dart';
import 'package:klutter/presentation/screens/reader.dart';
import 'package:klutter/presentation/screens/series_screen.dart';
import 'package:klutter/presentation/screens/server_picker.dart';
import 'package:klutter/presentation/widgets/download_floating_control.dart';
import 'package:path_provider/path_provider.dart';
import 'presentation/screens/server_home.dart';
import 'package:sizer/sizer.dart';

class DklTheme {
  static const Color amber = Color(0xFFE5A614);
  static const Color black = Colors.black;
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color surface1 = Color(0xFF111111);
  static const Color surface2 = Color(0xFF1A1A1A);
  static const Color dialogBg = Color(0xFF161616);
  static const Color track = Color(0xFF333333);
  static const Color divider = Color(0xFF222222);
  static const Color textMuted = Color(0xFF888888);
  static const Color textSecondary = Color(0xFFB0B0B0);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: await getApplicationSupportDirectory());
  ApiClient();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  ThemeData _oledTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: DklTheme.amber,
      scaffoldBackgroundColor: DklTheme.black,
      canvasColor: DklTheme.black,
      cardColor: DklTheme.surface1,
      dialogBackgroundColor: DklTheme.dialogBg,
      dividerColor: DklTheme.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: DklTheme.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DklTheme.black,
        selectedItemColor: DklTheme.amber,
        unselectedItemColor: Color(0xFF666666),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DklTheme.amber,
        foregroundColor: Colors.black,
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData.light().copyWith(
      primaryColor: DklTheme.amber,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: DklTheme.amber,
        unselectedItemColor: Colors.grey,
        elevation: 4,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DklTheme.amber,
        foregroundColor: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeCubit(),
      child: Sizer(builder: (context, orientation, devicetype) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            late ThemeMode themeMode;
            late ThemeData darkTheme;
            switch (state) {
              case ThemeState.dark:
                themeMode = ThemeMode.dark;
                darkTheme = _oledTheme();
                break;
              case ThemeState.oled:
                themeMode = ThemeMode.dark;
                darkTheme = _oledTheme();
                break;
              case ThemeState.light:
                themeMode = ThemeMode.light;
                darkTheme = _oledTheme();
                break;
              case ThemeState.system:
                themeMode = ThemeMode.dark;
                darkTheme = _oledTheme();
                break;
            }
            return MaterialApp(
              navigatorKey: DownloadFloatingControl.navigatorKey,
              title: 'Dekluttered',
              theme: _lightTheme(),
              themeMode: themeMode,
              darkTheme: darkTheme,
              builder: (context, child) => DownloadFloatingControl(
                child: child ?? SizedBox.shrink(),
              ),
              home: ServerPicker(),
              routes: {
                ServerHome.routeName: (context) => ServerHome(),
                ServerPicker.routeName: (context) => ServerPicker(),
                DownloadsScreen.routeName: (context) => DownloadsScreen(),
                BookScreen.routeName: (context) => BookScreen(),
                SeriesScreen.routeName: (context) => SeriesScreen(),
                Reader.routeName: (context) => Reader(),
                LibraryScreen.routeName: (context) => LibraryScreen(),
                CollectionScreen.routeName: (context) => CollectionScreen(),
              },
            );
          },
        );
      }),
    );
  }
}
