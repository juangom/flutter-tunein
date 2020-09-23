import 'dart:io';

import 'package:Tunein/components/common/selectableTile.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/models/ContextMenuOption.dart';
import 'package:Tunein/plugins/nano.dart';
import 'package:Tunein/services/dialogService.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/musicService.dart';
import 'package:Tunein/utils/ConversionUtils.dart';
import 'package:dart_tags/dart_tags.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:dart_tags/src/readers/id3v2.dart';
import 'package:dart_tags/src/writers/id3v2.dart';
final musicService = locator<MusicService>();


class SongTags extends StatefulWidget {

  Tune song;
  double heightToSubtract;
  SongTags(this.song, {this.heightToSubtract});

  @override
  _SongTagsState createState() => _SongTagsState();
}

class _SongTagsState extends State<SongTags> {
  Tune song;
  String title;
  String album;
  String artist;
  String year;
  String track;
  String genre;
  String composer;
  String comment;
  String lyrics;
  String albumArt;
  List<Artist> artists = musicService.artists$.value;
  List<Album> albums = musicService.albums$.value;

  _SongTagsState();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    this.song=widget.song;
    this.title=this.song.title;
    this.album=this.song.album;
    this.artist=this.song.artist;
    this.year=this.song.year;
    this.track=this.song.numberInAlbum.toString();
    this.genre=this.song.genre;
    this.albumArt=this.song.albumArt;
  }


  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

  }


  setNewAlbum(Album newAlbum){
    setState(() {
      this.album=newAlbum.title;
      this.albumArt=newAlbum.albumArt;
    });
  }


  setNewArtist(Artist newArtist){
    setState(() {
      this.artist=newArtist.name;
    });
  }

  @override
  Widget build(BuildContext context) {

    final  bottom = MediaQuery.of(context).viewInsets.bottom;
    Size size = MediaQuery.of(context).size;
    return Container(
      child: Material(
        color: MyTheme.bgBottomBar,
        child: Column(
          children: <Widget>[
            Material(
              child: Container(
                child: new Container(
                  margin: EdgeInsets.all(0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          height:60,
                          width:60,
                          child: FadeInImage(
                            placeholder: AssetImage('images/track.png'),
                            fadeInDuration: Duration(milliseconds: 200),
                            fadeOutDuration: Duration(milliseconds: 100),
                            image: this.albumArt != null
                                ? FileImage(
                              new File(this.albumArt),
                            )
                                : AssetImage('images/track.png'),
                          ),
                        ),
                        flex: 2,
                      ),
                      Expanded(
                        flex: 8,
                        child: Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        "Editing : ${this.song.uri}",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    flex: 10,
                                  ),
                                  Expanded(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Padding(
                                          padding: const EdgeInsets.only(right: 5.0),
                                          child:InkWell(
                                            child: Icon(
                                              Icons.save,
                                              size: 26,
                                              color: MyTheme.darkRed,
                                            ),
                                            onTap: (){
                                              DialogService.showToast(context,
                                                  backgroundColor: MyTheme.darkBlack,
                                                  color: MyTheme.grey300,
                                                  message: "Saving ....",
                                                  duration: 2
                                              );
                                              musicService.saveSongTags(Tune(
                                                this.song.id,
                                                this.title,
                                                this.artist,
                                                this.album,
                                                this.song.duration,
                                                this.song.uri,
                                                this.song.albumArt,
                                                this.song.colors,
                                                int.tryParse(this.track),
                                                this.genre,
                                                this.year,
                                              ), this.song).then((value) {
                                                print("SAVING TAGS SHOULD BE DONE");
                                                DialogService.showToast(context,
                                                    backgroundColor: MyTheme.darkBlack,
                                                    color: MyTheme.darkRed,
                                                    message: "Song Tags Saved",
                                                    duration: 3
                                                );
                                              }).catchError((onError){
                                                print(onError);
                                              });
                                            },
                                          )
                                      )
                                      ,
                                    ),
                                    flex: 2,
                                  )
                                ],
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              ),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        this.song.title??"Unknown title",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w400,
                                          color: MyTheme.grey300,
                                        ),
                                      ),
                                    ),
                                    flex: 8,
                                  ),
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.bottomRight,
                                      margin: EdgeInsets.all(5),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Container(
                                            child: Text(
                                              "${ConversionUtils.DurationToStandardTimeDisplay(inputDuration: Duration(milliseconds: ConversionUtils.songListToDuration([this.song]).floor()), showHours: false)}",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            margin: EdgeInsets.only(right: 5),
                                          ),
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.white70,
                                          )
                                        ],
                                      ),
                                    ),
                                    flex: 4,
                                  )
                                ],
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.only(right: 10, left: 10),
                          alignment: Alignment.center,
                        ),
                      )
                    ],
                  ),
                  height: 100,
                ),
                color: MyTheme.bgBottomBar,
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top
                ),
              ),
              elevation: 5.0,
            ),
            Flexible(
              child:Container(
                child:  SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottom),
                  child: Container(
                    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.all(5),
                    child: Column(
                      children: [
                        Container(
                          child: Row(
                            children: [
                              Text("**",
                                style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: MyTheme.grey300,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.2
                                ),
                                textAlign: TextAlign.start,
                              ),
                              Text("Don't touch fields you don't want to edit",
                                style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: MyTheme.grey300,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.2
                                ),
                              )
                            ],
                          ),
                          margin: EdgeInsets.only(bottom: 5),
                        ),
                        Container(
                          child: TextField(
                            onChanged: (string){
                              this.title=string;
                            },
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                                hintText: this.title!=null && this.title!=""?this.title:"Add a Title to this song",
                                hintStyle: TextStyle(
                                    color: MyTheme.grey500.withOpacity(0.6)
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.grey300.withOpacity(.7),
                                        style: BorderStyle.solid,
                                        width: 1
                                    )
                                ),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.grey300.withOpacity(.9),
                                        style: BorderStyle.solid,
                                        width: 2
                                    )
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: "Song Title",
                                labelStyle: TextStyle(
                                  fontSize: 17,
                                  color: MyTheme.darkRed.withOpacity(.8),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.4,
                                )
                            ),
                          ),
                          margin: EdgeInsets.only(top: 8),
                        ),
                        Container(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (string){
                                    this.album=string;
                                  },
                                  enableSuggestions: true,
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: this.album!=null && this.album!=""?this.album:"Add an Album title to this song",
                                    hintStyle: TextStyle(
                                        color: MyTheme.grey500.withOpacity(0.6)
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: MyTheme.grey300.withOpacity(.7),
                                            style: BorderStyle.solid,
                                            width: 1
                                        )
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: MyTheme.grey300.withOpacity(.9),
                                            style: BorderStyle.solid,
                                            width: 2
                                        )
                                    ),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    labelText: "Song Album",
                                    labelStyle: TextStyle(
                                      fontSize: 17,
                                      color: MyTheme.darkRed.withOpacity(.8),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ),
                                flex: 10,
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Material(
                                    color: MyTheme.darkBlack,
                                    elevation: 12,
                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                    child: IconButton(
                                      icon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(Icons.list, color: MyTheme.darkRed, size: 28)
                                        ],
                                      ),
                                      onPressed: (){
                                        Album selectedAlbum;
                                        BehaviorSubject<String> albumListStream = new BehaviorSubject<String>();
                                        final TextEditingController searchController = new TextEditingController();
                                        Future.delayed(Duration(milliseconds: 200), ()async{
                                          bool returnedData = await DialogService.showPersistentDialog(context,
                                              showCancelAction: true,
                                              content: Container(
                                                height: MediaQuery.of(context).size.height/2.3,
                                                width: MediaQuery.of(context).size.width/1.2,
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      child:  TextField(
                                                        onChanged: (string){
                                                          albumListStream.add(searchController.text);
                                                        },
                                                        controller: searchController,
                                                        enableSuggestions: true,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                        decoration: InputDecoration(
                                                          hintText: "Type an album's name",
                                                          hintStyle: TextStyle(
                                                              color: MyTheme.grey500.withOpacity(0.6)
                                                          ),
                                                          enabledBorder: UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: MyTheme.grey300.withOpacity(.9),
                                                                  style: BorderStyle.solid,
                                                                  width: 1
                                                              )
                                                          ),
                                                          focusedBorder: UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: MyTheme.darkRed.withOpacity(.9),
                                                                  style: BorderStyle.solid,
                                                                  width: 1.5
                                                              )
                                                          ),
                                                          floatingLabelBehavior: FloatingLabelBehavior.always,
                                                          labelText: "Search",
                                                          labelStyle: TextStyle(
                                                            fontSize: 15,
                                                            color: MyTheme.grey300.withOpacity(.7),
                                                            fontWeight: FontWeight.w500,
                                                            letterSpacing: 1.4,
                                                          ),
                                                        ),
                                                      ),
                                                      padding: EdgeInsets.all(5),
                                                      margin: EdgeInsets.only(bottom: 5, top: 5),
                                                    ),
                                                    Flexible(
                                                      child: StreamBuilder(
                                                        initialData: null,
                                                        stream: albumListStream,
                                                        builder: (context, AsyncSnapshot<String> snapshot){
                                                          List<Album> newAlbums = snapshot.data!=null?albums.where((element) => element.title.toLowerCase().startsWith(snapshot.data.toLowerCase())).toList():albums;

                                                          return GridView.builder(
                                                            padding: EdgeInsets.all(3),
                                                            itemBuilder: (context, index){
                                                              Album currentAlbum = newAlbums[index];
                                                              return new SelectableTile.mediumWithSubtitle(
                                                                subtitle: currentAlbum.artist,
                                                                imageUri: currentAlbum.albumArt,
                                                                title: currentAlbum.title,
                                                                isSelected: currentAlbum.title == this.album,
                                                                selectedBackgroundColor: MyTheme.darkRed,
                                                                onTap: (willItBeSelected){
                                                                  if(willItBeSelected){
                                                                    selectedAlbum=currentAlbum;
                                                                    Navigator.of(context).pop(true);
                                                                  }else{
                                                                    selectedAlbum=null;
                                                                  }
                                                                },
                                                                placeHolderAssetUri: "images/cover.png",
                                                              );
                                                            },
                                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                              crossAxisCount: 2,
                                                              mainAxisSpacing: 2.5,
                                                              crossAxisSpacing: 2.5,
                                                              childAspectRatio: 2,
                                                            ),
                                                            semanticChildCount: newAlbums.length,
                                                            cacheExtent: 150,
                                                            itemCount: newAlbums.length,
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              title: "Choose An existing Album",
                                              padding: EdgeInsets.all(5)
                                          );
                                          if(selectedAlbum!=null){
                                            setState(() {
                                              setNewAlbum(selectedAlbum);
                                            });
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                flex: 2,
                              )
                            ],
                          ),
                          margin: EdgeInsets.only(top: 8),
                        ),
                        Container(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (string){
                                    this.artist=string;
                                  },
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                      hintText: this.artist!=null && this.artist!=""?this.artist:"Add an Artist to this song",
                                      hintStyle: TextStyle(
                                          color: MyTheme.grey500.withOpacity(0.6)
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: MyTheme.grey300.withOpacity(.7),
                                              style: BorderStyle.solid,
                                              width: 1
                                          )
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: MyTheme.grey300.withOpacity(.9),
                                              style: BorderStyle.solid,
                                              width: 2
                                          )
                                      ),
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      labelText: "Song Artist",
                                      labelStyle: TextStyle(
                                        fontSize: 17,
                                        color: MyTheme.darkRed.withOpacity(.8),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.4,
                                      )
                                  ),
                                ),
                                flex: 10,
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(left: 5),
                                  child: Material(
                                    color: MyTheme.darkBlack,
                                    elevation: 12,
                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                    child: IconButton(
                                      icon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(Icons.list, color: MyTheme.darkRed, size: 28)
                                        ],
                                      ),
                                      onPressed: (){
                                        Artist selectedArtist;
                                        BehaviorSubject<String> artistListStream = new BehaviorSubject<String>();
                                        final TextEditingController searchController = new TextEditingController();
                                        Future.delayed(Duration(milliseconds: 200), ()async{
                                          bool returnedData = await DialogService.showPersistentDialog(context,
                                              showCancelAction: true,
                                              content: Container(
                                                height: MediaQuery.of(context).size.height/2.5,
                                                width: MediaQuery.of(context).size.width/1.2,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      child:  TextField(
                                                        onChanged: (string){
                                                          artistListStream.add(searchController.text);
                                                        },
                                                        controller: searchController,
                                                        enableSuggestions: true,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                        decoration: InputDecoration(
                                                          hintText: "Type an artist's name",
                                                          hintStyle: TextStyle(
                                                              color: MyTheme.grey500.withOpacity(0.6)
                                                          ),
                                                          enabledBorder: UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: MyTheme.grey300.withOpacity(.9),
                                                                  style: BorderStyle.solid,
                                                                  width: 1
                                                              )
                                                          ),
                                                          focusedBorder: UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: MyTheme.darkRed.withOpacity(.9),
                                                                  style: BorderStyle.solid,
                                                                  width: 1.5
                                                              )
                                                          ),
                                                          floatingLabelBehavior: FloatingLabelBehavior.always,
                                                          labelText: "Search",
                                                          labelStyle: TextStyle(
                                                            fontSize: 15,
                                                            color: MyTheme.grey300.withOpacity(.7),
                                                            fontWeight: FontWeight.w500,
                                                            letterSpacing: 1.4,
                                                          ),
                                                        ),
                                                      ),
                                                      padding: EdgeInsets.all(5),
                                                      margin: EdgeInsets.only(bottom: 5, top: 5),
                                                    ),
                                                    Flexible(
                                                      child: StreamBuilder(
                                                        initialData: null,
                                                        stream: artistListStream,
                                                        builder: (context, AsyncSnapshot<String> snapshot){
                                                          List<Artist> newArtists = snapshot.data!=null?artists.where((element) => element.name.toLowerCase().startsWith(snapshot.data.toLowerCase())).toList():artists;
                                                          return GridView.builder(
                                                            padding: EdgeInsets.all(3),
                                                            itemBuilder: (context, index){
                                                              Artist currentArtist = newArtists[index];
                                                              return SelectableTile.mediumWithSubtitle(
                                                                subtitle: "${currentArtist.albums.length} albums",
                                                                imageUri: currentArtist.coverArt,
                                                                title: currentArtist.name,
                                                                isSelected: currentArtist.name == this.artist,
                                                                selectedBackgroundColor: MyTheme.darkRed,
                                                                onTap: (willItBeSelected){
                                                                  if(willItBeSelected){
                                                                    selectedArtist=currentArtist;
                                                                    Navigator.of(context).pop(true);
                                                                  }else{
                                                                    selectedArtist=null;
                                                                  }
                                                                },
                                                                placeHolderAssetUri: "images/artist.jpg",
                                                              );
                                                            },
                                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                              crossAxisCount: 2,
                                                              mainAxisSpacing: 2.5,
                                                              crossAxisSpacing: 2.5,
                                                              childAspectRatio: 2,
                                                            ),
                                                            semanticChildCount: newArtists.length,
                                                            cacheExtent: 120,
                                                            itemCount: newArtists.length,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              title: "Choose An existing Artist",
                                              padding: EdgeInsets.all(5)
                                          );
                                          if(selectedArtist!=null){
                                            setNewArtist(selectedArtist);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                flex: 2,
                              )
                            ],
                          ),
                          margin: EdgeInsets.only(top: 8),
                        ),
                        Container(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  child: TextField(
                                    onChanged: (string){
                                      this.year=string;
                                    },
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                        hintText: this.year!=null && this.year!=""?this.year:"Year",
                                        hintStyle: TextStyle(
                                            color: MyTheme.grey500.withOpacity(0.6)
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: MyTheme.grey300.withOpacity(.7),
                                                style: BorderStyle.solid,
                                                width: 1
                                            )
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: MyTheme.grey300.withOpacity(.9),
                                                style: BorderStyle.solid,
                                                width: 2
                                            )
                                        ),
                                        floatingLabelBehavior: FloatingLabelBehavior.always,
                                        labelText: "Year",
                                        labelStyle: TextStyle(
                                          fontSize: 17,
                                          color: MyTheme.darkRed.withOpacity(.8),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1.4,
                                        )
                                    ),
                                  ),
                                  padding: EdgeInsets.only(right: 8),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  child: TextField(
                                    onChanged: (string){
                                      this.track=string;
                                    },
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                        hintText: this.track!=null && this.track.toString()!=""?this.track.toString():"Track",
                                        hintStyle: TextStyle(
                                            color: MyTheme.grey500.withOpacity(0.6)
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: MyTheme.grey300.withOpacity(.7),
                                                style: BorderStyle.solid,
                                                width: 1
                                            )
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: MyTheme.grey300.withOpacity(.9),
                                                style: BorderStyle.solid,
                                                width: 2
                                            )
                                        ),
                                        floatingLabelBehavior: FloatingLabelBehavior.always,
                                        labelText: "Track",
                                        labelStyle: TextStyle(
                                          fontSize: 17,
                                          color: MyTheme.darkRed.withOpacity(.8),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1.4,
                                        )
                                    ),
                                  ),
                                  padding: EdgeInsets.only(right: 8),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: TextField(
                                  onChanged: (string){
                                    this.genre=string;
                                  },
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: this.genre!=null && this.genre.toString()!=""?this.genre.toString():"genre",
                                    hintStyle: TextStyle(
                                        color: MyTheme.grey500.withOpacity(0.6)
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: MyTheme.grey300.withOpacity(.7),
                                            style: BorderStyle.solid,
                                            width: 1
                                        )
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: MyTheme.grey300.withOpacity(.9),
                                            style: BorderStyle.solid,
                                            width: 2
                                        )
                                    ),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    labelText: "Genre",
                                    labelStyle: TextStyle(
                                      fontSize: 17,
                                      color: MyTheme.darkRed.withOpacity(.8),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          margin: EdgeInsets.only(top: 8),
                        ),
                        Container(
                          child: TextField(
                            onChanged: (string){
                              this.composer=string;
                            },
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                                hintText: this.artist!=null && this.artist!=""?this.artist:"Set A Composer to this song",
                                hintStyle: TextStyle(
                                    color: MyTheme.grey500.withOpacity(0.6)
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.grey300.withOpacity(.7),
                                        style: BorderStyle.solid,
                                        width: 1
                                    )
                                ),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.grey300.withOpacity(.9),
                                        style: BorderStyle.solid,
                                        width: 2
                                    )
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: "Composer",
                                labelStyle: TextStyle(
                                  fontSize: 17,
                                  color: MyTheme.darkRed.withOpacity(.8),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.4,
                                )
                            ),
                          ),
                          margin: EdgeInsets.only(top: 8),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          child: TextField(
                            onChanged: (string){
                              this.lyrics=string;
                            },
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            minLines: 4,
                            maxLines: 5,
                            decoration: InputDecoration(
                                hintText: this.artist!=null && this.artist!=""?this.artist:"No lyrics",
                                hintStyle: TextStyle(
                                    color: MyTheme.grey500.withOpacity(0.6)
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.grey300.withOpacity(.7),
                                        style: BorderStyle.solid,
                                        width: 1
                                    )
                                ),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.grey300.withOpacity(.9),
                                        style: BorderStyle.solid,
                                        width: 2
                                    )
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: "Lyrics",
                                labelStyle: TextStyle(
                                  fontSize: 17,
                                  color: MyTheme.darkRed.withOpacity(.8),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.4,
                                )
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          child: TextField(
                            onChanged: (string){
                              this.comment=string;
                            },
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            minLines: 4,
                            maxLines: 5,
                            decoration: InputDecoration(
                                hintText: "No Comment on this file",
                                hintStyle: TextStyle(
                                    color: MyTheme.grey500.withOpacity(0.6)
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.grey300.withOpacity(.7),
                                        style: BorderStyle.solid,
                                        width: 1
                                    )
                                ),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: MyTheme.grey300.withOpacity(.9),
                                        style: BorderStyle.solid,
                                        width: 2
                                    )
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: "Comments",
                                labelStyle: TextStyle(
                                  fontSize: 17,
                                  color: MyTheme.darkRed.withOpacity(.8),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.4,
                                )
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                height: size.height - widget.heightToSubtract - MediaQuery.of(context).padding.top - 100,
              ),
            )
          ],
        ),
      ),
    );
  }


}
