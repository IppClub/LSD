// Verify authored contact trajectories with the same Spine runtime as the game.
#include <spine/spine.h>
#include <cmath>
#include <iostream>
#include <memory>
#include <string>
using namespace spine;
namespace spine {SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();}}
double contact(double p,double high){p-=floor(p);if(p<=.7)return high-60*p;double t=(p-.7)/.3,lo=high-42,m=-18;return (2*t*t*t-3*t*t+1)*lo+(t*t*t-2*t*t+t)*m+(-2*t*t*t+3*t*t)*high+(t*t*t-t*t)*m;}
int main(int argc,char**argv){
 if(argc!=4)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonJson reader(atlas);std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile(argv[2]));if(!d){std::cerr<<reader.getError().buffer();return 3;}
 auto*idle=d->findAnimation("idle");auto*a=d->findAnimation("climb");if(!idle||!a)return 4;Skeleton sk(*d);sk.setupPose();idle->apply(sk,-1,0,false,nullptr,1,true,false,false,false);sk.updateWorldTransform(Physics_Reset);
 bool nini=std::string(argv[3])=="ninilite";double highs[]={sk.findBone(nini?"shangbiL":"L_UpArm")->getAppliedPose().getWorldY()+36,sk.findBone(nini?"shangbiR":"R_UpArm")->getAppliedPose().getWorldY()+36,55,55};
 const char*names[]={"climbHandL","climbHandR","climbFootL","climbFootR"};double phases[]={0,.5,.5,0},xs[]={30,40,10,20},maxError=0,maxSlip=0,prevY[4]={},prevPhase[4]={};int count=0;
 for(int f=0;f<=480;f++){
  double p=f/480.;sk.setupPose();a->apply(sk,-1,a->getDuration()*p,false,nullptr,1,true,false,false,false);sk.updateWorldTransform(Physics_Reset);
  for(int j=0;j<4;j++){
   auto*slot=sk.findSlot(names[j]);if(!slot)return 5;auto*point=dynamic_cast<PointAttachment*>(slot->getAppliedPose().getAttachment());if(!point)return 6;float x,y;point->computeWorldPosition(slot->getBone().getAppliedPose(),x,y);if(!std::isfinite(x)||!std::isfinite(y))return 7;
   double phase=p+phases[j];phase-=floor(phase);double error=hypot(x-xs[j],y-contact(p+phases[j],highs[j]));maxError=std::max(maxError,error);
   if(f>0&&phase<=.7&&prevPhase[j]<=phase)maxSlip=std::max(maxSlip,fabs(y+60*p-prevY[j]));prevY[j]=y+60*p;prevPhase[j]=phase;count++;
  }
 }
 bool pass=maxError<.15&&maxSlip<.05&&fabs(a->getDuration()-2.4)<.001;
 std::cout<<"{\"name\":\""<<argv[3]<<"\",\"status\":\""<<(pass?"PASS":"FAIL")<<"\",\"contactSamples\":"<<count<<",\"maxTargetError\":"<<maxError<<",\"maxPlantedFrameSlip\":"<<maxSlip<<",\"duration\":"<<a->getDuration()<<",\"visualAcceptance\":false}\n";return pass?0:1;
}
