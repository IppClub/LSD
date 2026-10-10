#include <spine/spine.h>
#include <iostream>
#include <memory>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 for(int i=1;i<argc;i++){
  std::string path=argv[i];Atlas atlas((path+".atlas").c_str(),nullptr,false);SkeletonBinary reader(atlas);
  std::unique_ptr<SkeletonData> d(reader.readSkeletonDataFile((path+".skel").c_str()));
  if(!d){std::cerr<<reader.getError().buffer();return 1;}
  int count=0;
  for(size_t j=0;j<d->getSkins().size();j++){
   auto* skin=d->getSkins()[j];auto entries=skin->getAttachments();
   while(entries.hasNext()){
    auto& e=entries.next();if(!e._attachment->getRTTI().instanceOf(BoundingBoxAttachment::rtti))continue;
    count++;std::cout<<"BOX\t"<<path<<"\t"<<skin->getName().buffer()<<"\t"<<e._attachment->getName().buffer()<<"\t"<<d->getSlots()[e._slotIndex]->getBoneData().getName().buffer()<<"\n";
   }
  }
  std::cout<<"COUNT\t"<<path<<"\t"<<count<<"\n";
 }
}
