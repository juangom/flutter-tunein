



import 'dart:math';

class MathUtils{

  static int getRandomFromRange(int min, int max){
    Random rnd;
    rnd = new Random();
    return min + rnd.nextInt(max - min);
  }

}