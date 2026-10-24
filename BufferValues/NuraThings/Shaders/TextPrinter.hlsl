Buffer<uint> text : register(t113);

struct TextParameters {
	float4 rect;
	float4 colour;
	float4 background;
	float2 border;
	float h_anchor;
	float v_anchor;
	float h_align;
	float font_scale;
};
StructuredBuffer<TextParameters> params : register(t114);

static float2 cur_pos;
// static float4 resolution;
#define resolution IniParams[0].xy

// Default return of effective_dpi is 96 for 100% or undetected scaling
// Since Windows defaults to 125% scaling at 1080p, lets use 96*1.25=120 as actual basis
// So anything beyond 120 should be scaled up
#define ScreenScaling (IniParams[0].w > 120 ? IniParams[0].w / 120 : 1)
#define packedHSV IniParams[100].x
#define packedHSL IniParams[100].y
#define packedRGB IniParams[100].z
#define useWhichPacked IniParams[100].w
#define TINT_STRENGTH IniParams[101].x
#define SPECIAL_EFFECT IniParams[136].z

float3 RGBtoHSL(float3 rgb)
{
    float r = rgb.r;
    float g = rgb.g;
    float b = rgb.b;

    float maxC = max(r, max(g, b));
    float minC = min(r, min(g, b));
    float delta = maxC - minC;

    float h = 0.0;
    float s = 0.0;
    float l = (maxC + minC) / 2.0;

    if (delta > 0.0)
    {
        // Saturation
        s = delta / (1.0 - abs(2.0 * l - 1.0));

        // Hue
        if (maxC == r)
            h = (g - b) / delta;
        else if (maxC == g)
            h = (b - r) / delta + 2.0;
        else
            h = (r - g) / delta + 4.0;

        h /= 6.0;
        if (h < 0.0) h += 1.0;
    }

    return float3(h, s, l);
}

float3 HSVtoRGB(float H, float S, float V)
{
    float C = V * S;
    float X = C * (1 - abs(fmod(H / 60.0, 2) - 1));
    float m = V - C;
    float3 color = float3(0, 0, 0);

    if (H < 60)       color = float3(C, X, 0);
    else if (H < 120) color = float3(X, C, 0);
    else if (H < 180) color = float3(0, C, X);
    else if (H < 240) color = float3(0, X, C);
    else if (H < 300) color = float3(X, 0, C);
    else              color = float3(C, 0, X);

    return color + m;
}

float3 HSLtoRGB(float3 hsl)
{
    float H = hsl.x;
    float S = hsl.y;
    float L = hsl.z;

    float C = (1 - abs(2 * L - 1)) * S;
    float Hprime = H * 6.0;
    float X = C * (1 - abs(fmod(Hprime, 2.0) - 1.0));

    float3 rgb1;
    if (Hprime < 1) rgb1 = float3(C, X, 0);
    else if (Hprime < 2) rgb1 = float3(X, C, 0);
    else if (Hprime < 3) rgb1 = float3(0, C, X);
    else if (Hprime < 4) rgb1 = float3(0, X, C);
    else if (Hprime < 5) rgb1 = float3(X, 0, C);
    else rgb1 = float3(C, 0, X);

    float m = L - 0.5 * C;
    return rgb1 + m;
}

float3 UnpackHSL(float packed)
{
    uint data = asuint(packed);

    uint H = (data >> 16) & 0xFFFF;
    uint S = (data >> 8) & 0xFF;
    uint L = data & 0xFF;

    float3 hsl;
    hsl.x = (float)H / 65535.0;
    hsl.y = (float)S / 255.0;
    hsl.z = (float)L / 255.0;

    return hsl;
}


float3 UnpackRGB(float packed)
{
    uint data = asuint(packed);

    uint R = (data >> 20) & 0x3FF;
    uint G = (data >> 10) & 0x3FF;
    uint B = data & 0x3FF;

    float3 rgb;
    rgb.r = (float)R / 1023.0;
    rgb.g = (float)G / 1023.0;
    rgb.b = (float)B / 1023.0;

    return rgb;
}

float3 UnpackHSV(float packed)
{
    uint data = asuint(packed);

    uint H = (data >> 16) & 0xFFFF;
    uint S = (data >> 8) & 0xFF;
    uint V = data & 0xFF;

    float3 hsv;
    hsv.x = (float)H / 65535.0 * 360.0;
    hsv.y = (float)S / 255.0;
    hsv.z = (float)V / 255.0;

    return hsv;
}

float3 RGBtoHSV(float3 c)
{
    float R = c.r;
    float G = c.g;
    float B = c.b;

    float maxC = max(R, max(G, B));
    float minC = min(R, min(G, B));
    float delta = maxC - minC;

    float H = 0.0;
    if (delta > 0.00001)
    {
        if (maxC == R)
            H = 60.0 * fmod(((G - B) / delta), 6.0);
        else if (maxC == G)
            H = 60.0 * (((B - R) / delta) + 2.0);
        else if (maxC == B)
            H = 60.0 * (((R - G) / delta) + 4.0);
    }

    if (H < 0.0)
        H += 360.0;

    float S = (maxC <= 0.0) ? 0.0 : delta / maxC;
    float V = maxC;

    return float3(H, S, V);
}

float3 HSVtoHSL(float3 hsv)
{
    float H = hsv.x;
    float S_HSV = hsv.y;
    float V = hsv.z;

    float L = V * (1.0 - S_HSV * 0.5);

    float S_HSL;
    if (L == 0.0 || L == 1.0)
    {
        S_HSL = 0.0;
    }
    else
    {
        S_HSL = (V - L) / min(L, 1.0 - L);
    }

    return float3(H, S_HSL, L);
}


static float2 char_size;
static int2 meta_pos_start;

// Must be set high enough to counter floating point error in the perspective
// divide. Should be set to at least the font texture width * font_scale.
#define TEXCOORD2_BIAS 4096 /* * font_scale */

// dictated by 1024 / sizeof(gs2ps) / 4
#define CHARS_PER_INVOCATION 64

Texture2D<float> font : register(t100);
Texture1D<float4> IniParams : register(t120);
Texture2D<float4> StereoParams : register(t125);

struct vs2gs {
	uint idx : TEXCOORD0;
};

struct gs2ps {
	float4 pos : SV_Position0;
};

struct cs2gs {
	uint start;
	uint len;
	float2 pos;
};

float2 get_char_dimensions(uint c)
{
	float2 meta_pos;
	float2 dim;

	meta_pos.x = meta_pos_start.x + (c % 16);
	meta_pos.y = meta_pos_start.y + (c / 16 - 2) * 2;

	dim.x = font.Load(int3(meta_pos, 0)) * 255;
	meta_pos.y++;
	dim.y = font.Load(int3(meta_pos, 0)) * 255;

	return dim;
}

#ifdef COMPUTE_SHADER
void get_meta()
{
	// No good in windowed mode:
	//resolution = StereoParams.Load(int3(2, 0, 0));

	// Can't use GetDimensions in a compute shader - it crashes
	// font.GetDimensions(font_width, font_height);

	float font_width = 256, font_height = 96;
	char_size = float2(font_width, font_height) / float2(16, 6);

	meta_pos_start = float2(15 * char_size.x, 5 * char_size.y);
}

RWStructuredBuffer<cs2gs> textpos : register(u0);

[numthreads(1, 1, 1)]
void main()
{
	get_meta();
	float2 char_dim = char_size.xy / resolution.xy * 2 * params[0].font_scale * ScreenScaling;
	uint pos;
	uint c;
	uint gs = 1;
	uint gs_linestart = 1;
	uint start = 0;
	uint space = -1;
	float space_x = 0;
	float max_x = -1;
	float rect_width = params[0].rect.z - params[0].rect.x;

	cur_pos = 0;
	textpos[gs].start = 0;
	textpos[gs].pos = cur_pos;

	// Can't use GetDimensions in a compute shader - it crashes
	//buf.GetDimensions(strlen);

	// FIXME: Refactor

	for (pos = 0; c = text[pos]; pos++) {
		if (c == ' ') {
			space = pos;
			space_x = cur_pos.x;
		}

		cur_pos.x += get_char_dimensions(c).x / resolution.x * 2 * params[0].font_scale * ScreenScaling;

		// FIXME: Refactor

		if (c == '\n') {
			textpos[gs].len = pos - start + 1;
			max_x = max(max_x, cur_pos.x);

			if (params[0].h_align == 1) {
				// Center align
				for (uint i = gs_linestart; i <= gs; i++)
					textpos[i].pos.x = (rect_width - cur_pos.x) / 2 + textpos[i].pos.x;
			} else if (params[0].h_align == 2) {
				// Right align
				for (uint i = gs_linestart; i <= gs; i++)
					textpos[i].pos.x = rect_width - cur_pos.x + textpos[i].pos.x;
			}

			gs++;
			gs_linestart = gs;
			start = pos + 1;
			space = -1;
			cur_pos.y -= char_dim.y;
			cur_pos.x = 0;

			textpos[gs].start = start;
			textpos[gs].pos = cur_pos;
			//continue; // XXX: Use of > 1 continue statements triggers a HLSL BUG
		} else if (cur_pos.x >= rect_width) {
			// Long line - wrap text
			if (space != -1) {
				// Wrap at the position of the most recent space
				textpos[gs].len = space - start;
				max_x = max(max_x, space_x);
				start = space + 1;
				pos = space;

				if (params[0].h_align == 1) {
					// Center align
					for (uint i = gs_linestart; i <= gs; i++)
						textpos[i].pos.x = (rect_width - space_x) / 2 + textpos[i].pos.x;
				} else if (params[0].h_align == 2) {
					// Right align
					for (uint i = gs_linestart; i <= gs; i++)
						textpos[i].pos.x = rect_width - space_x + textpos[i].pos.x;
				}

				gs++;
				gs_linestart = gs;
				space = -1;
				cur_pos.y -= char_dim.y;
				cur_pos.x = 0;

				textpos[gs].start = start;
				textpos[gs].pos = cur_pos;
				//continue; // XXX: Use of > 1 continue statements triggers a HLSL BUG
			} else {
				// No space encountered on the line, wrap at this point
				textpos[gs].len = pos - start + 1;
				max_x = max(max_x, cur_pos.x);

				if (params[0].h_align == 1) {
					// Center align
					for (uint i = gs_linestart; i <= gs; i++)
						textpos[i].pos.x = (rect_width - cur_pos.x) / 2 + textpos[i].pos.x;
				} else if (params[0].h_align == 2) {
					// Right align
					for (uint i = gs_linestart; i <= gs; i++)
						textpos[i].pos.x = rect_width - cur_pos.x + textpos[i].pos.x;
				}

				gs++;
				gs_linestart = gs;
				start = pos + 1;
				space = -1;
				cur_pos.y -= char_dim.y;
				cur_pos.x = 0;

				textpos[gs].start = start;
				textpos[gs].pos = cur_pos;
				//continue; // XXX: Use of > 1 continue statements triggers a HLSL BUG
			}
		} else if (pos - start >= CHARS_PER_INVOCATION - 1) {
			// Cut the text every 64 characters for each geometry shader invocation
			textpos[gs].len = pos - start + 1;

			gs++;
			start = pos + 1;

			textpos[gs].start = start;
			textpos[gs].pos = cur_pos;
		}
	}
	textpos[gs].len = pos - start + 1;
	max_x = max(max_x, cur_pos.x);
	if (text[pos-1] != '\n' && text[pos-1] != '\r') {
		cur_pos.y -= char_dim.y;

		if (params[0].h_align == 1) {
			// Center align
			for (uint i = gs_linestart; i <= gs; i++)
				textpos[i].pos.x = (rect_width - cur_pos.x) / 2 + textpos[i].pos.x;
		} else if (params[0].h_align == 2) {
			// Right align
			for (uint i = gs_linestart; i <= gs; i++)
				textpos[i].pos.x = rect_width - cur_pos.x + textpos[i].pos.x;
		}
	}

	// Store the final y position in index 0, which is used to
	// automatically size the background rectangle:
	textpos[0].pos = float2(max_x, cur_pos.y);
}
#endif

void pack_texcoord(inout gs2ps output, float2 texcoord)
{
	// Packs one coordinate of the texcoord into the SV_Position Z to give
	// us room for a few extra characters per geometry shader invocation.
	// Requires 'depth_clip_enable = false' in the d3dx.ini
	output.pos.z = texcoord.x;

	// We can encode the Y texcoord in the SV_Position's W component to
	// maximise the number of characters the geometry shader can produce
	// per invocation. This is a little tricky, since the rasterizer will
	// perform a perspective divide by this value (and "noperspective"
	// doesn't seem to prevent this), so we cannot encode 0 here and must
	// be wary of floating point error that may be introduced by this
	// divide. To counter this problem, we add a fixed bias to the texcoord
	// that will prevent it from being 0 and ensure that floating point
	// error is reduced enough that it will not make a visible difference.
	output.pos.w = texcoord.y + TEXCOORD2_BIAS;
	output.pos.xyz *= output.pos.w;
}

float2 unpack_texcoord(gs2ps input)
{
	return float2(input.pos.z, input.pos.w - TEXCOORD2_BIAS);
}

#ifdef VERTEX_SHADER
void main(uint id : SV_VertexID, out vs2gs output)
{
	output.idx = id;
}
#endif

#ifdef GEOMETRY_SHADER
void get_meta()
{
	float font_width, font_height;

	// No good in windowed mode:
	//resolution = StereoParams.Load(int3(2, 0, 0));

	font.GetDimensions(font_width, font_height);
	char_size = float2(font_width, font_height) / float2(16, 6);

	meta_pos_start = float2(15 * char_size.x, 5 * char_size.y);
}

void emit_char(uint c, inout TriangleStream<gs2ps> ostream)
{
	float2 cdim = get_char_dimensions(c);
	float2 texcoord;

	if (c >= ' ' && c < 0x7f) {
		gs2ps output;
		float2 dim = float2(cdim.x, char_size.y) / resolution.xy * 2 * params[0].font_scale * ScreenScaling;
		float texture_x_percent = cdim.x / char_size.x;

		texcoord.x = (c % 16) * char_size.x;
		texcoord.y = (c / 16 - 2) * char_size.y;

		output.pos = float4(cur_pos.x        , cur_pos.y - dim.y, 0, 1);
		pack_texcoord(output, texcoord + float2(0, 1) * char_size);
		ostream.Append(output);
		output.pos = float4(cur_pos.x + dim.x, cur_pos.y - dim.y, 0, 1);
		pack_texcoord(output, texcoord + float2(texture_x_percent, 1) * char_size);
		ostream.Append(output);
		output.pos = float4(cur_pos.x        , cur_pos.y        , 0, 1);
		pack_texcoord(output, texcoord + float2(0, 0) * char_size);
		ostream.Append(output);
		output.pos = float4(cur_pos.x + dim.x, cur_pos.y        , 0, 1);
		pack_texcoord(output, texcoord + float2(texture_x_percent, 0) * char_size);
		ostream.Append(output);

		ostream.RestartStrip();
	}

	// Increment current position taking specific character width into account:
	cur_pos.x += cdim.x / resolution.x * 2 * params[0].font_scale * ScreenScaling;
}

// Using a macro for this because a function requires us to know the size of the buffer
#define EMIT_CHAR_ARRAY(strlen, buf, ostream) \
{ \
	for (uint i = 0; i < strlen; i++) \
		emit_char(buf[i], ostream); \
} \

void print_string_buffer(Buffer<uint> buf, uint start, uint len, inout TriangleStream<gs2ps> ostream)
{
	uint strlen, i;

	//buf.GetDimensions(strlen);

	for (i = start; i < start + len; i++)
		emit_char(buf[i], ostream);
}

void emit_int(int val, inout TriangleStream<gs2ps> ostream)
{
	int digit;

	if (val < 0.0) {
		emit_char('-', ostream);
		val *= -1;
	}

	int e = 0;
	if (val == 0) {
		emit_char('0', ostream);
		return;
	}
	e = log10(val);
	while (e >= 0) {
		digit = uint(val / pow(10, e)) % 10;
		emit_char(digit + 0x30, ostream);
		e--;
	}
}

// isnan() is optimised out by the compiler, which produces a warning that we
// need the /Gis (IEEE Strictness) option to enable it... but that doesn't work
// either... neither does disabling optimisations... Uhh, good job Microsoft?
// Whatever, just implement it ourselves by testing for an exponent of all 1s
// and a non-zero mantissa:
bool workaround_broken_isnan(float x)
{
	return (((asuint(x) & 0x7f800000) == 0x7f800000) && ((asuint(x) & 0x007fffff) != 0));
}

void emit_float(float val, inout TriangleStream<gs2ps> ostream)
{
	int digit;
	int significant = 0;
	int scientific = 0;

	if (workaround_broken_isnan(val)) {
		emit_char('N', ostream);
		emit_char('a', ostream);
		emit_char('N', ostream);
		return;
	}

	if (val < 0.0) {
		emit_char('-', ostream);
		val *= -1;
	}

	if (isinf(val)) {
		emit_char('i', ostream);
		emit_char('n', ostream);
		emit_char('f', ostream);
		return;
	}

	if (val == 0) {
		emit_char('0', ostream);
		return;
	}

	int e = log10(val);
	if (e < 0) {
		if (e < -4) {
			scientific = --e;
			digit = uint(val / pow(10, e)) % 10;
			emit_char(digit + 0x30, ostream);
			significant++;
			e--;
		} else {
			emit_char('0', ostream);
			e = -1;
		}
	} else {
		if (e > 6)
			scientific = e;
		while (e - scientific >= 0) {
			digit = uint(val / pow(10, e)) % 10;
			emit_char(digit + 0x30, ostream);
			if (digit || significant) // Don't count leading 0 as significant, but do count following 0s
				significant++;
			e--;
		}
	}
	if (!scientific && frac(val / pow(10, e + 1)) == 0)
		return;
	emit_char('.', ostream);
	bool emitted = false;
	while (!emitted || (significant < 3 && frac(val / pow(10, e + 1)))) {
		digit = uint(val / pow(10, e)) % 10;
		emit_char(digit + 0x30, ostream);
		significant++;
		e--;
		emitted = true;
	}

	if (scientific) {
		emit_char('e', ostream);
		emit_int(scientific, ostream);
	}
}

void draw_outline_rectangle(float4 r, inout TriangleStream<gs2ps> ostream)
{
	gs2ps output;

	output.pos = float4(r.x - params[0].border.x, r.y + params[0].border.y, -1, 1);
	ostream.Append(output);
	output.pos = float4(r.z + params[0].border.x, r.y + params[0].border.y, -1, 1);
	ostream.Append(output);
	output.pos = float4(r.x - params[0].border.x, r.w - params[0].border.y, -1, 1);
	ostream.Append(output);
	output.pos = float4(r.z + params[0].border.x, r.w - params[0].border.y, -1, 1);
	ostream.Append(output);

	ostream.RestartStrip();
}


void draw_centered_outline_rectangle(float4 r, inout TriangleStream<gs2ps> ostream)
{
    gs2ps output;

    float2 halfBorder = params[0].border * 0.25;

    // Top left
    output.pos = float4(r.x - halfBorder.x, r.y + halfBorder.y, -1, 1);
    ostream.Append(output);

    // Top right
    output.pos = float4(r.z + halfBorder.x, r.y + halfBorder.y, -1, 1);
    ostream.Append(output);

    // Bottom left
    output.pos = float4(r.x - halfBorder.x, r.w - halfBorder.y, -1, 1);
    ostream.Append(output);

    // Bottom right
    output.pos = float4(r.z + halfBorder.x, r.w - halfBorder.y, -1, 1);
    ostream.Append(output);

    ostream.RestartStrip();
}


StructuredBuffer<cs2gs> textpos : register(t112);

// The max vertex count is dictated by 1024 / sizeof(gs2ps), and the max char count is that / 4
[maxvertexcount(256)]
void main(point vs2gs input[1], inout TriangleStream<gs2ps> ostream)
{
	get_meta();
	uint idx = input[0].idx;
	float2 char_dim = char_size.xy / resolution.xy * 2 * params[0].font_scale * ScreenScaling;
	float4 r = params[0].rect;

	// Anchor the text & rectangle as requested. This will also resize the
	// background to fit around the text
	float2 center = r.xy + float2(r.z - r.x, r.w - r.y) / 2;
	float2 text_shift = 0;

    // ─── Begin scroll patch ─────────────────────────────────────────

	bool AutoReSize = 1;
	bool LimitHeight = 0;
	bool LimitWidth = 0;

	bool CenteredRectangle = 0;
	float CustomParam = IniParams[46].x;
	float CustomParam2 = IniParams[46].y;

	bool UseMinimalWidth = (IniParams[46].z == 69) ? 1 : 0;
	float MinimalWidth = IniParams[46].w;

	bool UseMinimalHeight = (IniParams[46].z == 96) ? 1 : 0;
	float MinimalHeight = IniParams[46].w;

	if (CustomParam > 0){
		AutoReSize = (floor(CustomParam) == 69) ? 0 : 1;
		LimitHeight = (abs(frac(CustomParam) - 0.69) < 0.001) ? 1 : 0;
	}

	if (CustomParam2 > 0){
		CenteredRectangle = (floor(CustomParam2) == 69) ? 1 : 0;
		LimitWidth = (abs(frac(CustomParam2) - 0.69) < 0.001) ? 1 : 0;
	}

    // scroll_norm in IniParams[1].x
    float scrollNorm = clamp(IniParams[49].x, 0.0, 1.0);
    float scrollWNorm = clamp(IniParams[49].y, 0.0, 1.0);
    // total_text_height = -textpos[0].pos.y;
    float totalH = -textpos[0].pos.y;
    float totalW = textpos[0].pos.x;

    // visible box height
    float visibleH = r.y - r.w;
	float visibleW = r.x - r.z;

    // how many pixels we can scroll
    float scrollRange = max(0.0, totalH - visibleH);
    float scrollWRange = max(0.0, totalW - visibleW);
    // final pixel offset
    float scrollOffset = scrollNorm * scrollRange;
    float scrollWOffset = scrollWNorm * scrollWRange;

	if (floor(CustomParam) == 66){
		scrollOffset = 0;
		scrollWOffset = 0;
	}

    // shift the rect itself so the background moves too
    //r.y += scrollOffset;
    //r.w += scrollOffset;
    // ─── End scroll patch ────────────────────────────────────────────

	if (AutoReSize){
		if (!LimitWidth)
		{
			if (params[0].h_anchor == 1) { // Anchor Left
				r.xz = float2(r.x, r.x + textpos[0].pos.x);
				if (params[0].h_align)
					text_shift.x = (r.z - params[0].rect.z);
			} else if (params[0].h_anchor == 2) { // Anchor Center
				r.xz = float2(center.x - textpos[0].pos.x/2, center.x + textpos[0].pos.x/2);
				if (params[0].h_align)
					text_shift.x = (r.z - params[0].rect.z) * 2;
			} else if (params[0].h_anchor == 3) { // Anchor Right
				r.xz = float2(r.z - textpos[0].pos.x, r.z);
				if (params[0].h_align)
					text_shift.x = (params[0].rect.x - r.x);
			}
		}

		if (params[0].h_align == 1)
			text_shift.x /= 2;

		if (!LimitHeight){
			if (params[0].v_anchor == 1) // Anchor Top
				r.yw = float2(r.y, r.y + textpos[0].pos.y);
			else if (params[0].v_anchor == 2) // Anchor center
				r.yw = float2(center.y - textpos[0].pos.y/2, center.y + textpos[0].pos.y/2);
			else if (params[0].v_anchor == 3) // Anchor Bottom
				r.yw = float2(r.w - textpos[0].pos.y, r.w);
		}
	}
	
	if (idx == 0) {
		if (UseMinimalWidth && r.z < MinimalWidth)
			r.z = MinimalWidth;

		if (UseMinimalHeight && r.w < MinimalHeight)
			r.w = MinimalHeight;

		if (CenteredRectangle)
			draw_centered_outline_rectangle(r, ostream);
		else
			draw_outline_rectangle(r, ostream);
	} else {
		cur_pos = r.xy + textpos[idx].pos + text_shift + float2(scrollWOffset, scrollOffset);

		if ((!AutoReSize || LimitHeight || LimitWidth) && (cur_pos.y > r.y+0.01 || cur_pos.y < r.w+0.01))
			return;

		print_string_buffer(text, textpos[idx].start, textpos[idx].len, ostream);
	}
}
#endif

#ifdef PIXEL_SHADER
void main(gs2ps input, out float4 o0 : SV_Target0)
{
	float2 texcoord = unpack_texcoord(input);
	float4 result = params[0].colour;
	float4 background = params[0].background;
	float balpha = background.a;

        if (SPECIAL_EFFECT == 96) {
            float3 hsvTex = RGBtoHSV(result.rgb); // Original texture HSV
			float3 hsvBackground = RGBtoHSV(background.rgb);
            float3 packed = float3(0,0,0);
        
            if (useWhichPacked == 0) {
                // HSV sliders
                packed = UnpackHSV(packedHSV); // Expect H in [0..360], S/V in [0..1]
                
                hsvTex.x = lerp(hsvTex.x, packed.x, TINT_STRENGTH);
                hsvTex.y = lerp(hsvTex.y, packed.y, TINT_STRENGTH);
                hsvTex.z = lerp(hsvTex.z, packed.z, TINT_STRENGTH * 0.1); // small V shift

                result.rgb = HSVtoRGB(hsvTex.x, hsvTex.y, hsvTex.z);

				if (all(background) > 0){
					hsvBackground.x = lerp(hsvBackground.x, packed.x, TINT_STRENGTH);
                	hsvBackground.y = lerp(hsvBackground.y, packed.y, TINT_STRENGTH);
                	hsvBackground.z = lerp(hsvBackground.z, packed.z, TINT_STRENGTH * 0.1); // small V shift

                	background.rgb = HSVtoRGB(hsvBackground.x, hsvBackground.y, hsvBackground.z);
				}
            }
            else if (useWhichPacked == 1) {
                // RGB sliders
                float3 rgbPacked = UnpackRGB(packedRGB);
                float3 hsvPacked = RGBtoHSV(rgbPacked);
        
                hsvTex.x = lerp(hsvTex.x, hsvPacked.x, TINT_STRENGTH);
                hsvTex.y = lerp(hsvTex.y, hsvPacked.y, TINT_STRENGTH);
                hsvTex.z = lerp(hsvTex.z, hsvPacked.z, TINT_STRENGTH * 0.1);

                result.rgb = HSVtoRGB(hsvTex.x, hsvTex.y, hsvTex.z);

				if (all(background) > 0){
					hsvBackground.x = lerp(hsvBackground.x, hsvPacked.x, TINT_STRENGTH);
                	hsvBackground.y = lerp(hsvBackground.y, hsvPacked.y, TINT_STRENGTH);
                	hsvBackground.z = lerp(hsvBackground.z, hsvPacked.z, TINT_STRENGTH * 0.1);

                	background.rgb = HSVtoRGB(hsvBackground.x, hsvBackground.y, hsvBackground.z);
				}
            }
            else if (useWhichPacked == 2) {
                float3 hsl = UnpackHSL(packedHSL);

                // Step 1: Convert RGB input to HSL
                float3 texHSL = RGBtoHSL(result.rgb);

                // Blend between original lightness and tint lightness
                float blendLightness = lerp(texHSL.z, hsl.z, TINT_STRENGTH);

                // Step 2: Blend hue and saturation, but keep the lightness from the original pixel
                float3 targetHSL = float3(hsl.x*360, hsl.y, blendLightness); // preserve lightness

                
                //float3 blendedHSL = lerp(texHSL, targetHSL, 0.5);

                result.rgb = HSLtoRGB(float3(targetHSL.x, targetHSL.y, targetHSL.z));


				if (all(background) > 0){
				                // Step 1: Convert RGB input to HSL
                	float3 backgroundHSL = RGBtoHSL(background.rgb);

                	// Blend between original lightness and tint lightness
                	float blendBackgroundLightness = lerp(backgroundHSL.z, hsl.z, TINT_STRENGTH);

                	// Step 2: Blend hue and saturation, but keep the lightness from the original pixel
                	float3 targeBackgroundHSL = float3(hsl.x*360, hsl.y, blendBackgroundLightness); // preserve lightness

	
                	//float3 blendedHSL = lerp(texHSL, targetHSL, 0.5);

                	background.rgb = HSLtoRGB(float3(targeBackgroundHSL.x, targeBackgroundHSL.y, targeBackgroundHSL.z));
				}
            }
        }


	if (texcoord.x == -1)
		o0 = background;
	else
		o0.xyzw = font.Load(int3(texcoord, 0)) * result;
}
#endif