// lib/ui/widgets/advanced_card_swiper_controller.dart
import 'package:flutter/material.dart';

enum SwipingDirection { left, right }

class AdvancedCardSwiperController extends ChangeNotifier {
  SwipingDirection? _swipingDirection;
  SwipingDirection? get swipingDirection => _swipingDirection;

  void swipeLeft() {
    _swipingDirection = SwipingDirection.left;
    notifyListeners();
  }

  void swipeRight() {
    _swipingDirection = SwipingDirection.right;
    notifyListeners();
  }
}
