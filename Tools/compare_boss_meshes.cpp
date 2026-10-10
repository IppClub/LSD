// Compare every existing rendered mesh through sampled authored animations.
// Added invisible bounds/probes are deliberately excluded.
#include <spine/spine.h>
#include <iostream>
#include <memory>
#include <vector>
#include <cmath>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 if(argc!=4)return 2;
 Atlas atlas(argv[3],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData> a(reader.readSkeletonDataFile(argv[1])),b(reader.readSkeletonDataFile(argv[2]));
 if(!a||!b){std::cerr<<reader.getError().buffer();return 1;}
 Skeleton sa(*a),sb(*b);sa.setSkin("default");sb.setSkin("default");
 size_t checks=0;float maxError=0;
 for(size_t i=0;i<a->getAnimations().size();i++){
  auto* aa=a->getAnimations()[i];auto* ab=b->findAnimation(aa->getName());
  if(!ab||std::abs(aa->getDuration()-ab->getDuration())>.001){std::cerr<<"Animation differs: "<<aa->getName().buffer();return 1;}
  for(int step=0;step<=30;step++){
   float t=aa->getDuration()*step/30;sa.setupPose();sb.setupPose();
   aa->apply(sa,0,t,false,nullptr,1,true,false,false,false);ab->apply(sb,0,t,false,nullptr,1,true,false,false,false);
   sa.updateWorldTransform(Physics_Pose);sb.updateWorldTransform(Physics_Pose);
   for(size_t j=0;j<sa.getSlots().size();j++){
    auto* x=sa.getSlots()[j];auto* y=sb.findSlot(x->getData().getName());
    if(!y){std::cerr<<"Missing slot";return 1;}
    auto* ax=x->getAppliedPose().getAttachment();auto* ay=y->getAppliedPose().getAttachment();
    if(!ax){if(ay)return 1;continue;}
    if(!ay||ax->getName()!=ay->getName()){std::cerr<<"Attachment differs";return 1;}
    if(!ax->getRTTI().instanceOf(MeshAttachment::rtti))continue;
    auto* mx=static_cast<MeshAttachment*>(ax);auto* my=static_cast<MeshAttachment*>(ay);
    size_t n=mx->getWorldVerticesLength();if(n!=my->getWorldVerticesLength())return 1;
    std::vector<float> vx(n),vy(n);mx->computeWorldVertices(sa,*x,0,n,vx.data(),0,2);my->computeWorldVertices(sb,*y,0,n,vy.data(),0,2);
    for(size_t k=0;k<n;k++){float delta=std::abs(vx[k]-vy[k]);maxError=std::max(maxError,delta);checks++;if(delta>.1){std::cerr<<"Mesh mismatch "<<aa->getName().buffer()<<" "<<x->getData().getName().buffer()<<" at "<<t<<" delta "<<delta;return 1;}}
   }
  }
 }
 std::cout<<"PASS meshCoordinates="<<checks<<" maxError="<<maxError<<" animations="<<a->getAnimations().size()<<"\n";
}
