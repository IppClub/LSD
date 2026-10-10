#include <spine/spine.h>
#include <cmath>
#include <iostream>
#include <memory>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){if(argc<3||argc>4)return 2;Bone::setYDown(false);Atlas at(argv[1],nullptr,false);SkeletonBinary r(at);std::unique_ptr<SkeletonData>d(r.readSkeletonDataFile(argv[2]));if(!d)return 3;Skeleton s(*d);const char*state=argc==4?argv[3]:"fmove";auto*a=d->findAnimation(state);if(!a)return 4;
 for(auto side:{"L","R"}){double lo=1e9,hi=0,reach=0,signedLow=1e9,signedHigh=-1e9;float peak=0;for(int f=0;f<=240;f++){float t=f/240.f;s.setupPose();a->apply(s,-1,t*a->getDuration(),false,nullptr,1,true,false,false,false);s.updateWorldTransform(Physics_Reset);auto&u=s.findBone((std::string("datui")+side).c_str())->getAppliedPose();auto&l=s.findBone((std::string("xiaotui")+side).c_str())->getAppliedPose();auto&foot=s.findBone((std::string("jiao")+side).c_str())->getAppliedPose();auto&target=s.findBone(*side=='L'?"1":"2")->getAppliedPose();double angle=l.getWorldRotationX()-u.getWorldRotationX();while(angle>180)angle-=360;while(angle<-180)angle+=360;signedLow=std::min(signedLow,angle);signedHigh=std::max(signedHigh,angle);angle=fabs(angle);lo=std::min(lo,angle);if(angle>hi){hi=angle;peak=t;}reach=std::max<double>(reach,hypot(foot.getWorldX()-target.getWorldX(),foot.getWorldY()-target.getWorldY()));}
 std::cout<<state<<" "<<side<<" signedMin="<<signedLow<<" signedMax="<<signedHigh<<" minFlex="<<lo<<" maxFlex="<<hi<<" peakPhase="<<peak<<" maxIKError="<<reach<<'\n';}}
