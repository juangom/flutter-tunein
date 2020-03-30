import 'dart:async';
import 'dart:io';

import 'package:Tunein/globals.dart';
import 'package:Tunein/models/playback.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:media_notification/media_notification.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'locator.dart';

final themeService = locator<ThemeService>();




class languageService{

  FlutterI18nDelegate _flutterI18nDelegate ;


  languageService(){
    _flutterI18nDelegate = FlutterI18nDelegate(
      translationLoader: FileTranslationLoader(
          useCountryCode: false,
          fallbackFile: 'en',
          basePath: 'locale',
          forcedLocale: Locale('es')),
    );
  }

  FlutterI18nDelegate get flutterI18nDelegate => _flutterI18nDelegate;

  settingService(){
    _initStreams();
  }

  _initStreams(){

  }


  void dispose() {

  }
}

