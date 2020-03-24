import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:Tunein/services/pageService.dart';

class LayoutService {
  // Main PageView
  PageController _globalPageController;
  PageController get globalPageController => _globalPageController;

  // Sub PageViews
  List<PageService> _pageServices;
  List<PageService> get pageServices => _pageServices;

  // Main Panel
  PanelController _globalPanelController;
  PanelController get globalPanelController => _globalPanelController;
  PageController _albumPlayerPageController;
  PageController get albumPlayerPageController => _albumPlayerPageController;
  PageController _albumListPageController;
  PageController get albumListPageController => _albumListPageController;

  // global keys
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;

  LayoutService() {
    _initGlobalPageView();
    _initSubPageViews();
    _initGlobalPanel();
    _initPlayingPageView();
    _initAlbumListPageView();
  }

  void _initSubPageViews() {
    _pageServices = List<PageService>(3);
    for (var i = 0; i < _pageServices.length; i++) {
      _pageServices[i] = PageService(i);
    }
  }

  void _initGlobalPanel() {
    _globalPanelController = PanelController();
  }

  void _initGlobalPageView() {
    _globalPageController = PageController();
  }

  void _initPlayingPageView() {
    _albumPlayerPageController = PageController(
      initialPage: 1,
      keepPage: true
    );
  }

  void _initAlbumListPageView() {
    _albumListPageController = PageController();
  }

  void changeGlobalPage(int pageIndex) {
    Curve curve = Curves.fastOutSlowIn;
    _globalPageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 200),
      curve: curve,
    );
  }
}
