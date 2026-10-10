#include <spine/spine.h>
#include <iostream>
#include <memory>
#include <vector>
#include <cmath>
#include "../Docs/artwork/big-yingzhao-hitboxes/probe-manifest.h"
using namespace spine;
namespace spine {SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();}}
int main(int argc,char**argv){
 if(argc!=4)return 2;Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData> original(reader.readSkeletonDataFile(argv[2])),derived(reader.readSkeletonDataFile(argv[3]));if(!original||!derived)return 3;
 Skeleton a(*original),b(*derived);a.setSkin("default");b.setSkin("default");size_t checks=0,artChecks=0;float error=0,artError=0;
 for(int sign:{-1,1})for(size_t ai=0;ai<original->getAnimations().size();ai++)for(int frame=0;frame<=60;frame++){
  auto* animation=original->getAnimations()[ai];auto* copy=derived->findAnimation(animation->getName());if(!copy||std::abs(animation->getDuration()-copy->getDuration())>.001)return 4;
  float time=animation->getDuration()*frame/60;
  a.setupPose();b.setupPose();a.setScaleX(sign);b.setScaleX(sign);
  animation->apply(a,0,time,false,nullptr,1,true,false,false,false);copy->apply(b,0,time,false,nullptr,1,true,false,false,false);
  a.updateWorldTransform(Physics_Pose);b.updateWorldTransform(Physics_Pose);
  for(size_t i=0;i<original->getSlots().size();i++){
   auto* sa=a.findSlot(original->getSlots()[i]->getName());auto* sb=b.findSlot(original->getSlots()[i]->getName());
   auto* ma=dynamic_cast<MeshAttachment*>(sa->getAppliedPose().getAttachment());auto* mb=dynamic_cast<MeshAttachment*>(sb->getAppliedPose().getAttachment());
   if(bool(ma)!=bool(mb))return 5;if(!ma)continue;if(ma->getWorldVerticesLength()!=mb->getWorldVerticesLength())return 6;
   std::vector<float> va(ma->getWorldVerticesLength()),vb(va.size());ma->computeWorldVertices(a,*sa,0,va.size(),va.data(),0,2);mb->computeWorldVertices(b,*sb,0,vb.size(),vb.data(),0,2);
   for(size_t j=0;j<va.size();j++){float delta=std::abs(va[j]-vb[j]);artError=std::max(artError,delta);artChecks++;if(delta>.1){std::cerr<<"Art drift "<<sa->getData().getName().buffer()<<" "<<animation->getName().buffer()<<" "<<delta;return 7;}}
  }
  for(auto&part:parts){
   auto* slot=b.findSlot(part.slot);auto* mesh=dynamic_cast<MeshAttachment*>(slot->getAppliedPose().getAttachment());if(!mesh)return 8;
   std::vector<float> vertices(mesh->getWorldVerticesLength());mesh->computeWorldVertices(b,*slot,0,vertices.size(),vertices.data(),0,2);
   for(size_t i=0;i<part.vertices.size();i++){
    float x=0,y=0;for(auto&ref:part.vertices[i]){
     auto* probeSlot=b.findSlot(ref.slot);
     auto point=[&](const char*suffix){String name((std::string(ref.slot)+suffix).c_str());auto* p=dynamic_cast<PointAttachment*>(derived->findSkin("default")->getAttachment(probeSlot->getData().getIndex(),name));float x,y;p->computeWorldPosition(probeSlot->getBone().getAppliedPose(),x,y);return std::pair<float,float>{x,y};};
     auto o=point("-o"),u=point("-x"),v=point("-y");x+=(o.first+(u.first-o.first)*ref.x/1024+(v.first-o.first)*ref.y/1024)*ref.weight;y+=(o.second+(u.second-o.second)*ref.x/1024+(v.second-o.second)*ref.y/1024)*ref.weight;
    }
    float delta=std::max(std::abs(x-vertices[i*2]),std::abs(y-vertices[i*2+1]));error=std::max(error,delta);checks++;if(delta>.05){std::cerr<<"Hull drift "<<part.slot<<" "<<animation->getName().buffer()<<" "<<delta;return 9;}
   }
  }
 }
 std::cout<<"PASS animations="<<original->getAnimations().size()<<" hullChecks="<<checks<<" hullMaxError="<<error<<" artCoordinates="<<artChecks<<" artMaxError="<<artError<<"\n";
}
