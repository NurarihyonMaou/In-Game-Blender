#!/usr/bin/env python3
"""Convert msdf-atlas-gen JSON metadata to the R32G32B32A32_FLOAT raw buffer used by TextPrinterMSDF.hlsl.

Usage:
  python build_msdf_metrics.py NuraThingsFont_MSDF.json NuraThingsFont_MSDFMetrics.buf

The output contains 386 float4 records (386 float4 records; each record is 16 bytes):
  [0] atlasWidth, atlasHeight, distanceRange, lineHeight
  [1] ascender, descender, emSize, fontSize
  [2 + code*3 + 0] advance, planeLeft, planeBottom, planeRight
  [2 + code*3 + 1] planeTop, atlasLeft, atlasTop, atlasRight
  [2 + code*3 + 2] atlasBottom, 0, 0, 0
Coordinates are normalized to a top-origin atlas. Glyphs with no bitmap bounds (e.g. space) keep advance but have empty plane/atlas bounds.
"""
import argparse
import json
import math
import struct
from pathlib import Path


def number(value, default=0.0):
    try:
        out = float(value)
        return out if math.isfinite(out) else default
    except (TypeError, ValueError):
        return default


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('json_path', type=Path)
    parser.add_argument('output_path', type=Path)
    args = parser.parse_args()

    data = json.loads(args.json_path.read_text(encoding='utf-8'))
    atlas = data.get('atlas', {})
    metrics = data.get('metrics', {})
    width = number(atlas.get('width'))
    height = number(atlas.get('height'))
    distance_range = number(atlas.get('distanceRange'), 4.0)
    line_height = number(metrics.get('lineHeight'), 1.0)
    ascender = number(metrics.get('ascender'), 0.8)
    descender = number(metrics.get('descender'), -0.2)
    em_size = number(metrics.get('emSize'), 1.0)
    font_size = number(atlas.get('size'), 48.0)
    y_origin = str(atlas.get('yOrigin', 'bottom')).lower()

    if width <= 0 or height <= 0:
        raise SystemExit('Invalid atlas width/height in JSON.')
    if distance_range <= 0:
        raise SystemExit('Invalid atlas.distanceRange in JSON.')

    records = []
    records.append((width, height, distance_range, line_height))
    records.append((ascender, descender, em_size, font_size))

    glyphs = {}
    for glyph in data.get('glyphs', []):
        code = glyph.get('unicode')
        if code is not None:
            try:
                code = int(code)
            except (TypeError, ValueError):
                continue
            if 0 <= code <= 127:
                glyphs[code] = glyph

    # The shader preserves ASCII-only behavior, matching the original TextPrinter.
    for code in range(128):
        glyph = glyphs.get(code, {})
        advance = number(glyph.get('advance'))
        plane = glyph.get('planeBounds') or {}
        atlas_bounds = glyph.get('atlasBounds') or {}

        left = number(plane.get('left'))
        right = number(plane.get('right'))
        top_value = number(plane.get('top'))
        bottom_value = number(plane.get('bottom'))

        # TextPrinterMSDF.hlsl builds glyph quads in the conventional Y-up
        # plane space (bottom < top). msdf-atlas-gen's -yorigin top also flips
        # the plane-space Y axis, so invert those two coordinates back to Y-up.
        # Atlas pixel coordinates are normalized separately below.
        if y_origin == 'top':
            bottom = -bottom_value
            top = -top_value
        else:
            bottom = bottom_value
            top = top_value

        atlas_left = number(atlas_bounds.get('left'))
        if y_origin == 'top':
            atlas_top = number(atlas_bounds.get('top'))
            atlas_bottom = number(atlas_bounds.get('bottom'))
        else:
            # Convert bottom-origin coordinates to top-origin pixel coordinates.
            atlas_top = height - number(atlas_bounds.get('top'))
            atlas_bottom = height - number(atlas_bounds.get('bottom'))
        atlas_right = number(atlas_bounds.get('right'))

        # Atlas bounds can be omitted for glyphs that have advance but no ink (space).
        if not atlas_bounds or right <= left or top <= bottom:
            left = bottom = right = top = 0.0
            atlas_left = atlas_top = atlas_right = atlas_bottom = 0.0

        records.append((advance, left, bottom, right))
        records.append((top, atlas_left, atlas_top, atlas_right))
        records.append((atlas_bottom, 0.0, 0.0, 0.0))

    args.output_path.parent.mkdir(parents=True, exist_ok=True)
    with args.output_path.open('wb') as stream:
        for record in records:
            stream.write(struct.pack('<4f', *record))

    print(f'Wrote {args.output_path} ({len(records)} float4 records, {len(records) * 16} bytes)')
    print(f'Atlas: {width:g} x {height:g}; distanceRange={distance_range:g}; lineHeight={line_height:g}; ascender={ascender:g}')
    missing = [c for c in range(32, 127) if c not in glyphs]
    if missing:
        print('WARNING: missing ASCII glyphs: ' + ', '.join(f'U+{c:04X}' for c in missing))


if __name__ == '__main__':
    main()
