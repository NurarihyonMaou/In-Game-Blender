#ifndef NURAUI_MODULE_API_HLSLI
#define NURAUI_MODULE_API_HLSLI

// Shared constants and visual primitives for every NuraUI module.
// Registry layout: 32 modules x 8 widgets/module x 8 floats/widget.
// Widget descriptor: type, x1, y1, x2, y2, value, minValue, maxValue.
// Types: 1 slider, 2 toggle, 3 action counter, 4 cycle selector, 5 momentary pulse button.
static const uint NURAUI_MODULE_CAPACITY = 32u;
static const uint NURAUI_WIDGETS_PER_MODULE = 8u;
static const uint NURAUI_WIDGET_STRIDE = 8u;
static const uint NURAUI_WIDGET_SLIDER = 1u;
static const uint NURAUI_WIDGET_TOGGLE = 2u;
static const uint NURAUI_WIDGET_ACTION = 3u;
static const uint NURAUI_WIDGET_CYCLE = 4u;
static const uint NURAUI_WIDGET_PULSE_BUTTON = 5u;

#define NURAUI_MODULE_WIDGET_BASE(MODULE_SLOT, WIDGET_INDEX) (((MODULE_SLOT) * NURAUI_WIDGETS_PER_MODULE + (WIDGET_INDEX)) * NURAUI_WIDGET_STRIDE)
#define NURAUI_MODULE_WIDGET_VALUE(WIDGET_BUFFER, MODULE_SLOT, WIDGET_INDEX) WIDGET_BUFFER[NURAUI_MODULE_WIDGET_BASE((MODULE_SLOT), (WIDGET_INDEX)) + 5u]
// p / center / halfSize are normalized screen coordinates (0..1).
// Generic module widgets are declared by the module's INI:
//   type 1 = slider; value changes continuously while dragging
//   type 2 = toggle; value flips between 0 and 1 on click
//   type 3 = action; value is a persistent click counter (wraps at maxValue)
//   type 4 = cycle; integer value advances through minValue..maxValue on click
//   type 5 = momentary pulse button; value is 1 on the click frame, then Core resets it to 0
// Each module gets 8 widget slots. Descriptor stride is 8 floats:
//   type, x1, y1, x2, y2, value, minValue, maxValue.
// Widget bounds are normalized top-left / bottom-right screen coordinates.
// Labels and project-specific actions remain module-owned; Core only draws/hit-tests controls.
// KeyBind tab contribution is separate from widget registration: each module can
// publish 0..4 rows. NuraUIModuleKeybindRegister.hlsl assigns compact global row
// positions, so modules without KeyBinds do not create gaps in the Core list.
// Keep each module's visible text resource paired with an actual [Key...] binding.
// Settings tab contribution is separate: up to two rows per module, with types
// 1 = toggle (0..1) and 2 = slider (min..max). NuraUIModuleSettingRegister.hlsl
// allocates a compact global row and writes its index to a module-owned two-entry
// slot buffer (64 is the invalid-row sentinel). NuraUIModuleSettingRead.hlsl
// copies the current descriptor values into a module-owned two-entry value buffer.
// Row labels and persistence variables remain module-owned; Settings controls are
// rendered and hit-tested by Core. The global registry supports 64 contributed rows.

float NuraUI_ModuleRoundRect(float2 p, float2 center, float2 halfSize, float radius)
{
    float2 q = abs(p - center) - halfSize + radius;
    float distanceToEdge = length(max(q, 0.0f)) + min(max(q.x, q.y), 0.0f) - radius;
    float aa = max(fwidth(distanceToEdge), 0.0005f);
    return 1.0f - smoothstep(-aa, aa, distanceToEdge);
}

float NuraUI_ModuleBox(float2 p, float2 topLeft, float2 bottomRight)
{
    float2 inside = step(topLeft, p) * step(p, bottomRight);
    return inside.x * inside.y;
}

float4 NuraUI_ModuleOverlay(float4 destination, float4 source, float mask)
{
    return lerp(destination, source, saturate(mask));
}

#endif // NURAUI_MODULE_API_HLSLI
