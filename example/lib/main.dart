import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_image_picker/model/photo.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_facebook_image_picker/flutter_facebook_image_picker.dart';

void main() {
  // check if is running on Web
  if (kIsWeb) {
    // initialiaze the facebook javascript SDK
    FacebookAuth.i.webInitialize(
      appId: "219488965589880", //<-- YOUR APP_ID
      cookie: true,
      xfbml: true,
      version: "v10.0",
    );
  }
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  MyAppState createState() {
    return new MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final FacebookAuth fbInstance = FacebookAuth.instance;
  List<Photo> _photos = [];
  String _accessToken;
  String _error;
  bool _loading = false;

  Future<Null> _login() async {
    final AccessToken accessToken = await fbInstance.accessToken;
    if (accessToken != null) {
      setState(() {
        _loading = true;
        _accessToken = accessToken.token;
      });
      _openImagePicker();
      return;
    }
    final LoginResult result = await fbInstance.login(
      permissions: ['public_profile', 'email', 'user_photos'],
    );

    switch (result.status) {
      case LoginStatus.operationInProgress:
        setState(() {
          _loading = true;
        });
        break;
      case LoginStatus.success:
        final AccessToken accessToken = result?.accessToken ?? null;
        if (accessToken == null) {
          setState(() {
            _error = "Unsuccessful facebook login attempt. Get help";
            _loading = false;
          });
        } else {
          setState(() {
            _accessToken = accessToken.token;
          });
          _openImagePicker();
        }
        break;
      case LoginStatus.cancelled:
        setState(() {
          _loading = false;
          _error = 'Login cancelled by the user.';
        });

        break;
      case LoginStatus.failed:
        setState(() {
          _error = 'Something went wrong with the login process.\n'
              'Here\'s the error Facebook gave us: ${result.message}';
          _loading = false;
        });
        break;
    }
  }

  _openImagePicker() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FacebookImagePicker(
          _accessToken,
          onDone: (items) async {
            Navigator.pop(context);
            setState(() {
              _error = null;
              _photos = items;
              _loading = false;
            });
            await fbInstance.logOut();
          },
          onCancel: () async {
            Navigator.pop(context);
            setState(() {
              _loading = false;
              _error = 'No photos received';
            });
            await fbInstance.logOut();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: new Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: !_loading
                  ? MaterialButton(
                      onPressed: () => _login(),
                      color: Colors.blue,
                      child: Text(
                        "Pick images",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    )
                  : CircularProgressIndicator(),
            ),
          ),
          _error != null ? Text(_error) : null,
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              children: List.generate(_photos.length, (index) {
                return Image.network(_photos[index].source);
              }),
            ),
          ),
        ].where((o) => o != null).toList(),
      ),
    );
  }
}
