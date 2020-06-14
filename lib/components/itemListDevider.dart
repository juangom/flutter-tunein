import 'package:Tunein/globals.dart';
import 'package:flutter/material.dart';





class ItemListDevider extends StatelessWidget {

  final TextStyle textStyle;
  final double height;
  final String DeviderTitle;
  final Color backgroundColor;


  const ItemListDevider({this.textStyle, this.height, this.DeviderTitle, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        child: Text(DeviderTitle??"Albums",
          style: textStyle??TextStyle(
            fontSize: 15.5,
            color: MyTheme.grey300,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.left,
        ),
        padding: EdgeInsets.all(8).add(EdgeInsets.only(top: 2,left: 4)),
      ),
      color: backgroundColor??MyTheme.bgBottomBar,
      constraints: BoxConstraints.expand(height: height??35),
    );
  }
}


class DynamicSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double maxHeight;
  final double minHeight;

  const DynamicSliverHeaderDelegate({
    @required this.child,
    this.maxHeight = 250,
    this.minHeight = 80,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  // @override
  // bool shouldRebuild(DynamicSliverHeaderDelegate oldDelegate) => true;

  @override
  bool shouldRebuild(DynamicSliverHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;
}
