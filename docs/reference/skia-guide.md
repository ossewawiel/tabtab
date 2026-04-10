# Skia Quick Reference

> Stub — to be filled in alongside BLD-003 (first Skia-backed widget).

[Skia](https://skia.org/) is the 2D graphics library TabTab uses for all
builder rendering. It's the same library used by Chrome, Flutter, and Android,
licensed under BSD.

## Official docs
- [Skia docs home](https://skia.org/docs/)
- [C++ API reference](https://api.skia.org/)

## Key types TabTab uses
- `SkCanvas` — the drawing surface passed into every render call
- `SkPaint` — stroke/fill properties (colour, width, style, shader, filter)
- `SkPath` — vector paths
- `SkParagraph` — text layout
- `SkShader` — gradients and image fills
- `SkFont` / `SkTypeface` — font handling

## TabTab-specific patterns
_(to be documented as the builder takes shape)_
