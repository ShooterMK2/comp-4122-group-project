Quadlet v1.0 - pixel font
by fcidade

Thanks for downloading! License: see LICENSE.txt (commercial use allowed).


FILES

  Quadlet.ttf
      TrueType font. Crisp at 11px and its multiples (11, 22, 33...).

  Quadlet.fnt
      BMFont (text format), uses Quadlet.png. Works in Godot, Phaser, LOVE,
      MonoGame, libGDX, Defold and others.

  Quadlet.png
      Spritesheet: white glyphs on transparent background, 16 per row,
      8x11px cells. Tint it any color in your engine.

  Quadlet-chars.txt
      The characters in the spritesheet, in order.


CHARACTER SET

  196 glyphs: ASCII, Latin-1 and the euro sign. Covers English, Portuguese, Spanish, French, German, Italian and most Western European languages.


QUICK START

  Godot 4
    BMFont: put Quadlet.fnt and Quadlet.png in the same folder of your project
    (the .fnt needs the .png next to it) and use the .fnt as the font of
    a Label.
    TTF: in the .ttf import settings set Antialiasing to None and
    Subpixel Positioning to Disabled, then use font size 11 or a multiple.

  Unity
    Import Quadlet.ttf and use a font size that is a multiple of 11. Set the
    font texture filter to Point (no filter) to keep the pixels sharp.

  GameMaker
    Import Quadlet.png as a sprite strip (196 frames, 16 per row,
    8x11 each), then create the font with font_add_sprite_ext(),
    passing the contents of Quadlet-chars.txt as the string map.

  Anything else
    Use the .ttf at 11px or a multiple, with antialiasing / smoothing off.
