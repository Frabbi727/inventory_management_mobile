import 'package:flutter/widgets.dart';

class OrderFlowStep {
  const OrderFlowStep({
    required this.index,
    required this.title,
    required this.builder,
  });

  final int index;
  final String title;
  final WidgetBuilder builder;
}
