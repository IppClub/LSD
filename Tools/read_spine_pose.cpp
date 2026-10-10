// Export native evaluated poses for authoring contact-constrained scene motions.
#include <spine/spine.h>
#include <iostream>
#include <memory>
using namespace spine;
namespace spine {SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();}}
int main(int argc,char**argv){
 if(argc!=5)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonJson reader(atlas);
 std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile(argv[2]));if(!d){std::cerr<<reader.getError().buffer();return 3;}
 auto*a=d->findAnimation(argv[3]);if(!a)return 4;Skeleton s(*d);s.setupPose();a->apply(s,-1,std::stof(argv[4]),false,nullptr,1,true,false,false,false);s.updateWorldTransform(Physics_Reset);
 std::cout<<"{\"bones\":[";
 for(size_t i=0;i<s.getBones().size();i++){
  auto*b=s.getBones()[i];auto&p=b->getAppliedPose();p.validateLocalTransform(s);if(i)std::cout<<",";
  std::cout<<"{\"name\":\""<<b->getData().getName().buffer()<<"\",\"x\":"<<p.getX()<<",\"y\":"<<p.getY()<<",\"rotation\":"<<p.getRotation()<<",\"scaleX\":"<<p.getScaleX()<<",\"scaleY\":"<<p.getScaleY()<<",\"shearX\":"<<p.getShearX()<<",\"shearY\":"<<p.getShearY()<<",\"worldX\":"<<p.getWorldX()<<",\"worldY\":"<<p.getWorldY()<<",\"worldRotation\":"<<p.getWorldRotationX()<<",\"worldScaleX\":"<<p.getWorldScaleX()<<"}";
 }
 std::cout<<"],\"slots\":[";
 for(size_t i=0;i<s.getSlots().size();i++){
  auto*sl=s.getSlots()[i];auto*at=sl->getAppliedPose().getAttachment();if(i)std::cout<<",";std::cout<<"{\"name\":\""<<sl->getData().getName().buffer()<<"\",\"attachment\":";
  if(at)std::cout<<"\""<<at->getName().buffer()<<"\"";else std::cout<<"null";std::cout<<"}";
 }
 std::cout<<"]}\n";
}
