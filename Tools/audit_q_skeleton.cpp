#include <spine/spine.h>
#include <iostream>
#include <memory>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 std::cout<<"asset\tbones\tslots\tconstraints\tattachments\tmeshes\tweightedMeshes\tvertices\tanimations\n";
 for(int k=1;k<argc;k++){
  std::string p=argv[k];Atlas atlas((p+".atlas").c_str(),nullptr,false);SkeletonBinary reader(atlas);std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile((p+".skel").c_str()));
  if(!d){std::cerr<<reader.getError().buffer();return 1;}
  size_t total=0,meshes=0,weighted=0,vertices=0;
  auto&skins=d->getSkins();for(size_t s=0;s<skins.size();s++){auto entries=skins[s]->getAttachments();while(entries.hasNext()){auto&e=entries.next();total++;if(e._attachment->getRTTI().instanceOf(MeshAttachment::rtti)){auto*m=static_cast<MeshAttachment*>(e._attachment);meshes++;if(m->getBones().size())weighted++;vertices+=m->getWorldVerticesLength()/2;}}}
  std::cout<<p<<'\t'<<d->getBones().size()<<'\t'<<d->getSlots().size()<<'\t'<<d->getConstraints().size()<<'\t'<<total<<'\t'<<meshes<<'\t'<<weighted<<'\t'<<vertices<<'\t'<<d->getAnimations().size()<<'\n';
 }
}
