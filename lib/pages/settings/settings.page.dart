import 'package:Tunein/components/pagenavheader.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/services/layout.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/settingService.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatelessWidget {

  final SettingService = locator<settingService>();
  final layoutService = locator<LayoutService>();



  @override
  Widget build(BuildContext gcontext) {
    return Material(
      color: MyTheme.darkBlack,
      child: Column(
        children: <Widget>[
          PageNavHeader(
            pageIndex: 2,
          ),
          Flexible(
            child: PageView(
              physics: AlwaysScrollableScrollPhysics(),
              controller: layoutService.pageServices[2].pageViewController,
              children: <Widget>[
                StreamBuilder(
                  stream: SettingService.settings$,
                  builder: (BuildContext context,
                      AsyncSnapshot<Map<SettingsIds,String>> snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }
                    final _settings = snapshot.data;
                    return Container(
                      child: SettingsList(
                        backgroundColor: MyTheme.darkBlack,
                        textColor: MyTheme.grey300,
                        headingTextColor: MyTheme.darkRed,
                        sections: [
                          SettingsSection(
                            title: 'Region Settings',
                            tiles: [
                              SettingsTile(
                                title: 'Language',
                                subtitle: _settings[SettingsIds.SET_LANG],
                                leading: Icon(
                                  Icons.language,
                                  color: MyTheme.grey300,
                                ),
                                onTap: () {
                                  changeSystemLanguage(gcontext, _settings[SettingsIds.SET_LANG]);
                                },
                              ),

                            ],
                          ),
                          SettingsSection(
                            title: 'Aritsts',
                            tiles: [
                              SettingsTile.switchTile(
                                title: 'Update Artist thumbnails',
                                subtitle: 'Automatically update artist thumbnails via the internet',
                                leading: Icon(
                                    Icons.update,
                                    color: MyTheme.grey300
                                ),
                                switchValue: true,
                                onToggle: (bool value) {
                                  print("got the value : ${value}");
                                },
                              ),

                            ],
                          ),
                        ],
                      ),
                    );

                  },
                ),
                Center(
                  child: Container(
                    child: Text(
                      "SERVERS SETTINGS",
                      style: TextStyle(
                        fontSize: 40,
                        color: MyTheme.grey300,
                        fontWeight: FontWeight.w700
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );

  }


  changeSystemLanguage(context, String current)async{
    String Language = await openLanguageSelectDialog(context, current);
    SettingService.updateSingleSetting(SettingsIds.SET_LANG, Language);
  }


  Future<String> openLanguageSelectDialog(context, String current){

    void changeLanguage(String language) {
      Navigator.of(context, rootNavigator: true).pop(language);
    }

    bool isSelectedLanguage(String lang){
      return current==lang;
    }

    List<dynamic> languages = [
      "English",
      "Spanish",
      "Chinese",
      "German"
    ];

    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: MyTheme.darkBlack,
            title: Text(
              "Select language",
              style: TextStyle(
                  color: Colors.white70
              ),
            ),
            content: Material(
              child: Container(
                height: MediaQuery.of(context).size.height/2.5,
                width: MediaQuery.of(context).size.width/1.2,
                child: SettingsList(
                  textColor: MyTheme.grey300,
                  sections: [
                    SettingsSection(
                      title: "Chose the language to use",
                        tiles: languages.map((lang){
                          return SettingsTile(
                            trailing: isSelectedLanguage(lang)?Icon(Icons.check, color: MyTheme.grey300):Icon(null),
                            title: lang,
                            onTap: () {
                              changeLanguage(lang);
                            },
                          );
                        }).toList().cast<SettingsTile>()
                    ),
                  ],
                ),
              ),
              color:Colors.transparent
            ),
            actions: <Widget>[
              FlatButton(
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                        color: MyTheme.darkRed
                    ),
                  ),
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(null))
            ],
          );
        });
  }
}

