// Linkset Resizer, by Maestro Linden, 2010.03.12
// This script rescales all prims in a linkset, using a scaling factor specified
// by the user over chat.  The script does some basic sanity checks (ensuring
// that each prim stays within the allowed PRIM_SIZE range of 0.01m to 10m, although
// it does *not* check the prim linkability rules, which are described in:
// http://wiki.secondlife.com/wiki/Linkability_Rules 

float MIN_DIMENSION=0.01; // the minimum scale of a prim allowed, in any dimension
float MAX_DIMENSION=10.0; // the maximum scale of a prim allowed, in any dimension
 
list link_positions;
list link_scales;
float min_original_scale=10.0; // minimum x/y/z component of the scales in the linkset
float max_original_scale=0.0; // minimum x/y/z component of the scales in the linkset
float min_rescale_factor;
float max_rescale_factor;
integer listener;
  
scanLinkset()
{
   vector link_pos;
   vector link_scale;
   integer total_links=llGetNumberOfPrims();
   integer link;
   link_positions=[];
   link_scales=[];
 
   for(link=1; link<=total_links; link++)
   {
       link_pos=llList2Vector(llGetLinkPrimitiveParams(link,[PRIM_POSITION]),0);
       link_scale=llList2Vector(llGetLinkPrimitiveParams(link,[PRIM_SIZE]),0);
 
       // determine the minimum and maximum prim scales in the linkset, 
       //   so that rescaling doesn't fail due to prim scale limitations
       //   NOTE: the full linkability rules are _not_ checked by this script:
       //   http://wiki.secondlife.com/wiki/Linkability_Rules 
       if(link_scale.x<min_original_scale) min_original_scale=link_scale.x;
       else if(link_scale.x>max_original_scale) max_original_scale=link_scale.x;
       if(link_scale.y<min_original_scale) min_original_scale=link_scale.y;
       else if(link_scale.y>max_original_scale) max_original_scale=link_scale.y;
       if(link_scale.z<min_original_scale) min_original_scale=link_scale.z;
       else if(link_scale.z>max_original_scale) max_original_scale=link_scale.z;
 
       link_scales+=[link_scale];
       link_positions+=[(link_pos-llGetRootPosition())/llGetRootRotation()];
 
   }
 
   max_rescale_factor=MAX_DIMENSION/max_original_scale;
   min_rescale_factor=MIN_DIMENSION/min_original_scale;
}
 
rescaleLinkset(float scale)
{
   integer link;
   vector pos_to_set;
   vector scale_to_set;
   integer total_links=llGetListLength(link_positions);
 
   for(link=1; link<=total_links; link++)
   {
       scale_to_set=llList2Vector(link_scales,link-1)*scale;
       pos_to_set=llList2Vector(link_positions,link-1);
       pos_to_set = <pos_to_set.x, pos_to_set.y*scale, pos_to_set.z*scale>;
 
       // don't move the root prim
       if(link==1)
       {
            llSetLinkPrimitiveParamsFast(link,[PRIM_SIZE,scale_to_set]);
       }
       else
       {
           llSetLinkPrimitiveParamsFast(link,[PRIM_POSITION,pos_to_set,PRIM_SIZE,scale_to_set]);
       }
   }
}
 
default
{
   state_entry()
   {
        scanLinkset();
        rescaleLinkset(0.8);
   }
 
}
