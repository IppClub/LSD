#include <spine/spine.h>
#include <iostream>
#include <memory>
#include <vector>
#include <algorithm>
#include <cmath>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
struct P {const char*name;float lo,hi,value,initial;};
int main(int argc,char**argv){
 if(argc!=3 && argc!=4)return 2;float targetX=argc==4?std::stof(argv[3]):75;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile(argv[2]));if(!d)return 3;Skeleton s(*d);auto*a=d->findAnimation("idle");if(!a)return 4;
 auto*slot=s.findSlot("item");if(!slot)return 5;auto*point=dynamic_cast<PointAttachment*>(s.getAttachment(slot->getData().getIndex(),"s:item"));if(!point)return 6;
 s.setupPose();a->apply(s,-1,0,false,nullptr,1,true,false,false,false);s.updateWorldTransform(Physics_Reset);
 std::vector<P>p={{"R_UpArm",-180,180},{"R_Arm",-100,140},{"R_Hand",-80,80}};
 for(auto&v:p){auto*b=s.findBone(v.name);if(!b)return 7;v.initial=v.value=b->getPose().getRotation()-b->getData().getSetupPose().getRotation();}
 auto apply=[&](){s.setupPose();a->apply(s,-1,0,false,nullptr,1,true,false,false,false);for(auto&v:p){auto*b=s.findBone(v.name);b->getPose().setRotation(b->getData().getSetupPose().getRotation()+v.value);}s.updateWorldTransform(Physics_Reset);};
 auto score=[&](){apply();float x,y;point->computeWorldPosition(slot->getBone().getAppliedPose(),x,y);double loss=pow(x-targetX,2)+pow(y-193,2);for(auto&v:p)loss+=.001*pow(v.value-v.initial,2);return loss;};
 double best=score();for(float step:{20.f,10.f,5.f,2.f,1.f,.25f})for(int j=0;j<15;j++){
  bool changed=false;for(auto&v:p){float old=v.value,chosen=old;for(float sign:{-1.f,1.f}){v.value=std::clamp(old+step*sign,v.lo,v.hi);auto loss=score();if(loss<best){best=loss;chosen=v.value;changed=true;}}v.value=chosen;}if(!changed)break;
 }
 apply();float x,y;point->computeWorldPosition(slot->getBone().getAppliedPose(),x,y);
 std::cout<<"{\"palmX\":"<<x<<",\"palmY\":"<<y<<",\"rotations\":{";bool first=true;for(auto&v:p){if(!first)std::cout<<",";first=false;std::cout<<"\""<<v.name<<"\":"<<v.value;}std::cout<<"}}\n";
 for(auto name:{"melee","throw"}){auto*clip=d->findAnimation(name);s.setupPose();clip->apply(s,-1,name==std::string("melee")?.4:.3333333,false,nullptr,1,true,false,false,false);s.updateWorldTransform(Physics_Reset);point->computeWorldPosition(slot->getBone().getAppliedPose(),x,y);std::cerr<<name<<" palm="<<x<<","<<y<<'\n';}
}
