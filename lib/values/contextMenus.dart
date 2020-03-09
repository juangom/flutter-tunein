import 'package:Tunein/models/ContextMenuOption.dart';
import 'package:flutter/material.dart';


final songCardContextMenulist=[
  ContextMenuOptions(
    id: 1,
    title: "Play one",
    icon: Icons.play_circle_outline,
  ),
  ContextMenuOptions(
    id: 2,
    title: "Stat with and shuffle queue",
    icon: Icons.shuffle,
  ),
  ContextMenuOptions(
    id: 3,
    title: "Stat with and shuffle album",
    icon: Icons.shuffle,
  ),
];

final artistCardContextMenulist=[
  ContextMenuOptions(
    id: 1,
    title: "Play All",
    icon: Icons.play_circle_outline,
  ),
  ContextMenuOptions(
    id: 2,
    title: "Shuffle",
    icon: Icons.shuffle,
  ),
];