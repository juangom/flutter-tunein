import 'package:Tunein/plugins/nano.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

final _androidAppRetain = MethodChannel("android_app_retain");

class ThemeService {
  BehaviorSubject<List<int>> _color$;
  BehaviorSubject<List<int>> get color$ => _color$;

  Map<String, List<int>> _savedColors;
  Map<String, List<int>> _artistDavedColors;
  ThemeService() {
    _initStreams();
    _savedColors = Map<String, List<int>>();
  }


  void updateTheme(Tune song) async {
  print(song.title);
    if (_savedColors.containsKey(song.id)) {
      print(song.id);
      _color$.add(_savedColors[song.id]);
      print(_color$.value);
      return;
    }


    String path = song.albumArt;
    print(path);
    if (path == null) {
      _color$.add([0xff111111, 0xffffffff]);
      return;
    }

    print("GETTING COLORS ");
    final colors =
        await _androidAppRetain.invokeMethod("getColor", {"path": path});
    List<int> _colors = List<int>();
    for (var color in colors) {
      _colors.add(color);
    }
    _color$.add(_colors);
    _savedColors[song.id] = _colors;
  }

  Future<List<int>> getThemeColors(Tune song) async{
    List<int> color=[];
    if (_savedColors.containsKey(song.id)) {
      color.addAll(_savedColors[song.id]);


      return color;
    }

    String path = song.albumArt;

    if (path == null) {
      color.addAll([0xff111111, 0xffffffff, 0xffffffff]);
      return color;
    }

    final colors =
    await _androidAppRetain.invokeMethod("getColor", {"path": path});

    List<int> _colors = List<int>();
    for (var color in colors) {
      _colors.add(color);
    }
    if(_colors.length<3){
      do{
        _colors.add(_colors[1]);
      }while(_colors.length<3);
    }
    color.addAll(_colors);
    _savedColors[song.id] = _colors;


    return color;
  }

  Future<List<int>> getArtistColors(Artist artist) async{
    List<int> color=[];
    if (_artistDavedColors.containsKey(artist.id)) {
      color.addAll(_artistDavedColors[artist.id]);


      return color;
    }

    String path = artist.coverArt;

    if (path == null) {
      color.addAll([0xff111111, 0xffffffff, 0xffffffff]);
      return color;
    }

    final colors =
    await _androidAppRetain.invokeMethod("getColor", {"path": path});

    List<int> _colors = List<int>();
    for (var color in colors) {
      _colors.add(color);
    }
    if(_colors.length<3){
      do{
        _colors.add(_colors[1]);
      }while(_colors.length<3);
    }
    color.addAll(_colors);
    _artistDavedColors[artist.id.toString()] = _colors;


    return color;
  }

  void _initStreams() {
    _color$ = BehaviorSubject<List<int>>.seeded([0xff111111, 0xffffffff]);
  }
}
