import 'dart:math';

int lessFirst(int? first, int current) {
  if (first == null) {
    return current;
  } else {
    return min(first, current);
  }
}

int greaterLast(int? last, int current) {
  if (last == null) {
    return current;
  } else {
    return max(last, current);
  }
}
