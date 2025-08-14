import 'dart:developer';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:vikunja_app/api/client.dart';
import 'package:vikunja_app/global.dart';
import 'package:vikunja_app/models/user.dart';
import 'package:vikunja_app/pages/user/register.dart';
import 'package:vikunja_app/theme/button.dart';
import 'package:vikunja_app/theme/buttonText.dart';
import 'package:vikunja_app/theme/constants.dart';
import 'package:vikunja_app/utils/validator.dart';

import '../../components/SentryModal.dart';
import '../../models/server.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _serverConfigured = false;
  bool _rememberMe = false;
  bool init = false;
  List<String> pastServers = [];
  Server? _serverInfo;

  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final FlutterAppAuth _appAuth = FlutterAppAuth();



  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      if (VikunjaGlobal.of(context).expired) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Login has expired. Please reenter your details!")));
        setState(() {
          _serverController.text = VikunjaGlobal.of(context).client.base;
          _usernameController.text =
              VikunjaGlobal.of(context).currentUser?.username ?? "";
        });
      }
      final client = VikunjaGlobal.of(context).client;
      await VikunjaGlobal.of(context)
          .settingsManager
          .getIgnoreCertificates()
          .then((value) =>
              setState(() => client.ignoreCertificates = value == "1"));

      await VikunjaGlobal.of(context)
          .settingsManager
          .getPastServers()
          .then((value) {
        print(value);
        if (value != null) setState(() => pastServers = value);
      });
      showSentryModal(context, VikunjaGlobal.of(context));
    });
  }

  @override
  Widget build(BuildContext ctx) {
    Client client = VikunjaGlobal.of(context).client;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Builder(
            builder: (BuildContext context) => Form(
              autovalidateMode: AutovalidateMode.always,
              key: _formKey,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Image(
                        image: Theme.of(context).brightness == Brightness.dark
                            ? AssetImage('assets/vikunja_logo_full_white.png')
                            : AssetImage('assets/vikunja_logo_full.png'),
                        height: 85.0,
                        semanticLabel: 'Vikunja Logo',
                      ),
                    ),
                    // Server URL Input
                    if (!_serverConfigured) ..._buildServerSelectionWidgets(),
                    // Authentication options after server is configured
                    if (_serverConfigured) ..._buildAuthenticationWidgets(),
                    // Settings
                    CheckboxListTile(
                        title: Text("Ignore Certificates"),
                        value: client.ignoreCertificates,
                        onChanged: (value) {
                          setState(
                              () => client.reloadIgnoreCerts(value ?? false));
                          VikunjaGlobal.of(context)
                              .settingsManager
                              .setIgnoreCertificates(value ?? false);
                          VikunjaGlobal.of(context).client.ignoreCertificates =
                              value ?? false;
                        }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildServerSelectionWidgets() {
    return [
      Padding(
        padding: vStandardVerticalPadding,
        child: Row(children: [
          Expanded(
            child: TypeAheadField(
              controller: _serverController,
              builder: (context, controller, focusnode) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusnode,
                  enabled: !_loading,
                  validator: (address) {
                    return (isUrl(address) ||
                            address != null ||
                            address!.isEmpty)
                        ? null
                        : 'Invalid URL';
                  },
                  decoration: new InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Server Address'),
                );
              },
              onSelected: (suggestion) {
                _serverController.text = suggestion;
                setState(
                    () => _serverController.text = suggestion);
              },
              itemBuilder:
                  (BuildContext context, Object? itemData) {
                return Card(
                    child: Container(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(itemData.toString()),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    pastServers.remove(
                                        itemData.toString());
                                    VikunjaGlobal.of(context)
                                        .settingsManager
                                        .setPastServers(
                                            pastServers);
                                  });
                                },
                                icon: Icon(Icons.clear))
                          ],
                        )));
              },
              suggestionsCallback: (String pattern) {
                List<String> matches = <String>[];
                matches.addAll(pastServers);
                matches.retainWhere((s) {
                  return s
                      .toLowerCase()
                      .contains(pattern.toLowerCase());
                });
                return matches;
              },
            ),
          ),
        ]),
      ),
      Builder(
          builder: (context) => FancyButton(
                onPressed: !_loading
                    ? () {
                        if (_formKey.currentState!.validate() &&
                            _serverController.text.isNotEmpty) {
                          _configureServer();
                        }
                      }
                    : null,
                child: _loading
                    ? CircularProgressIndicator()
                    : VikunjaButtonText('Continue'),
              )),
    ];
  }

  List<Widget> _buildAuthenticationWidgets() {
    List<Widget> widgets = [];

    // Back button
    widgets.add(
      Padding(
        padding: vStandardVerticalPadding,
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _serverConfigured = false;
                  _serverInfo = null;
                });
              },
              icon: Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Server: ${_serverController.text}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );

    // OpenID Connect providers
    if (_serverInfo?.auth?.openidConnect?.enabled == true &&
        _serverInfo?.auth?.openidConnect?.providers != null) {
      widgets.add(
        Padding(
          padding: vStandardVerticalPadding,
          child: Text(
            'Login with Identity Provider',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );

      for (var provider in _serverInfo!.auth!.openidConnect!.providers!) {
        widgets.add(
          Padding(
            padding: vStandardVerticalPadding,
            child: FancyButton(
              onPressed: !_loading
                  ? () => _loginWithOpenId(provider)
                  : null,
              child: VikunjaButtonText('Login with ${provider.name ?? provider.key}'),
            ),
          ),
        );
      }
    }

    // Local authentication (username/password)
    if (_serverInfo?.auth?.local?.enabled == true) {
      widgets.add(
        Padding(
          padding: vStandardVerticalPadding,
          child: Text(
            'Login with Username & Password',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );

      widgets.add(
        Padding(
          padding: vStandardVerticalPadding,
          child: TextFormField(
            enabled: !_loading,
            controller: _usernameController,
            autofillHints: [AutofillHints.username],
            decoration: new InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Username'),
          ),
        ),
      );

      widgets.add(
        Padding(
          padding: vStandardVerticalPadding,
          child: TextFormField(
            enabled: !_loading,
            controller: _passwordController,
            autofillHints: [AutofillHints.password],
            decoration: new InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password'),
            obscureText: true,
          ),
        ),
      );

      widgets.add(
        Padding(
          padding: vStandardVerticalPadding,
          child: CheckboxListTile(
            value: _rememberMe,
            onChanged: (value) =>
                setState(() => _rememberMe = value ?? false),
            title: Text("Remember me"),
          ),
        ),
      );

      widgets.add(
        Builder(
            builder: (context) => FancyButton(
                  onPressed: !_loading
                      ? () {
                          if (_usernameController.text.isNotEmpty &&
                              _passwordController.text.isNotEmpty) {
                            _loginUser(context);
                          }
                        }
                      : null,
                  child: _loading
                      ? CircularProgressIndicator()
                      : VikunjaButtonText('Login'),
                )),
      );

      // Registration button if enabled
      if (_serverInfo?.auth?.local?.registrationEnabled == true) {
        widgets.add(
          Builder(
              builder: (context) => FancyButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterPage())),
                    child: VikunjaButtonText('Register'),
                  )),
        );
      }
    }

    return widgets;
  }

  _configureServer() async {
    String server = _serverController.text;
    if (server.isEmpty) return;

    if (!pastServers.contains(server)) pastServers.add(server);
    await VikunjaGlobal.of(context).settingsManager.setPastServers(pastServers);

    setState(() => _loading = true);
    try {
      var vGlobal = VikunjaGlobal.of(context);
      vGlobal.client.showSnackBar = false;
      vGlobal.client.configure(base: server);
      Server? info = await vGlobal.serverService.getInfo();

      if (info == null) {
        throw Exception("Failed to get server information");
      }

      setState(() {
        _serverInfo = info;
        _serverConfigured = true;
      });
    } catch (ex) {
      print(ex);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect to server: ${ex.toString()}'),
        ),
      );
    } finally {
      VikunjaGlobal.of(context).client.showSnackBar = true;
      setState(() => _loading = false);
    }
  }

  _loginWithOpenId(OpenIdProvider provider) async {
    setState(() => _loading = true);

  try {
    // Use discoveryUrl for OpenID Connect discovery
    String discoveryUrl = Uri.parse(provider.authUrl!).origin + '/.well-known/openid-configuration';
    String clientId = '38b36fd7-8427-431d-9c80-29bcbf2eb5ae'; // provider.clientId ?? '';
    String redirectUrl = 'vikunja://oauth'; // You may need to configure this
    List<String> scopes = provider.scope?.split(' ') ?? ['openid', 'profile', 'email'];

    // Perform OAuth flow using discoveryUrl
    final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        redirectUrl,
        discoveryUrl: discoveryUrl,
        scopes: scopes,
      ),
    );

      if (result != null) {
        // Use the access token to authenticate with Vikunja
        await _loginUserByToken(result.accessToken!);
      }
    } catch (ex) {
      print('OpenID login error: $ex');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OpenID login failed: ${ex.toString()}'),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  _loginUser(BuildContext context) async {
    String server = _serverController.text;
    String username = _usernameController.text;
    String password = _passwordController.text;
    if (server.isEmpty) return;

    setState(() => _loading = true);
    try {
      var vGlobal = VikunjaGlobal.of(context);
      vGlobal.client.showSnackBar = false;
      vGlobal.client.configure(base: server);

      UserTokenPair newUser = await vGlobal.newUserService!
          .login(username, password, rememberMe: this._rememberMe);

      if (newUser.error == 1017) {
        TextEditingController totpController = TextEditingController();
        bool dismissed = true;
        await showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: Text("Enter One Time Passcode"),
            content: TextField(
              controller: totpController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    dismissed = false;
                    Navigator.pop(context);
                  },
                  child: Text("Login"))
            ],
          ),
        );
        if (!dismissed) {
          newUser = await vGlobal.newUserService!.login(username, password,
              rememberMe: this._rememberMe, totp: totpController.text);
        } else {
          throw Exception();
        }
      }
      if (newUser.error > 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(newUser.errorString)));
      }

      if (newUser.error == 0)
        vGlobal.changeUser(newUser.user!, token: newUser.token, base: server);
    } catch (ex) {
      print(ex);
    } finally {
      VikunjaGlobal.of(context).client.showSnackBar = true;
      setState(() => _loading = false);
    }
  }

  _loginUserByToken(String accessToken) async {
    VikunjaGlobalState vGS = VikunjaGlobal.of(context);

    vGS.client.configure(
        token: accessToken,
        base: _serverController.text,
        authenticated: true);
    setState(() => _loading = true);
    try {
      var newUser = await vGS.newUserService?.getCurrentUser();
      if (newUser != null)
        vGS.changeUser(newUser,
            token: accessToken, base: _serverController.text);
    } catch (e) {
      log("failed to change to user by token");
      log(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: ${e.toString()}'),
        ),
      );
    }
    setState(() => _loading = false);
  }
}
