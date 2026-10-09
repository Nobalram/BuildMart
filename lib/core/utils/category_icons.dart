import 'package:flutter/material.dart';

/// Maps a category's stored `icon` key to a Material icon.
/// Keeps icon logic in one place instead of scattering switch
/// statements across widgets.
IconData categoryIconFor(String key) {
  switch (key) {
    case 'sand':
    case 'msand':
    case 'psand':
      return Icons.landscape_outlined;
    case 'bricks':
    case 'blocks':
      return Icons.view_module_outlined;
    case 'cement':
      return Icons.inventory_2_outlined;
    case 'stone':
    case 'bluemetal':
    case 'gravel':
    case 'jelly':
      return Icons.terrain_outlined;
    case 'steel':
    case 'tmtbars':
      return Icons.construction_outlined;
    case 'pipes':
      return Icons.plumbing_outlined;
    case 'tiles':
      return Icons.grid_view_outlined;
    default:
      return Icons.category_outlined;
  }
}
