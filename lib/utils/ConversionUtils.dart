


class ConversionUtils{

  static String DurationToFancyText(Duration duration, {showHours=true, showMinutes=true, showSeconds=true}){
    assert(duration!=null, "duration argument can't be null");
    String finalText ="";
    if(showHours && duration.inHours!=0){
      finalText+="${duration.inHours} hours";
    }
    if(showMinutes && duration.inMinutes.remainder(60)!=0){
      finalText+="${duration.inMinutes.remainder(60)} min ";
    }
    if(showSeconds && duration.inSeconds.remainder(60)!=0){
      finalText+="${duration.inSeconds.remainder(60)} sec";
    }

    return finalText;
  }
}