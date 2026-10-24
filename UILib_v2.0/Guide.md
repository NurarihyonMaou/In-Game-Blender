# UI Transform Data Library Guide by Unicornshell

<!-- IF YOU CAN READ THIS, PLEASE VIEW AS MARKDOWN! -->

# Overview

This library gives modders access to the relative scaling and padding of the in-game user interface in GI.\
It provides a resource that can be passed to shaders to allow for 100% consistent UI layouts.

# Mod Setup

The library's namespace is "`UI`". The transform data resource can be accessed with `Resource\UI\UIParams`.
You'll need to set up your custom shader to pass this resource from the `.ini` file.

## Ini Setup

To gain access to the UI scaling and padding, you'll need a custom shader within your `.ini` file. It can be any type of shader.

For the purpose of this example, I will be using a vertex shader.\
Here's a pretty typical setup, with the added resource:

```ini
[CustomShader->VertexShaderExample]
vs = .\path_to_shader_file.hlsl
vs-t0 = Resource\UI\UIParams
handling = skip
draw = from_caller
```

###### (I'm using slot 0 here, but you can use any of them)

## HLSL Setup

Now, time for the fun part. Inside your .hlsl custom shader, you'll simply want to register the resource in the matching slot. You need to register it as a `Buffer` of `float2`, like this:

```cpp
// UI Library declaration
Buffer<float2> UIParams : register(t0);
```

###### (Remember to use the matching slot)

Now, you can access the UI transform data inside your shader.
The **scale is index `0`**, and **padding is index `1`**.\
You can use variables if you wish, like this:

```cpp
void main(
  float4 position : POSITION,
  out float4 svpos : SV_POSITION)
{
  //...
  float2 scale = UIParams[0];
  float2 padding = UIParams[1];
  //...
  return;
}
```

# Technical details

Here's some needed details on how the library works, and how to use it properly.

### Format

The `ResourceUIParams` buffer is an array of 2 float2 values. The first represents normalized scale, and the second represents the screenspace padding. Keep in mind that the given\
value represents the distance between the screen edge and the Paimon icon location.\
Also, the scaling floats are accurate up to about `±0.000001`.

### Scale & Padding

The scaling value represents the x and y scale relative to a typical display.\
If you're using a 2560x1440 27" monitor, for example, you'll most likely see a scale of `(1,1)` or `(0.999999,0.999999)`.
In any case, you'll want to multiply any position offset with this scaling, so it works for any screen.

You should also consider the padding when writing offsets or thresholds. The padding value represents the **screenspace** distance between the screen corner and the top left of the Paimon icon.

###### "Screenspace" is a screen coordinate from -1 to +1, where 0 is the center. It'll be the output SV_POSITION.xy in a vertex shader.

This means that if you were ti capture the top-left position of an element at the bottom center (like the health bar), it would look similar to this:

```cpp
//                               |half-width| |width scale|  |height padding|   |height|  |height scale|
float2 top_left_position = float2(   0.2   * -UIParams[0].x, -1 + UIParams[1].y + 0.01 * UIParams[0].y);
```

The entire UI scales evenly, so this will always work.

### Updating scale

The UI transform data auto-updates every frame, as long as the minimap's border is visible and not currently fading in or out.
- There is a 0.3s delay for the $calibrated variable, which should give you a good idea of when the resource is actually giving correct values.
- The $calibrated variable is **not updated** when input method changes (Controller <-> Keyboard).
  You can manually re-calibrate without reloading mods by running this command:
  ```ini
  run = CommandList\UI\Recalibrate
  ```
  Note that as of `v2.0`, this basically does nothing!\
  Setting `$\UI\Calibrated = 0` instead will not show the warning notification!
- The mod will not be able to calibrate until the minimap border is visible on screen. You can check the value of `$\UI\Calibrated` to know if the calibration is still on standby, if necessary.

## How does it actually work?

If you're a curious modder, here's how this mod actually works.

1. First, the mod overrides the texture for the minimap border. It's basically always on screen, and easy to target even if updates might change the hash.
2. Then, a compute shader is run for all 4 of the vertex positions (the four corners), saving the x and y positions to a resource in the process.
3. If the color attributes are correct (meaning the minimap border is not in a fade-in/fade-out animation), proceeds to the next step.
4. Finally, when computing the last vertex position, the compute shader uses the saved positions to compute the padding and scale, and writes those to the `UIParams` resource.
An arbitray "reference" size (`0.225` by `0.400`) is used to determine the UI scale relative to standard 16:9.

You might have noticed that the compute shader applies a transform and projection matrix. This is code copied from the decompiled vertex shader that is tied to the minimap element.
I also have to bind `vb0`, `cb1` and `cb2` to the compute shader.
Using imHex, I reversed the vb0 binary signature to make my vb0 struct.


<!-- IF YOU CAN READ THIS, PLEASE TO VIEW AS MARKDOWN! -->