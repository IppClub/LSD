#include <spine/spine.h>
#include <iostream>
#include <memory>
#include <vector>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 if(argc!=7)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile(argv[2]));if(!d)return 3;
 Skeleton s(*d);s.setupPose();s.updateWorldTransform(Physics_Reset);
 auto*slot=s.findSlot(argv[3]);auto*bone=s.findBone(argv[4]);if(!slot||!bone)return 4;
 auto*m=dynamic_cast<MeshAttachment*>(slot->getAppliedPose().getAttachment());if(!m)return 5;
 auto&uv=m->getRegionUVs();auto&tri=m->getTriangles();float u=std::stof(argv[5]),v=std::stof(argv[6]);
 std::vector<float>w(m->getWorldVerticesLength());m->computeWorldVertices(s,*slot,0,w.size(),w.data(),0,2);
 for(size_t i=0;i<tri.size();i+=3){
  int a=tri[i]*2,b=tri[i+1]*2,c=tri[i+2]*2;
  float den=(uv[b+1]-uv[c+1])*(uv[a]-uv[c])+(uv[c]-uv[b])*(uv[a+1]-uv[c+1]);
  if(std::abs(den)<1e-9)continue;
  float x=((uv[b+1]-uv[c+1])*(u-uv[c])+(uv[c]-uv[b])*(v-uv[c+1]))/den;
  float y=((uv[c+1]-uv[a+1])*(u-uv[c])+(uv[a]-uv[c])*(v-uv[c+1]))/den;float z=1-x-y;
  if(x<0||y<0||z<0)continue;
  float wx=w[a]*x+w[b]*y+w[c]*z,wy=w[a+1]*x+w[b+1]*y+w[c+1]*z,lx,ly;
  bone->getAppliedPose().worldToLocal(wx,wy,lx,ly);
  std::cout<<"{\"x\":"<<lx<<",\"y\":"<<ly<<",\"setupWorldX\":"<<wx<<",\"setupWorldY\":"<<wy<<",\"u\":"<<u<<",\"v\":"<<v<<"}\n";return 0;
 }return 6;
}
