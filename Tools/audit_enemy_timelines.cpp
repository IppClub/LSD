// Read authored enemy timelines with the engine's bundled Spine runtime.
// This validates binary parsing and events, not rendering or combat behavior.
#include <spine/spine.h>
#include <iostream>
#include <memory>
#include <string>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 for(int k=1;k<argc;k++){
  std::string path=argv[k];Atlas atlas((path+".atlas").c_str(),nullptr,false);SkeletonBinary reader(atlas);
  std::unique_ptr<SkeletonData> data(reader.readSkeletonDataFile((path+".skel").c_str()));
  if(!data){std::cerr<<path<<": "<<reader.getError().buffer()<<"\n";return 1;}
  Skeleton sk(*data);auto &anims=data->getAnimations();
  for(size_t j=0;j<anims.size();j++){
   auto *a=anims[j];std::cout<<"ANIM\t"<<path<<"\t"<<a->getName().buffer()<<"\t"<<a->getDuration()<<"\n";
   sk.setupPose();Array<Event*> events;
   a->apply(sk,-1,a->getDuration(),false,&events,1,true,false,false,false);
   for(size_t e=0;e<events.size();e++)std::cout<<"EVENT\t"<<path<<"\t"<<a->getName().buffer()<<"\t"<<events[e]->getTime()<<"\t"<<events[e]->getData().getName().buffer()<<"\n";
  }
 }
}
