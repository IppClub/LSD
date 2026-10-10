#include <spine/spine.h>
#include <cmath>
#include <iostream>
#include <memory>
#include <vector>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
struct Probe {const char*name;double u1,v1,u2,v2;};
// Source-alpha boundaries at midshaft, measured before mesh deformation.
Probe probes[]={
 {"nearUpperArm",.6807575,.57752469,.27283878,.39784841},
 {"farUpperArm",.69000331,.38911920,.29553390,.58449466},
 {"nearForearm",.71653449,.47625826,.39784681,.16040297},
 {"farForearm",.62764279,.18312151,.25281868,.48658622}};
bool sample(MeshAttachment&m,const std::vector<float>&w,double u,double v,double&x,double&y){
 auto&uv=m.getRegionUVs();auto&tri=m.getTriangles();
 for(size_t i=0;i<tri.size();i+=3){int a=tri[i]*2,b=tri[i+1]*2,c=tri[i+2]*2;
  double det=(uv[b+1]-uv[c+1])*(uv[a]-uv[c])+(uv[c]-uv[b])*(uv[a+1]-uv[c+1]);
  if(fabs(det)<1e-12)continue;
  double p=((uv[b+1]-uv[c+1])*(u-uv[c])+(uv[c]-uv[b])*(v-uv[c+1]))/det;
  double q=((uv[c+1]-uv[a+1])*(u-uv[c])+(uv[a]-uv[c])*(v-uv[c+1]))/det;double r=1-p-q;
  if(p>=-1e-6&&q>=-1e-6&&r>=-1e-6){x=p*w[a]+q*w[b]+r*w[c];y=p*w[a+1]+q*w[b+1]+r*w[c+1];return true;}
 }return false;
}
int main(int argc,char**argv){
 if(argc<3)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);
 for(int file=2;file<argc;file++){
  SkeletonBinary reader(atlas);std::unique_ptr<SkeletonData>d(reader.readSkeletonDataFile(argv[file]));if(!d)return 3;
  Skeleton sk(*d);auto*anim=d->findAnimation("fmove");if(!anim)return 4;
  for(auto&p:probes){double low=1e9,high=0;
   for(int frame=0;frame<=240;frame++){
    sk.setupPose();anim->apply(sk,-1,frame/240.f,false,nullptr,1,true,false,false,false);sk.updateWorldTransform(Physics_Reset);
    auto*slot=sk.findSlot(p.name);auto*m=dynamic_cast<MeshAttachment*>(slot->getAppliedPose().getAttachment());if(!m)return 5;
    std::vector<float>w(m->getWorldVerticesLength());m->computeWorldVertices(sk,*slot,0,w.size(),w.data(),0,2);
    double ax,ay,bx,by;if(!sample(*m,w,p.u1,p.v1,ax,ay)||!sample(*m,w,p.u2,p.v2,bx,by))return 6;
    double width=hypot(ax-bx,ay-by);low=std::min(low,width);high=std::max(high,width);
   }
   std::cout<<argv[file]<<'\t'<<p.name<<"\tmin="<<low<<"\tmax="<<high<<"\tvariation="<<high-low<<'\n';
  }
 }
}
