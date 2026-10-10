#include <spine/spine.h>
#include <iostream>
#include <memory>
#include <vector>
#include <cmath>
#include "../Docs/artwork/flower-hitboxes/probe-manifest.h"
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 if(argc!=3)return 2;Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile(argv[2]));if(!d)return 3;
 Skeleton s(*d);s.setSkin("default");size_t checks=0;float error=0;
 for(int sign:{-1,1})for(size_t ai=0;ai<d->getAnimations().size();ai++)for(int frame=0;frame<=60;frame++){
  auto*anim=d->getAnimations()[ai];
  s.setupPose();s.setScaleX(sign);anim->apply(s,0,anim->getDuration()*frame/60,false,nullptr,1,true,false,false,false);s.updateWorldTransform(Physics_Pose);
  for(auto&part:parts){
   auto*slot=s.findSlot(part.slot);auto*mesh=dynamic_cast<MeshAttachment*>(slot->getAppliedPose().getAttachment());if(!mesh)return 4;
   std::vector<float> vertices(mesh->getWorldVerticesLength());mesh->computeWorldVertices(s,*slot,0,vertices.size(),vertices.data(),0,2);
   for(size_t i=0;i<part.vertices.size();i++){
    float x=0,y=0;
    for(auto&ref:part.vertices[i]){
     auto point=[&](const char*suffix){
      String name((std::string(ref.slot)+suffix).c_str());auto*probeSlot=s.findSlot(name);
      auto*probe=dynamic_cast<PointAttachment*>(probeSlot->getAppliedPose().getAttachment());
      float x,y;probe->computeWorldPosition(probeSlot->getBone().getAppliedPose(),x,y);return std::pair<float,float>{x,y};
     };
     auto o=point("-o"),u=point("-x"),v=point("-y");
     float px=o.first+(u.first-o.first)*ref.x/1024+(v.first-o.first)*ref.y/1024;
     float py=o.second+(u.second-o.second)*ref.x/1024+(v.second-o.second)*ref.y/1024;
     x+=px*ref.weight;y+=py*ref.weight;
    }
    float delta=std::max(std::abs(x-vertices[i*2]),std::abs(y-vertices[i*2+1]));error=std::max(error,delta);checks++;
    if(delta>.05){std::cerr<<"Probe mismatch "<<part.slot<<" "<<anim->getName().buffer()<<" "<<delta;return 6;}
   }
  }
 }
 std::cout<<"PASS mirroredHullVertices="<<checks<<" maxError="<<error<<" animations="<<d->getAnimations().size()<<"\n";
}
