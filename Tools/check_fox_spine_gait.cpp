// Evaluate exported Spine with the engine's Y-up convention and actual root travel.
#include <spine/spine.h>
#include <cmath>
#include <iostream>
#include <memory>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 if(argc!=3)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData>data(reader.readSkeletonDataFile(argv[2]));if(!data)return 3;
 auto*anim=data->findAnimation("fmove");if(!anim)return 4;
 double reach=0,height=0,slip=0,minElbow=1000,maxElbow=-1000,minKnee=1000,maxKnee=-1000,minForwardSwing=1000;size_t samples=0;
 for(int direction:{-1,1}){
  Skeleton sk(*data);sk.setScaleX(direction==1?-1:1);double previousX[2]={},previousPhase[2]={1,1};
  for(int frame=0;frame<=720;frame++){
   float time=frame/240.f;sk.setupPose();sk.setX(direction*192*time);
   anim->apply(sk,-1,time,true,nullptr,1,true,false,false,false);sk.updateWorldTransform(Physics_Reset);
   for(int side=0;side<2;side++){
    auto&foot=sk.findBone(side==0?"jiaoL":"jiaoR")->getAppliedPose();auto&target=sk.findBone(side==0?"1":"2")->getAppliedPose();
    double phase=fmod(time+(side==0?.5:0),1.);
    auto&upper=sk.findBone(side==0?"shangbiL":"shangbiR")->getAppliedPose();auto&lower=sk.findBone(side==0?"xiabiL":"xiabiR")->getAppliedPose();
    double angle=lower.getWorldRotationX()-upper.getWorldRotationX();
    while(angle>180)angle-=360;while(angle<-180)angle+=360;
    double forwardFlex=angle*direction;minElbow=std::min(minElbow,forwardFlex);maxElbow=std::max(maxElbow,forwardFlex);
    auto&thigh=sk.findBone(side==0?"datuiL":"datuiR")->getAppliedPose();auto&shin=sk.findBone(side==0?"xiaotuiL":"xiaotuiR")->getAppliedPose();
    double knee=shin.getWorldRotationX()-thigh.getWorldRotationX();while(knee>180)knee-=360;while(knee<-180)knee+=360;
    knee*=-direction;minKnee=std::min(minKnee,knee);maxKnee=std::max(maxKnee,knee);
    if(phase>.68&&phase<.93&&previousPhase[side]>.68&&previousPhase[side]<phase)
     minForwardSwing=std::min(minForwardSwing,(foot.getWorldX()-previousX[side])*direction);
    reach=std::max<double>(reach,hypot(foot.getWorldX()-target.getWorldX(),foot.getWorldY()-target.getWorldY()));
    if(phase<.549&&phase>.001){
     height=std::max(height,fabs(foot.getWorldY()-57.));
     if(previousPhase[side]>.001&&previousPhase[side]<phase&&previousPhase[side]<.549)slip=std::max(slip,fabs(foot.getWorldX()-previousX[side]));
     samples++;
    }
    previousX[side]=foot.getWorldX();previousPhase[side]=phase;
   }
  }
 }
 bool ok=reach<.1&&height<.05&&slip<.05&&minElbow>0&&maxElbow<70&&minKnee>0&&maxKnee<65&&minForwardSwing>0;
 std::cout<<(ok?"PASS":"FAIL")<<" mirroredDirections=2 cyclesPerDirection=3 sampleHz=240 contactSamples="<<samples<<" maxIKError="<<reach<<" maxContactHeightError="<<height<<" maxWorldSlipPerFrame="<<slip<<" minForwardElbowFlex="<<minElbow<<" maxForwardElbowFlex="<<maxElbow<<" minForwardKneeFlex="<<minKnee<<" maxForwardKneeFlex="<<maxKnee<<" minForwardSwingPerFrame="<<minForwardSwing<<" startupAndStopNotCovered=true visualAcceptancePending=true\n";
 return ok?0:1;
}
