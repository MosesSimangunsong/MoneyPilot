import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(color: Color(0x0D102A43), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> raised = <BoxShadow>[
    BoxShadow(color: Color(0x14102A43), blurRadius: 16, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> overlay = <BoxShadow>[
    BoxShadow(color: Color(0x1F102A43), blurRadius: 24, offset: Offset(0, 12)),
  ];
}
