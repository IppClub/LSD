#include <spine/spine.h>
#include <iostream>
#include <string>
#include <memory>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 for(int k=1;k<argc;k++){
  std::string path=argv[k];Atlas atlas((path+".atlas").c_str(),nullptr,false);SkeletonBinary reader(atlas);
  SkeletonData* data=reader.readSkeletonDataFile((path+".skel").c_str());if(!data){std::cerr<<reader.getError().buffer();return 1;}
  std::unique_ptr<SkeletonData> lifetime(data);Skeleton sk(*data);auto &anims=data->getAnimations();
  for(size_t j=0;j<anims.size();j++){auto *a=anims[j];std::cout<<"ANIM\t"<<path<<"\t"<<a->getName().buffer()<<"\t"<<a->getDuration()<<"\n";
   std::string n=a->getName().buffer();if(n!="idle"&&n!="move"&&n!="prepare"&&n!="fmove")continue;
   for(int f=0;f<=24;f++){sk.setupPose();a->apply(sk,-1,a->getDuration()*f/24.f,false,nullptr,1,true,false,false,false);sk.updateWorldTransform(Physics_Reset);auto&bones=sk.getBones();
    for(size_t b=0;b<bones.size();b++){auto*bone=bones[b];auto&p=bone->getAppliedPose();std::cout<<"BONE\t"<<path<<"\t"<<n<<"\t"<<f<<"\t"<<bone->getData().getName().buffer()<<"\t"<<p.getWorldX()<<"\t"<<p.getWorldY()<<"\t"<<p.getWorldRotationX()<<"\n";}
   }
  }
 }
}
