import 'package:Tunein/components/cards/PreferedPicks.dart';
import 'package:Tunein/components/itemListDevider.dart';
import 'package:Tunein/globals.dart';
import 'package:flutter/material.dart';








class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyTheme.darkBlack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: MediaQuery.of(context).padding,
          ),
          Flexible(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: ItemListDevider(DeviderTitle: "Preferred Pics",
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height:150,
                    child: ListView.builder(
                      itemBuilder: (context, index){
                        return Material(
                            child: GestureDetector(
                              child: Container(
                                margin: EdgeInsets.only(right: 8),
                                child: PreferredPicks(
                                  bottomTitle: "Most Played",
                                  colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                ),
                              ),
                              onTap: (){

                              },
                            ),
                            color: Colors.transparent
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      shrinkWrap: false,
                      itemExtent: 200,
                      physics: AlwaysScrollableScrollPhysics(),
                      cacheExtent: 122,
                    ),
                    padding: EdgeInsets.all(10),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ItemListDevider(DeviderTitle: "Preferred Pics",
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height:190,
                    child: ListView.builder(
                      itemBuilder: (context, index){
                        return Material(
                            child: GestureDetector(
                              child: Container(
                                margin: EdgeInsets.only(right: 8),
                                child: PreferredPicks(
                                  bottomTitle: "Most Played",
                                  colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                ),
                              ),
                              onTap: (){

                              },
                            ),
                            color: Colors.transparent
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      shrinkWrap: false,
                      itemExtent: 122,
                      physics: AlwaysScrollableScrollPhysics(),
                      cacheExtent: 122,
                    ),
                    padding: EdgeInsets.all(10),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ItemListDevider(DeviderTitle: "Preferred Pics",
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height:150,
                    child: ListView.builder(
                      itemBuilder: (context, index){
                        return Material(
                            child: GestureDetector(
                              child: Container(
                                margin: EdgeInsets.only(right: 8),
                                child: PreferredPicks(
                                  bottomTitle: "Most Played",
                                  colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                ),
                              ),
                              onTap: (){

                              },
                            ),
                            color: Colors.transparent
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      shrinkWrap: false,
                      itemExtent: 200,
                      physics: AlwaysScrollableScrollPhysics(),
                      cacheExtent: 122,
                    ),
                    padding: EdgeInsets.all(10),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ItemListDevider(DeviderTitle: "Preferred Pics",
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height:190,
                    child: ListView.builder(
                      itemBuilder: (context, index){
                        return Material(
                            child: GestureDetector(
                              child: Container(
                                margin: EdgeInsets.only(right: 8),
                                child: PreferredPicks(
                                  bottomTitle: "Most Played",
                                  colors: [MyTheme.bgBottomBar.value, MyTheme.darkBlack.value],
                                ),
                              ),
                              onTap: (){

                              },
                            ),
                            color: Colors.transparent
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      shrinkWrap: false,
                      itemExtent: 122,
                      physics: AlwaysScrollableScrollPhysics(),
                      cacheExtent: 122,
                    ),
                    padding: EdgeInsets.all(10),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
