import 'dart:io';

import 'package:Tunein/globals.dart';
import 'package:flutter/material.dart';





class SelectableTile extends StatefulWidget {
  final String imageUri;
  final String title;
  dynamic Function(dynamic) onTap;
  bool isSelected;
  final String placeHolderAssetUri;
  Color initialTextColor;
  Color initialBackgroundColor;
  Color selectedTextColor;
  Color selectedBackgroundColor;
  SelectableTile({@required this.imageUri, @required this.title, this.onTap, this.isSelected, this.placeHolderAssetUri,
    this.initialBackgroundColor, this.selectedBackgroundColor, this.selectedTextColor, this.initialTextColor});

  @override
  _SelectableTileState createState() => _SelectableTileState();
}

class _SelectableTileState extends State<SelectableTile> {
  String imageUri;
  String title;
  dynamic Function(dynamic) onTap;
  bool isSelected;
  Color initialTextColor;
  Color initialBackgroundColor;
  Color selectedTextColor;
  Color selectedBackgroundColor;
  String placeHolderAssetUri;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    imageUri=widget.imageUri;
    title= widget.title;
    onTap=widget.onTap;
    isSelected=widget.isSelected;
    placeHolderAssetUri= widget.placeHolderAssetUri;
    initialBackgroundColor=widget.initialBackgroundColor;
    initialTextColor=widget.initialTextColor;
    selectedTextColor=widget.selectedTextColor;
    selectedBackgroundColor=widget.selectedBackgroundColor;
  }
  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected?selectedBackgroundColor??MyTheme.darkBlack:initialBackgroundColor??MyTheme.darkBlack,
      elevation: 16,
      child: InkWell(
        onTap: (){
          print("tapped element, will setState anyways");
          onTap!=null?onTap(!isSelected):null;
          setState(() {
            isSelected=!isSelected;
          });
        },
        child: Container(
          padding: EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 5),
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: FadeInImage(
                    placeholder: AssetImage(placeHolderAssetUri??'images/track.png'),
                    fadeInDuration: Duration(milliseconds: 200),
                    fadeOutDuration: Duration(milliseconds: 100),
                    image: imageUri != null
                        ? FileImage(
                      new File(imageUri),
                    )
                        : AssetImage(placeHolderAssetUri??'images/track.png'),
                  ),
                ),
              ),
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          (title == null)
                              ? "Unknon Album"
                              : title,
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          textWidthBasis: TextWidthBasis.parent,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected?selectedTextColor??MyTheme.grey300:initialTextColor??MyTheme.grey300,
                          ),
                        )

                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}


