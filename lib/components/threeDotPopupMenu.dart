import 'dart:math';

import 'package:Tunein/globals.dart';
import 'package:Tunein/models/ContextMenuOption.dart';
import 'package:flutter/material.dart';


class ThreeDotPopupMenu extends StatelessWidget {

  final List<ContextMenuOptions> choices;
  final Size screenSize;
  final Color IconColor;
  final double staticOffsetFromBottom;
  final void Function(ContextMenuOptions) onContextSelect;


  ThreeDotPopupMenu({@required this.choices, @required this.screenSize, this.IconColor, @required this.onContextSelect, this.staticOffsetFromBottom});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        flex: 2,
        child: Container(
          padding: EdgeInsets.all(4),
          child: GestureDetector(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: MyTheme.darkgrey,
                radius: 30.0,
                child: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child:Icon(
                      IconData(0xea7c, fontFamily: 'boxicons'),
                      size: 22,
                      color: IconColor!=null?IconColor:Colors.white70,
                    )
                ),
              ),
            ),
            onTapDown: (details){
              List itemList = choices.map((ContextMenuOptions choice) {
                return PopupMenuItem<ContextMenuOptions>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
              double YToSubstract = 0.0;
              if(details.globalPosition.dy >screenSize.height - 230){
                YToSubstract= max(0.0, details.globalPosition.dy - (screenSize.height - choices.length*30 - (staticOffsetFromBottom!=null?staticOffsetFromBottom:160)));
              }
              showPopMenu(context,itemList,Buttonoffset:details.globalPosition, ExtraOffset: Offset(-0,-YToSubstract) );
            },
          ),
        )
    );
  }


  void showPopMenu(context, List items,{@required Offset Buttonoffset, Offset ExtraOffset} ) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    RenderBox box = context.findRenderObject();
    RelativeRect position =  RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset(Buttonoffset.dx+(ExtraOffset!=null?ExtraOffset.dx:0.0),0.0+(ExtraOffset!=null?ExtraOffset.dy:0.0)), ancestor: overlay),
        box.localToGlobal(box.size.centerRight(Buttonoffset), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    ContextMenuOptions Choice = await showMenu<ContextMenuOptions>(context: context, position: position, items: items);
    if(Choice !=null){
      onContextSelect(Choice);
    }else{
      print("you selected nothing");
    }
  }

}
