# garage-sale/ruth2-modified

This repositiry provides the modified sources of
https://marketplace.secondlife.com/p/Ruth2-bento-bom-mesh-avatar-with-sculpted-vagina/23640893

I am using blender 3.1, gimp 2.10 and firestorm 6.5. If you want to make changes, you only need these free programs.
(Ubuntu comes with a "Dyuthi" font. Don't know how to get this font if you use a different os).

This compilation contains modified data from:
https://github.com/RuthAndRoth/Ruth2
https://marketplace.secondlife.com/stores/228512
https://marketplace.secondlife.com/p/Tavatar-ColorTexture-HUD-Kit-Free/4299174
https://marketplace.secondlife.com/p/Priority-6-Ankle-Lock-Gestures-Animation-FREE-FULL-PERM/22672114
https://ambientcg.com/view?id=Leather027


-- ruth2v4pp.blend --

This Blender File contains the mesh from
https://github.com/RuthAndRoth/Ruth2/tree/master/Mesh/Ruth2_v4/Ruth2v4Dev.blend
and the armature
https://github.com/RuthAndRoth/Reference/blob/master/Ada%20Radius/femalePIVOT_rig_avatar_skeleton.xml.blend

Unfortunately mesh and armature do not fit together. Secondlife uses a Maja feature "bind matrix" and "restpose matrix". Vanilla blender does not support these features. The avastar plugin implements this feature, but I don't want to use the plugin. It not only adds nice features. It also adds an extra layer of obfuscation.

So I scaled the mesh to fit the armature.

You can export the mesh with the builtin collada export.
- rotate the rig z90
- apply rotation to rig and all meshes
- select one or more meshes
- File -> Export -> Collada
-- Operator Presets --> sl+open sim rigged
-- Extra -> Keep Bind Info

To upload the mesh in firestorm keep all default values.
Just click "Calculate waights & fee" and "upload".

After uploading, you get the plain mesh or linkset. Blender materials are ignored. You have to tweak the material inworld.

There is problem. The blender collada export has 2 bugs. See blender-export-bug.txt


-- clothes.blend --

This file contails the dress, knickers and shoes.

Export and upload as "sl+open sim rigged" just like the mesh body.


-- ragdoll.blend --

The buttons of the alpha cut hud.

You can export the mesh with the builtin collada export.
- File -> Export -> Collada
-- Operator Presets --> sl+open sim static

To upload the mesh in firestorm keep all default values.
Just click "Calculate waights & fee" and "upload".


-- anim.blend --

The facial expressions.

Firestorm expects the bvh files in a wired rotation. So I copied mesh and armature to an additional file.

You can export the animations with the builtin Motion Capture export.
- select the armature
- in the action exitor select the animation
- verify Start and End
- File -> Export -> Motion Capture
-- Root Translation Only

To upload the bvh in firestorm
-- Priority: 4
-- Loop
-- In (frm): 5
-- Out (frm): 5
-- Mesh avatars ignore "Hand Pose" and "Expression"


-- Directory assets --

This dir contains the gimp files of the uploades images. And some images used by blender.


-- Directory image --

This dir contains only the images used by blender. Not all of the images exported from gimp.

-------------------------------------------------------------------------------

Ruth2 - Open Source Mesh Avatar for Virtual Worlds

For details and copies of relevant licenses see the project repository at https://github.com/RuthAndRoth/Ruth2

License terms for this project vary by part type. Copyrights are by the original Authors. Please do not delete any credits or license files that are included in this project. 

* Ruth2 Copyright 2018 by Shin Ingen, who can be found at https://plus.google.com/+ShinIngen and 2020 by Ada Radius.

The mesh body parts are AGPL. The AGPL license allows personal use of these meshes as you wish however any modifications that are distributed or made available in a service must be released under the same terms granted here.  The contents of this package are the raw mesh uploads with no in-world changes from the Blender exports.

* Built with Blender 2.83.3 and Avastar 2.81.35.
* The UV map is CC-BY Linden Lab
* The Avastar rig contains components licensed as CC-BY-3.0 by Machinimatrix.org

The button mesh included in this package were generated from prim builds by Serie Sumei.  They are licensed under Creative Commons CC-BY-3.0.

Various Authors and contributors to the Git Repo in alphabetical order are:
* Ada Radius
* Ai Austin
* Chimera Firecaster
* Duck Girl
* Elenia Boucher
* Fred Beckhusen
* Fritigern Gothly
* Joe Builder
* Kayaker Magic
* Lelani Carver
* Leona Morro
* Mike Dickson
* Noxluna Nightfire
* Sean Heavy
* Serie Sumei
* Shin Ingen
* Sundance Haiku

* Other contributions and testing by members of the OpenSimulator Community.

The 'R2' logo may be used to indicate projects or products that are either based on or compatible with the RuthAndRoth project mesh bodies.

-------------------------------------------------------------------------------

The modifications made by me are in the public domain. You can do whatever you wish.
