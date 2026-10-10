#include <spine/spine.h>
#include <cmath>
#include <iostream>
#include <memory>
#include <vector>
#include <algorithm>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 if(argc!=4 && argc!=5)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData>data(reader.readSkeletonDataFile(argv[2]));if(!data)return 3;
 Skeleton skeleton(*data);auto*animation=data->findAnimation(argv[3]);if(!animation)return 4;
 int frames=int(std::ceil(animation->getDuration()*120));
 std::cout<<"time,x,y,width,height\n";
 for(int f=0;f<=frames;f++){
  float t=animation->getDuration()*f/frames;skeleton.setupPose();animation->apply(skeleton,-1,t,false,nullptr,1,true,false,false,false);skeleton.updateWorldTransform(Physics_Reset);
  float x,y,w,h;skeleton.getBounds(x,y,w,h);
  if(argc==5){
   auto*slot=skeleton.findSlot(argv[4]);if(!slot)return 6;
   auto*mesh=dynamic_cast<MeshAttachment*>(slot->getAppliedPose().getAttachment());if(!mesh)return 7;
   std::vector<float>v(mesh->getWorldVerticesLength());mesh->computeWorldVertices(skeleton,*slot,0,v.size(),v.data(),0,2);
   x=y=1e9f;float right=-1e9f,top=-1e9f;
   for(size_t i=0;i<v.size();i+=2){x=std::min(x,v[i]);y=std::min(y,v[i+1]);right=std::max(right,v[i]);top=std::max(top,v[i+1]);}
   w=right-x;h=top-y;
  }
  if(!std::isfinite(x+y+w+h))return 5;
  std::cout<<t<<","<<x<<","<<y<<","<<w<<","<<h<<"\n";
 }
}
