// Compare evaluated world vertices, not merely export counts. No texture renderer needed.
#include <spine/spine.h>
#include <algorithm>
#include <cmath>
#include <iostream>
#include <memory>
#include <vector>
using namespace spine;
namespace spine { SpineExtension* getDefaultExtension(){return new DefaultSpineExtension();} }
int main(int argc,char**argv){
 if(argc!=4 && argc!=5){std::cerr<<"usage: compare atlas input.json exported.skel [sampleOffset]\n";return 2;}
 Atlas atlas(argv[1],nullptr,false);SkeletonJson jr(atlas);SkeletonBinary br(atlas);
 std::string input=argv[2];SkeletonBinary originalReader(atlas);
 std::unique_ptr<SkeletonData>a(input.size()>=5 && input.substr(input.size()-5)==".skel"?originalReader.readSkeletonDataFile(argv[2]):jr.readSkeletonDataFile(argv[2])),b(br.readSkeletonDataFile(argv[3]));
 if(!a||!b){std::cerr<<jr.getError().buffer()<<br.getError().buffer();return 2;}
 Skeleton sa(*a),sb(*b);double maxError=0;size_t checked=0;std::string worstAnimation,worstSlot;float worstTime=0;
 if(a->getAnimations().size()>b->getAnimations().size())return 3;
 for(size_t i=0;i<a->getAnimations().size();i++){
  auto*aa=a->getAnimations()[i];auto*ab=b->findAnimation(aa->getName());
  if(!ab||fabs(aa->getDuration()-ab->getDuration())>1e-5)return 3;
  for(int f=0;f<=120;f++){
   float t=std::clamp(aa->getDuration()*f/120.f+(argc==5?std::stof(argv[4]):0.f),0.f,aa->getDuration());sa.setupPose();sb.setupPose();
   aa->apply(sa,-1,t,false,nullptr,1,true,false,false,false);ab->apply(sb,-1,t,false,nullptr,1,true,false,false,false);
   sa.updateWorldTransform(Physics_Reset);sb.updateWorldTransform(Physics_Reset);
   for(size_t j=0;j<sa.getSlots().size();j++){
    auto*s1=sa.getSlots()[j];auto*s2=sb.findSlot(s1->getData().getName());if(!s2)return 4;
    auto*at1=s1->getAppliedPose().getAttachment();auto*at2=s2->getAppliedPose().getAttachment();
    if(!at1&&!at2)continue;
    if(!at1||!at2||at1->getName()!=at2->getName())return 4;
    if(auto*p1=dynamic_cast<PointAttachment*>(at1)){
     auto*p2=dynamic_cast<PointAttachment*>(at2);if(!p2)return 4;
     float x1,y1,x2,y2;p1->computeWorldPosition(s1->getBone().getAppliedPose(),x1,y1);p2->computeWorldPosition(s2->getBone().getAppliedPose(),x2,y2);
     if(!std::isfinite(x1)||!std::isfinite(y1)||!std::isfinite(x2)||!std::isfinite(y2))return 5;
     maxError=std::max(maxError,std::max<double>(fabs(x1-x2),fabs(y1-y2)));checked+=2;continue;
    }
    if(auto*r1=dynamic_cast<RegionAttachment*>(at1)){
     auto*r2=dynamic_cast<RegionAttachment*>(at2);if(!r2)return 4;
     float v1[8],v2[8];
     r1->computeWorldVertices(*s1,r1->getOffsets(s1->getAppliedPose()).buffer(),v1,0,2);
     r2->computeWorldVertices(*s2,r2->getOffsets(s2->getAppliedPose()).buffer(),v2,0,2);
     for(int k=0;k<8;k++){if(!std::isfinite(v1[k])||!std::isfinite(v2[k]))return 5;if(fabs(v1[k]-v2[k])>maxError){maxError=fabs(v1[k]-v2[k]);worstAnimation=aa->getName().buffer();worstSlot=s1->getData().getName().buffer();worstTime=t;}checked++;}
     continue;
    }
    auto*m1=dynamic_cast<MeshAttachment*>(at1);auto*m2=dynamic_cast<MeshAttachment*>(at2);
    if(!m1||!m2||m1->getWorldVerticesLength()!=m2->getWorldVerticesLength())return 4;
    size_t n=m1->getWorldVerticesLength();std::vector<float>v1(n),v2(n);
    m1->computeWorldVertices(sa,*s1,0,n,v1.data(),0,2);m2->computeWorldVertices(sb,*s2,0,n,v2.data(),0,2);
    for(size_t k=0;k<n;k++){if(!std::isfinite(v1[k])||!std::isfinite(v2[k]))return 5;if(fabs(v1[k]-v2[k])>maxError){maxError=fabs(v1[k]-v2[k]);worstAnimation=aa->getName().buffer();worstSlot=s1->getData().getName().buffer();worstTime=t;}checked++;}
   }
  }
 }
 std::cout<<"roundtrip "<<(maxError<.05?"PASS":"FAIL")<<" coordinateSamples="<<checked<<" maxWorldCoordinateError="<<maxError<<" worstAnimation="<<worstAnimation<<" worstSlot="<<worstSlot<<" worstTime="<<worstTime<<" tolerance=.05 animationQualityNotAssessed=true\n";
 return maxError<.05?0:1;
}
