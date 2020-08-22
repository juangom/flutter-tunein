import 'package:Tunein/globals.dart';
import 'package:flutter/material.dart';



class ShowWithFade extends StatelessWidget {
  final Widget child;
  final Duration fadeDuration;
  final Duration durationUntilFadeStarts;
  final Widget shallowWidget;


  ShowWithFade({@required this.child, this.fadeDuration, this.durationUntilFadeStarts,
  this.shallowWidget});

  @override
  Widget build(BuildContext context) {
    Widget fadedWidget = Stack(
      children: <Widget>[
        shallowWidget??Container(
          color: MyTheme.bgBottomBar,
          constraints: BoxConstraints.expand(),
        )
      ],
    );
    return StreamBuilder(
      stream: Future.delayed(durationUntilFadeStarts??Duration(milliseconds: 200), ()=>true).asStream(),
      builder: (context, AsyncSnapshot<dynamic> snapshot){
        return AnimatedSwitcher(
          duration: fadeDuration??Duration(milliseconds: 200),
          child: !snapshot.hasData?fadedWidget:Container(
            child: child,
          ),
        );
      },
    );
  }
}
