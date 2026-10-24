Unicornshell's UID Remover a.k.a UIDeleter [v1.2.5]
---------------------------------------------------

Overview
--------
This mod removes the in-game, pause menu and profile menu UID
 > Keybind to hide UID on/off: [F11]

Requirements
------------
Unicornshell's UI Scale & Padding Library
>>> https://gamebanana.com/mods/616408






x--x--x--x--x--x--x--x--CHANGELOG--x--x--x--x--x--x--x--x
[null -> v1.0]
 - Initial Release

[v1.0 -> v1.1]
 - Added detection when UI Scale & Padding Library is missing
   > Gooners are allergic to reading

[v1.1 -> v1.2]
 - Fixed small issue in "chart course" wishing menu
 - Added 2048x2048 font atlas hash
 - Made all the UI text hidden when calibration is not complete
   > This should make it much harder to leak your UID

[v1.2 -> v1.2.1]
 - Updated Namecard effect hash for 6.1
 - Fixed UID not being hidden after editing a custom game
 - Added a fairly simple fix for the Miliastra Wonderlands profile UID. Will be fixed later

[v1.2.1 -> v1.2.2]
 - Fixed Namecard effect being active in some Natlan areas (uses a texture now)

[v1.2.2 -> v1.2.3]
 - Reverted method for detecting namecard effect.
   > I also check for the shader's texture now, so it doesn't break in Natlan
 - Removed an extra checktextureoverride, may result in a 1ns framerate increase

[v1.2.3 -> v1.2.4_exp]
 - Fixed the corner UID being visible when $costume_mods is off
 - Changed check for corner UID, now also uses shaders. Playing miliastra wonderland won't break anything now.
   > If the shader runs, other shaderoverrides are skipped. So it should be compatible with most mods.
   > Dev note: Samples the depth buffer to see if the depth buffer was cleared or not
 - Added Miliastra wonderland center UID
 - This is an experimental update. It will work fine, but may not be up to standard with my usual updates.

[v1.2.4_exp -> v1.2.4]
 - Tweaked the thresholds. Should hold up better now.
 - Added hash for EVEN BIGGER TEXTURE ATLAS WEEEEEEEEEE (im not drunk i swear)

[v1.2.4 -> v1.2.5]
 - Updated hashes to version 6.7 (haha 67)
 - Added other texture dimensions for initial loading