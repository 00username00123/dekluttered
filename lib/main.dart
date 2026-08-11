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
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      cardColor: Colors.black,
      dialogBackgroundColor: Colors.black,
      bottomAppBarColor: Colors.black,
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
                darkTheme = ThemeData.dark();
                break;
              case ThemeState.oled:
                themeMode = ThemeMode.dark;
                darkTheme = _oledTheme();
                break;
              case ThemeState.light:
                themeMode = ThemeMode.light;
                darkTheme = ThemeData.dark();
                break;
              case ThemeState.system:
                themeMode = ThemeMode.system;
                darkTheme = ThemeData.dark();
                break;
            }
            return MaterialApp(
              navigatorKey: DownloadFloatingControl.navigatorKey,
              title: 'Dekluttered',
              theme: ThemeData.light(),
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
