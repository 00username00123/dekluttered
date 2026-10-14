import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/cubit/server_cubit.dart';
import 'package:klutter/business_logic/cubit/servercheck_cubit.dart';
import 'package:klutter/data/models/server.dart';
import 'package:validators/validators.dart';
import 'package:klutter/presentation/widgets/server_picker_drawer.dart';
import 'server_home.dart';

class ServerPicker extends StatefulWidget {
  static const routeName = '/serverPicker';

  const ServerPicker({Key? key}) : super(key: key);

  @override
  _ServerPickerState createState() => _ServerPickerState();
}

class _ServerPickerState extends State<ServerPicker> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ServerCubit()..getServers(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              title: const Text(
                'Dekluttered',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            drawer: const ServerPickerDrawer(),
            body: BlocConsumer<ServerCubit, ServerState>(
              listener: (context, state) {
                if (state is ServerReady) {
                  Navigator.of(context).pushNamed(ServerHome.routeName);
                }
                if (state is ServerAddNewFailed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is ServerInitial) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFE5A614)),
                    ),
                  );
                } else if (state is ServersEmpty) {
                  return Column(
                    children: [
                      _buildHeader(),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Add a server using the + button",
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (state is ServersFetched) {
                  return ListView(
                    children: [
                      _buildHeader(),
                      ...state.servers.map((server) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 6.0),
                          child: ServerCard(server),
                        );
                      }).toList(),
                      const SizedBox(height: 80),
                    ],
                  );
                } else {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Color(0xFFE5A614),
                      size: 32,
                    ),
                  );
                }
              },
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: const Color(0xFFE5A614),
              foregroundColor: Colors.black,
              onPressed: () {
                ServerCubit serverCubit = context.read<ServerCubit>();
                AddServerDialog addServerDialog = const AddServerDialog();
                showDialog(
                  context: context,
                  builder: (context) {
                    return BlocProvider<ServerCubit>.value(
                      value: serverCubit,
                      child: addServerDialog,
                    );
                  },
                );
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Center(
        child: Column(
          children: [
            Image.asset(
              'assets/images/icon.png',
              height: 56,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            const Text(
              'Dekluttered',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select a Komga server',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddServerDialog extends StatefulWidget {
  const AddServerDialog({Key? key}) : super(key: key);

  @override
  _AddServerDialogState createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final _formKey = GlobalKey<FormState>();
  late String serverName;
  late String url;
  late String username;
  late String password;
  bool useEmailLogin = true;

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFE5A614);

    return SimpleDialog(
      backgroundColor: const Color(0xFF161616),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        "Add new server",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  cursorColor: amber,
                  onChanged: (value) => serverName = value,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.star, color: amber),
                    labelText: 'Server Nickname',
                    labelStyle: TextStyle(color: Color(0xFF888888)),
                    hintText: 'Enter a server nickname',
                    hintStyle: TextStyle(color: Color(0xFF555555)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: amber, width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Server Name';
                    } else {
                      return null;
                    }
                  },
                ),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  cursorColor: amber,
                  keyboardType: TextInputType.url,
                  onChanged: (value) => url = value,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.cloud, color: amber),
                    labelText: 'Server address',
                    labelStyle: TextStyle(color: Color(0xFF888888)),
                    hintText: 'Enter the server\'s address',
                    hintStyle: TextStyle(color: Color(0xFF555555)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: amber, width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                  ),
                  validator: (value) {
                    if (isURL(
                      value!,
                      protocols: ['http', 'https'],
                      requireProtocol: true,
                    )) {
                      return null;
                    } else {
                      return "URL not valid. Please include the protocol, e.g. https://komga.example.com";
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: amber,
                  title: const Text(
                    'Use email address to sign in',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    useEmailLogin
                        ? 'For Komga accounts that log in with an email address'
                        : 'Use a regular username instead',
                    style:
                        const TextStyle(color: Color(0xFF888888), fontSize: 12),
                  ),
                  value: useEmailLogin,
                  onChanged: (value) {
                    setState(() {
                      useEmailLogin = value;
                    });
                  },
                ),
                AutofillGroup(
                  child: Column(
                    children: [
                      TextFormField(
                        style: const TextStyle(color: Colors.white),
                        cursorColor: amber,
                        keyboardType: useEmailLogin
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        autofillHints: useEmailLogin
                            ? [AutofillHints.email]
                            : [AutofillHints.username],
                        onChanged: (value) => username = value,
                        decoration: InputDecoration(
                          icon: Icon(
                            useEmailLogin ? Icons.email : Icons.person,
                            color: amber,
                          ),
                          labelText:
                              useEmailLogin ? 'Email address' : 'Username',
                          labelStyle:
                              const TextStyle(color: Color(0xFF888888)),
                          hintText: useEmailLogin
                              ? 'Enter your account email'
                              : 'Enter your username',
                          hintStyle:
                              const TextStyle(color: Color(0xFF555555)),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: amber, width: 2),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF333333)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return useEmailLogin
                                ? 'Enter your email address'
                                : 'Enter your username';
                          }
                          if (useEmailLogin && !isEmail(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        style: const TextStyle(color: Colors.white),
                        cursorColor: amber,
                        onChanged: (value) => password = value,
                        autofillHints: const [AutofillHints.password],
                        keyboardType: TextInputType.visiblePassword,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.password, color: amber),
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Color(0xFF888888)),
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(color: Color(0xFF555555)),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: amber, width: 2),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF333333)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password';
                          }
                          return null;
                        },
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(amber),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        BlocProvider.of<ServerCubit>(context).addNewServer(
                          serverName: serverName.trim(),
                          url: url.trim().replaceAll(RegExp(r"\/+$"), ''),
                          username: username.trim(),
                          password: password,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "Submit",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ServerCard extends StatelessWidget {
  final Server server;
  const ServerCard(this.server, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.read<ServerCubit>()..setCurrentServer(server),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                BlocBuilder<ServerCheckCubit, ServerCheckState>(
                  bloc: ServerCheckCubit()..checkServer(server),
                  builder: (context, state) {
                    Color statusColor;
                    if (state is ServerCheckOnline) {
                      statusColor = const Color(0xFF4CAF50);
                    } else if (state is ServerCheckOffline) {
                      statusColor = const Color(0xFFE53935);
                    } else {
                      statusColor = const Color(0xFF757575);
                    }
                    return Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        server.username,
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: const Color(0xFF757575),
                  onPressed: () =>
                      context.read<ServerCubit>()..removeServer(server.key),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
