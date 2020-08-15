import 'package:Tunein/components/pagenavheader.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/pages/library/albums.page.dart';
import 'package:Tunein/pages/library/artists.page.dart';
import 'package:Tunein/pages/library/tracks.page.dart';
import 'package:Tunein/pages/single/LandingPage.dart';
import 'package:Tunein/services/layout.dart';
import 'package:Tunein/services/locator.dart';
import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';

class LibraryPage extends StatelessWidget {
  LibraryPage({Key key}) : super(key: key);
  final layoutService = locator<LayoutService>();
  @override
  Widget build(BuildContext context) {
    var children = [
      LandingPage(),
      TracksPage(),
      ArtistsPage(),
      AlbumsPage(controller: layoutService.albumListPageController),
    ];
    Widget  shallowWidget;
    shallowWidget= Container(height: 200, color: MyTheme.darkgrey.withOpacity(.01),);
    return Column(
      children: <Widget>[
        PageNavHeader(
          pageIndex: 0,
        ),
        Flexible(
          child: StreamBuilder(
            stream: Future.delayed(Duration(milliseconds: 100),()=>true).asStream(),
            builder: (context, AsyncSnapshot snapshot){
              return AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: snapshot.hasData?PreloadPageView.builder(
                  itemCount: 4,
                  itemBuilder: (BuildContext context, int position){
                    return children[position];
                  },
                  onPageChanged: (int position) {
                      //print("position from the pagePloader: ${position}");
                  },
                  preloadPagesCount: 3,
                  controller: layoutService.pageServices[0].pageViewController,
                ):shallowWidget,
              );
            },
          ),
        )
      ],
    );
  }
}
