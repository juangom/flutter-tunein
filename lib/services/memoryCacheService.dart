



class MemoryCacheService{


  Map<String, dynamic> primaryCache;


  MemoryCacheService(){
    init();
  }

  dynamic setCacheItem(String id, dynamic value){
    primaryCache[id] = value;
  }

  dynamic getCacheItem(String id){
    return primaryCache[id];
  }

  bool isItemCached(String id){
    return primaryCache.containsKey(id);
  }




  init(){
    primaryCache= new Map();
  }
}