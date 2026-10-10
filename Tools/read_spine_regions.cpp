#include <spine/spine.h>
#include <iostream>
#include <memory>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 if(argc!=3)return 2;
 Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile(argv[2]));if(!d)return 3;
 std::cout<<"[";bool first=true;
 for(size_t i=0;i<d->getSkins().size();i++){
  auto*skin=d->getSkins()[i];auto entries=skin->getAttachments();
  while(entries.hasNext()){
   auto&e=entries.next();auto*r=dynamic_cast<RegionAttachment*>(e._attachment);if(!r)continue;
   if(!first)std::cout<<",";first=false;
   std::cout<<"{\"skin\":\""<<skin->getName().buffer()<<"\",\"slot\":\""<<d->getSlots()[e._slotIndex]->getName().buffer()<<"\",\"attachment\":\""<<e._placeholder.buffer()<<"\",\"width\":"<<r->getWidth()<<",\"height\":"<<r->getHeight()<<",\"scaleX\":"<<r->getScaleX()<<",\"scaleY\":"<<r->getScaleY()<<"}";
  }
 }
 std::cout<<"]\n";
}
