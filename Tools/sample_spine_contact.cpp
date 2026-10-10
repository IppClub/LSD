#include <spine/spine.h>
#include <iostream>
#include <memory>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 if(argc!=6)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile(argv[2]));if(!d)return 3;Skeleton s(*d);
 auto*a=d->findAnimation(argv[3]);auto*slot=s.findSlot(argv[4]);if(!a||!slot)return 4;
 auto*p=dynamic_cast<PointAttachment*>(s.getAttachment(slot->getData().getIndex(),argv[5]));if(!p)return 5;
 std::cout<<"time,x,y\n";
 for(int f=0;f<=60;f++){
  float t=a->getDuration()*f/60;s.setupPose();a->apply(s,-1,t,false,nullptr,1,true,false,false,false);s.updateWorldTransform(Physics_Reset);
  float x,y;p->computeWorldPosition(slot->getBone().getAppliedPose(),x,y);std::cout<<t<<","<<x<<","<<y<<"\n";
 }
}
