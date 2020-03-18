import 'package:Tunein/components/AlbumSongCell.dart';
import 'package:Tunein/components/genericSongList.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/ContextMenuOption.dart';
import 'package:Tunein/models/playerstate.dart';
import 'package:Tunein/pages/single/singleAlbum.page.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/values/contextMenus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/services/themeService.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key key}) : super(key: key);

  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  final musicService = locator<MusicService>();
  final themeService = locator<ThemeService>();
  ScrollController controller = new ScrollController();

  BehaviorSubject<MapEntry<List<Tune>,List<Album>>> searchResultSongs =  BehaviorSubject<MapEntry<List<Tune>,List<Album>>>();

  search(String keyword) async{
    List<String> keywordArray = keyword.split(" ");
    keyword=keyword.toLowerCase().trim();
    Map<double, Tune> songSimilarityArray = new Map();
    List<Tune> searchedsongs =[];
    List<Album> searchedALbums=[];
    searchedsongs.addAll(musicService.songs$.value.where((song){
      if(((song.title!=null && song.title.toLowerCase().contains(keyword))
          || (song.album != null && song.album.toLowerCase().contains(keyword))
          || (song.artist != null && song.artist.toLowerCase().contains(keyword)))
      ){
        return true;
      }
      return false;
    }));

    searchedALbums.addAll(musicService.albums$.value.where((album){
      if(((album.title!=null && album.title.toLowerCase().contains(keyword))
          || (album.artist != null && album.artist.toLowerCase().contains(keyword))
      )){
        return true;
      }
      return false;
    }));
    /* ///Finding the similar songs
     musicService.songs$.value.forEach((song){
      double similarity = StringSimilarity.compareTwoStrings(keyword, song.title);
      if(similarity>0.3){
        songSimilarityArray[similarity]= song;
      }else{
        if((song.title!=null && song.title.toLowerCase().contains(keyword)) || (song.album != null && song.album.toLowerCase().contains(keyword))){
          songSimilarityArray[1.0]= song;
        }
      }
    });
    ///Sorting the songs

    List<double> sortedKeys = songSimilarityArray.keys.toList();

    sortedKeys.sort((a,b){
      return b.compareTo(a);
    });
    sortedKeys.forEach((key){
      searchedsongs.add(songSimilarityArray[key]);
    });*/

    searchResultSongs.add(MapEntry(searchedsongs,searchedALbums));
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyTheme.darkBlack,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Padding(
            padding: MediaQuery.of(context).padding,
          ),
          Material(
            color: Colors.transparent,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Color(0xff0E0E0E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.5),
                    spreadRadius: 10,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      iconSize: 18,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        autofocus: false,
                        cursorColor: MyTheme.darkRed,
                        style: TextStyle(color: Colors.white, fontSize: 20),
                        textAlign: TextAlign.start,
                        keyboardType: TextInputType.text,
                        onChanged: (String){
                          search(String);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: MyTheme.darkBlack,
                          hintText: "TRACK, ALBUM, ARTIST",
                          hintStyle:
                              TextStyle(color: Colors.white54, fontSize: 18),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      iconSize: 18,
                      icon: Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: searchResultSongs,
              builder: (BuildContext context,
                  AsyncSnapshot<MapEntry<List<Tune>,List<Album>>> snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                }

                final _songs = snapshot.data.key;
                final _albums = snapshot.data.value;
                _songs.sort((a, b) {
                  return a.title
                      .toLowerCase()
                      .compareTo(b.title.toLowerCase());
                });
                return Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding:EdgeInsets.only(top:10, left: 10),
                          child: Material(
                              child: Text(
                                "ALBUMS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              elevation: 0,
                              color:Colors.transparent
                          ),
                        )
                      ] ,
                    ),
                    Expanded(
                      flex:4,
                      child: Container(
                        height:80,
                        child: ListView.builder(
                          itemBuilder: (context, index){
                            return Material(
                              child: GestureDetector(
                                child: Container(
                                  margin: EdgeInsets.only(right: 8),
                                  child: AlbumGridCell(
                                      _albums[index],120,80
                                  ),
                                ),
                                onTap: (){
                                  goToAlbumSongsList(_albums[index]);
                                },
                              ),
                              color: Colors.transparent
                            );
                          },
                          scrollDirection: Axis.horizontal,
                          itemCount: _albums.length,
                          controller: controller,
                          shrinkWrap: false,
                          itemExtent: 120,
                          physics: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: EdgeInsets.all(10),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Container(
                          padding:EdgeInsets.only(bottom:10, left: 10),
                          child: Material(
                              child: Text(
                                "TRACKS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              elevation: 0,
                              color:Colors.transparent
                          ),
                        )
                      ] ,
                    ),
                    Expanded(
                      flex:7,
                      child: GenericSongList(
                        songs: _songs ,
                        contextMenuOptions:(song) =>songCardContextMenulist,
                        onSongCardTap: (song,_state,_isSelectedSong){
                          print(song.uri);
                          print(_state);
                          print(_isSelectedSong);
                          switch (_state) {
                            case PlayerState.playing:
                              if (_isSelectedSong) {
                                musicService.pauseMusic(song);
                              } else {
                                musicService.stopMusic();
                                musicService.playOne(
                                  song,
                                );
                              }
                              break;
                            case PlayerState.paused:
                              if (_isSelectedSong) {
                                musicService
                                    .playMusic(song);
                              } else {
                                musicService.stopMusic();
                                musicService.playOne(
                                  song,
                                );
                              }
                              break;
                            case PlayerState.stopped:
                              musicService.playOne(song);
                              break;
                            default:
                              break;
                          }
                        },
                        onContextOptionSelect: (choice, song){
                          switch(choice.id){
                            case 1: {
                              musicService.playOne(song);
                              break;
                            }
                            case 2:{
                              musicService.startWithAndShuffleQueue(song, _songs);
                              break;
                            }
                            case 3:{
                              musicService.startWithAndShuffleAlbum(song);
                              break;
                            }
                          }
                        },
                      ),
                    )
                  ]
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  void goToAlbumSongsList(album) async {
    List<Tune> returnedSongs = await  Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SingleAlbumPage(null,
            album:album
        ),
      ),
    );
  }

}
