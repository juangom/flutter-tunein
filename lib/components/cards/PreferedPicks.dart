import 'dart:io';
import 'dart:ui';

import 'package:Tunein/globals.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/themeService.dart';
import 'package:flutter/material.dart';


final themeService = locator<ThemeService>();

class PreferredPicks extends StatelessWidget {

  final String bottomTitle;
  final String imageUri;
  final List<int> colors;
  VoidCallback onSavePressed;
  VoidCallback onPlayPressed;


  PreferredPicks({this.bottomTitle, this.imageUri, this.colors,
    this.onSavePressed, this.onPlayPressed});

  @override
  Widget build(BuildContext context) {
    Color shadowColor = ((colors!=null && colors.length!=0)?new Color(colors[0]):Color(themeService.defaultColors[0])).withOpacity(.7);
    return Container(
      height: 60,
      width: 60,
      margin: EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          border: Border.all(width: .3, color: MyTheme.bgBottomBar),
        ),
        child: Stack(
          overflow: Overflow.clip,
          children: <Widget>[
            Container(
              child: ConstrainedBox(
                child: imageUri == null ? Image.asset("images/artist.jpg",fit: BoxFit.cover) : Image(
                  image: FileImage(File(imageUri)),
                  fit: BoxFit.cover,
                  colorBlendMode: BlendMode.clear,
                ),
                constraints: BoxConstraints.expand(),
              ),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.all(width: .3, color: MyTheme.bgBottomBar),
              ),
            ),
            Container(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 3),
                    child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100.withOpacity(0.2),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          border: Border.all(width: .3, color: MyTheme.bgBottomBar),
                        )
                    ),
                  ),
                )
            ),
            Positioned(
              child: Text(bottomTitle??"Choice card",
                style: TextStyle(
                    color: ((colors!=null && colors.length!=0)?new Color(colors[1]):Color(0xffffffff)).withOpacity(.8),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    shadows: [
                      Shadow( // bottomLeft
                          offset: Offset(-1.2, -1.2),
                          color: shadowColor,
                          blurRadius: 2
                      ),
                      Shadow( // bottomRight
                          offset: Offset(1.2, -1.2),
                          color: shadowColor,
                          blurRadius: 2
                      ),
                      Shadow( // topRight
                          offset: Offset(1.2, 1.2),
                          color: shadowColor,
                          blurRadius: 2
                      ),
                      Shadow( // topLeft
                        offset: Offset(-1.2, 1.2),
                        color: shadowColor,
                        blurRadius: 2,
                      ),
                    ]
                ),
              ),
              bottom: 5,
              left: 5,
            ),
          ],
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(width: .3, color: MyTheme.bgBottomBar),
      ),
    );
  }
}
