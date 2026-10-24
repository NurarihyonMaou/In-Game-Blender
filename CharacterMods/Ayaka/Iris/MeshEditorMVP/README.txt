Mesh Editor MVP
===============

Target: Kamisato Ayaka, 79,355 position vertices.

Architecture:
  native game VS -> GS+trivial PS capture -> CS picker -> CS state -> CS deform -> writable VB0

Important:
  - The picker does NOT use the game's SV_PrimitiveID.
  - Capture uses a non-indexed point_list draw, so GS SV_PrimitiveID becomes the VB vertex order.
  - The active IB is read directly by the picker through cs-t2 = ib.
  - The deformer always starts from ResourceKamisatoAyakaPosition and adds persistent VertexDelta,
    then transient drag state. This prevents offset accumulation.
  - The only PS is the one-line capture writer; it performs no hit testing.

Files:
  MeshEditorCapture.hlsl
  MeshEditorPick.hlsl
  MeshEditorState.hlsl
  MeshEditorDeform.hlsl
  MeshEditor_MVP.ini

The INI assumes these existing resources/variables:
  ResourceKamisatoAyakaPosition (stride 40, 79,355 vertices)
  Body TextureOverride sets ib = ResourceKamisatoAyakaBodyIB

The Body hook shown at the bottom of MeshEditor_MVP.ini must be inserted into
an actual working Ayaka Body TextureOverride. Do not create a second conflicting
[TextureOverride...] section with the same hash unless you know how your current
config resolves duplicates.

First test should verify:
  1. Capture/picker stops returning unrelated body parts.
  2. HoverResult[7].x is the actual vertex ID under the cursor.
  3. LMB press freezes that ID.
  4. Drag moves only that vertex.
  5. Release leaves the persistent edit in VertexDelta.

This is an architectural/code prototype; it has not been runtime-compiled against
your exact local XXMI build inside this environment.
