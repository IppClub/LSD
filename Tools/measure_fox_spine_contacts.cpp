// Diagnostic: evaluate the actual preview's immediate root travel and native recovery.
// Ankle samples are not full sole/contact geometry and are not a visual acceptance test.
#include <spine/spine.h>
#include <cfloat>
#include <cmath>
#include <iostream>
#include <memory>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 if(argc!=3)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile(argv[2]));if(!d)return 3;
 double lowest=1e9;
 std::cout<<"from,to,sourcePhase,direction,side,groundBandSamples,groundBandTravelPixels,firstY,lastY,minY,maxY\n";
 for(const char* from:{"idle","fmove"}){
  const char*to=std::string(from)=="idle"?"fmove":"idle";
  for(int phase=0;phase<12;phase++)for(int direction:{-1,1}){
   Skeleton sk(*d);sk.setScaleX(direction==1?-1:1);AnimationStateData mix(*d);AnimationState state(mix);
   state.setAnimation(0,from,true);state.update(d->findAnimation(from)->getDuration()*phase/12.f);state.apply(sk);sk.updateWorldTransform(Physics_Update);
   float speed=std::string(to)=="fmove"?180.f/(192*.55f):1.f;
   state.setTimeScale(speed);mix.setDefaultMix(.15f*speed);state.setEmptyAnimation(0,.15f*speed);state.addAnimation(0,to,true,FLT_EPSILON);state.apply(sk);sk.updateWorldTransform(Physics_Pose);
   double prevX[2]={},prevY[2]={},drift[2]={},first[2]={},minY[2]={1e9,1e9},maxY[2]={-1e9,-1e9};int samples[2]={};
   for(int frame=0;frame<=36;frame++){
    if(frame){state.update(1.f/240);if(std::string(to)=="fmove")sk.setX(direction*180.f/.55f*frame/240.f);state.apply(sk);sk.updateWorldTransform(Physics_Update);}
    for(int side=0;side<2;side++){
     auto&p=sk.findBone(side?"jiaoR":"jiaoL")->getAppliedPose();double x=p.getWorldX(),y=p.getWorldY();
     lowest=std::min(lowest,y);minY[side]=std::min(minY[side],y);maxY[side]=std::max(maxY[side],y);
     if(!frame)first[side]=y;
     // Track consecutive near-ground ankles, not an inferred full foot contact.
     if(frame&&fabs(y-57)<2&&fabs(prevY[side]-57)<2){drift[side]+=fabs(x-prevX[side])*.55;samples[side]++;}
     prevX[side]=x;prevY[side]=y;
    }
   }
   for(int side=0;side<2;side++)std::cout<<from<<','<<to<<','<<phase/12.f<<','<<direction<<','<<side<<','<<samples[side]<<','<<drift[side]<<','<<first[side]<<','<<prevY[side]<<','<<minY[side]<<','<<maxY[side]<<'\n';
  }
 }
 bool floorOK=lowest>=56.95;
 std::cerr<<(floorOK?"PASS":"FAIL")<<" recoveryAnkleFloor minY="<<lowest<<" nominalY=57 tolerance=.05 horizontalSlipNotAccepted=true\n";
 return floorOK?0:1;
}
