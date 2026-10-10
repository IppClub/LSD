// Pose assistance only. Native mesh contact fitting does not establish visual quality.
#include <spine/spine.h>
#include <cmath>
#include <iostream>
#include <memory>
#include <vector>
#include <string>
#include <algorithm>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
struct Param{const char*name;double lo,hi,value,initial;};
int main(int argc,char**argv){
 if(argc!=3)return 2;Bone::setYDown(false);Atlas atlas(argv[1],nullptr,false);SkeletonBinary reader(atlas);
 std::unique_ptr<SkeletonData>data(reader.readSkeletonDataFile(argv[2]));if(!data)return 3;Skeleton s(*data);auto*a=data->findAnimation("knockout");if(!a)return 4;
 std::vector<Param>p={{"bone6",-75,25},{"bone15",-45,50},{"bone16",-75,0},{"bone18",-45,50},{"bone19",-70,0},{"bone8",-70,75},{"bone9",-90,0},{"bone12",-75,70},{"bone13",0,90},{"bone56",-150,150},{"bone36",-65,65},{"bone38",-65,65},{"bone41",-65,65},{"bone44",-70,70},{"bone46",-70,70},{"bone50",-70,70},{"bone55",-70,70}};
 s.setupPose();a->apply(s,-1,a->getDuration(),false,nullptr,1,true,false,false,false);
 for(auto&v:p){auto*b=s.findBone(v.name);v.value=v.initial=b->getPose().getRotation()-b->getData().getSetupPose().getRotation();}
 auto bottom=[&](const char*name){auto*slot=s.findSlot(name);auto*m=dynamic_cast<MeshAttachment*>(slot->getAppliedPose().getAttachment());std::vector<float>v(m->getWorldVerticesLength());m->computeWorldVertices(s,*slot,0,v.size(),v.data(),0,2);double y=1e9;for(size_t i=1;i<v.size();i+=2)y=std::min(y,double(v[i]));return y;};
 auto score=[&](){
  s.setupPose();a->apply(s,-1,a->getDuration(),false,nullptr,1,true,false,false,false);
  double loss=0;for(auto&v:p){auto*b=s.findBone(v.name);b->getPose().setRotation(b->getData().getSetupPose().getRotation()+v.value);loss+=.003*pow(v.value-v.initial,2);}
  s.updateWorldTransform(Physics_Reset);double ground=bottom("shangyi");
  loss+=.3*pow(bottom("youshou")-ground-6,2);
  for(auto name:{"tou","zuoxiaotui","youxiaotui"})loss+=pow(bottom(name)-ground-2,2);
  for(auto name:{"fashi","mawei","pinban","zuoshou","youshou","zuoxiaobi","youxiaobi","qunzi"}){double under=ground-bottom(name);if(under>0)loss+=6*under*under;}
  return loss;
 };
 double best=score();std::cerr<<"initial="<<best<<'\n';
 for(double step:{20.,10.,5.,2.,1.,.5})for(int sweep=0;sweep<12;sweep++){
  bool changed=false;for(auto&v:p){double initial=v.value,chosen=initial;
   for(double sign:{-1.,1.}){v.value=std::clamp(initial+sign*step,v.lo,v.hi);double current=score();if(current<best){best=current;chosen=v.value;changed=true;}}
   v.value=chosen;
  }if(!changed)break;
 }
 score();std::cerr<<"final="<<best<<" bodyGround="<<bottom("shangyi")<<'\n';
 for(auto name:{"tou","zuoxiaotui","youxiaotui","fashi","mawei","pinban"})std::cerr<<name<<" bottom="<<bottom(name)<<'\n';
 std::cout<<"{";bool first=true;for(auto&v:p){if(!first)std::cout<<",";first=false;std::cout<<"\""<<v.name<<"\":"<<v.value;}std::cout<<"}\n";
}
