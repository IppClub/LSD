// Match Dora Spine::play, including its empty-animation recovery bridge.
#include <spine/spine.h>
#include <cfloat>
#include <cmath>
#include <iostream>
#include <memory>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
double flex(Skeleton& sk,int side,int direction){
 auto& a=sk.findBone(side?"shangbiR":"shangbiL")->getAppliedPose();
 auto& b=sk.findBone(side?"xiabiR":"xiabiL")->getAppliedPose();
 double r=b.getWorldRotationX()-a.getWorldRotationX();
 while(r>180)r-=360;while(r<-180)r+=360;return r*direction;
}
void play(AnimationState& state,Skeleton& sk,const char* name,float recovery){
 state.setEmptyAnimation(0,recovery);
 state.addAnimation(0,name,true,FLT_EPSILON);
 state.apply(sk);sk.updateWorldTransform(Physics_Pose);
}
int main(int argc,char**argv){
 if(argc!=3)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData>data(reader.readSkeletonDataFile(argv[2]));if(!data)return 3;
 bool ok=true;
 for(auto from:{"idle","fmove","prepare"})for(auto to:{"idle","fmove","prepare"}){
  if(std::string(from)==to)continue;
  double low=1000,high=-1000,jump=0,minKnee=1000,maxKnee=-1000,maxReach=0;int samples=0;
  for(int direction:{-1,1})for(int phase=0;phase<12;phase++){
   Skeleton sk(*data);sk.setScaleX(direction==1?-1:1);
   AnimationStateData mix(*data);mix.setDefaultMix(.15f);AnimationState state(mix);
   state.setAnimation(0,from,true);
   state.update(data->findAnimation(from)->getDuration()*phase/12.f);
   state.apply(sk);sk.updateWorldTransform(Physics_Update);
   double previous[2]={flex(sk,0,direction),flex(sk,1,direction)};
   // Match the preview's animation speed and 0.15 seconds of wall-time recovery.
   float speed=std::string(to)=="fmove"?180.f/(192*.55f):1.f;
   state.setTimeScale(speed);mix.setDefaultMix(.15f*speed);play(state,sk,to,.15f*speed);
   const int frames=std::ceil((.15+data->findAnimation(to)->getDuration()/speed)*240);
   for(int frame=0;frame<=frames;frame++){
    if(frame){state.update(1.f/240);state.apply(sk);sk.updateWorldTransform(Physics_Update);}
    for(int side=0;side<2;side++){
     auto&thigh=sk.findBone(side?"datuiR":"datuiL")->getAppliedPose();auto&shin=sk.findBone(side?"xiaotuiR":"xiaotuiL")->getAppliedPose();
     auto&foot=sk.findBone(side?"jiaoR":"jiaoL")->getAppliedPose();auto&target=sk.findBone(side?"2":"1")->getAppliedPose();
     double knee=shin.getWorldRotationX()-thigh.getWorldRotationX();while(knee>180)knee-=360;while(knee<-180)knee+=360;knee*=-direction;
     minKnee=std::min(minKnee,knee);maxKnee=std::max(maxKnee,knee);maxReach=std::max<double>(maxReach,hypot(foot.getWorldX()-target.getWorldX(),foot.getWorldY()-target.getWorldY()));
     double v=flex(sk,side,direction);if(!std::isfinite(v))return 4;
     low=std::min(low,v);high=std::max(high,v);jump=std::max(jump,fabs(v-previous[side]));previous[side]=v;samples++;
    }
   }
  }
  bool passed=low>=-.05&&high<100&&jump<10&&minKnee>0&&maxKnee<70&&maxReach<.1;ok &= passed;
  std::cout<<(passed?"PASS":"FAIL")<<" from="<<from<<" to="<<to<<" samples="<<samples<<" minForwardFlex="<<low<<" maxForwardFlex="<<high<<" maxFrameDelta="<<jump<<" minForwardKnee="<<minKnee<<" maxForwardKnee="<<maxKnee<<" maxIKError="<<maxReach<<'\n';
 }
 std::cout<<"sampleHz=240 phases=12 mirroredDirections=2 recoveryWallSeconds=0.15 visualAcceptancePending=true footSlipNotCovered=true\n";
 return ok?0:1;
}
