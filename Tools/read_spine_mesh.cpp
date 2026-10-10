// Native Spine evaluation for isolated art review; no Dora process or asset writes.
#include <spine/spine.h>
#include <iostream>
#include <memory>
#include <vector>
using namespace spine;
namespace spine {SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();}}
int main(int argc,char**argv){
 if(argc!=5)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonJson reader(atlas);
 std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile(argv[2]));if(!d){std::cerr<<reader.getError().buffer();return 3;}
 auto*a=d->findAnimation(argv[3]);if(!a)return 4;Skeleton s(*d);s.setupPose();a->apply(s,-1,std::stof(argv[4]),false,nullptr,1,true,false,false,false);s.updateWorldTransform(Physics_Reset);
 std::cout<<"{\"meshes\":[";bool first=true;
 auto&order=s.getDrawOrder().getAppliedPose();
 for(size_t si=0;si<order.size();si++){
  auto*sl=order[si];
  auto*at=sl->getAppliedPose().getAttachment();if(!at)continue;
  if(!at->getRTTI().isExactly(MeshAttachment::rtti)){std::cerr<<"Non-mesh attachment";return 5;}
  auto*m=static_cast<MeshAttachment*>(at);auto n=m->getWorldVerticesLength();std::vector<float>vs(n);m->computeWorldVertices(s,*sl,0,n,vs.data(),0,2);
  if(!first)std::cout<<",";first=false;
  std::cout<<"{\"slot\":\""<<sl->getData().getName().buffer()<<"\",\"path\":\""<<m->getPath().buffer()<<"\",\"vertices\":[";
  for(size_t i=0;i<n;i++){if(i)std::cout<<",";std::cout<<vs[i];}
  std::cout<<"],\"uvs\":[";auto&uv=m->getRegionUVs();for(size_t i=0;i<uv.size();i++){if(i)std::cout<<",";std::cout<<uv[i];}
  auto&seq=m->getSequence();int index=seq.resolveIndex(sl->getAppliedPose());
  auto*region=static_cast<AtlasRegion*>(seq.getRegion(index));if(!region)return 6;
  auto&page=*region->getPage();auto&packedUV=seq.getUVs(index);
  std::cout<<"],\"page\":\""<<page.name.buffer()<<"\",\"atlasUVs\":[";
  for(size_t i=0;i<packedUV.size();i++){if(i)std::cout<<",";std::cout<<packedUV[i];}
  std::cout<<"],\"triangles\":[";auto&ts=m->getTriangles();for(size_t i=0;i<ts.size();i++){if(i)std::cout<<",";std::cout<<ts[i];}std::cout<<"]}";
 }
 std::cout<<"]}\n";
}
