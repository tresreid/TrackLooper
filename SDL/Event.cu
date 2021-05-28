# include "Event.cuh"
#include "allocate.h"


unsigned int N_MAX_HITS_PER_MODULE = 100;
const unsigned int N_MAX_MD_PER_MODULES = 100;
const unsigned int N_MAX_SEGMENTS_PER_MODULE = 600; //WHY!
const unsigned int MAX_CONNECTED_MODULES = 40;
const unsigned int N_MAX_TRACKLETS_PER_MODULE = 8000;//temporary
const unsigned int N_MAX_TRIPLETS_PER_MODULE = 5000;
const unsigned int N_MAX_TOTAL_TRIPLETS = 200000;
const unsigned int N_MAX_PIXEL_MD_PER_MODULES = 100000;
const unsigned int N_MAX_PIXEL_SEGMENTS_PER_MODULE = 50000;
const unsigned int N_MAX_QUINTUPLETS_PER_MODULE = 5000;
#ifdef FINAL_T3T4
const unsigned int N_MAX_TRACK_CANDIDATES_PER_MODULE = 50000;
const unsigned int N_MAX_PIXEL_TRACKLETS_PER_MODULE = 3000000;
const unsigned int N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE = 5000000;
#else
const unsigned int N_MAX_TRACK_CANDIDATES_PER_MODULE = 5000;
const unsigned int N_MAX_PIXEL_TRACKLETS_PER_MODULE = 200000;
const unsigned int N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE = 200000;
#endif
const unsigned int N_MAX_PIXEL_TRIPLETS = 3000000;

struct SDL::modules* SDL::modulesInGPU = nullptr;
struct SDL::pixelMap* SDL::pixelMapping = nullptr;
unsigned int SDL::nModules;

SDL::Event::Event()
{
    hitsInGPU = nullptr;
    mdsInGPU = nullptr;
    segmentsInGPU = nullptr;
    trackletsInGPU = nullptr;
    pixelTrackletsInGPU = nullptr;
    tripletsInGPU = nullptr;
    quintupletsInGPU = nullptr;
    trackCandidatesInGPU = nullptr;
    pixelTripletsInGPU = nullptr;


    hitsInCPU = nullptr;
    mdsInCPU = nullptr;
    segmentsInCPU = nullptr;
    trackletsInCPU = nullptr;
    pixelTrackletsInCPU = nullptr;
    tripletsInCPU = nullptr;
    trackCandidatesInCPU = nullptr;
    modulesInCPU = nullptr;
    modulesInCPUFull = nullptr;
    quintupletsInCPU = nullptr;
    pixelTripletsInCPU = nullptr;

    //reset the arrays
    for(int i = 0; i<6; i++)
    {
        n_hits_by_layer_barrel_[i] = 0;
        n_minidoublets_by_layer_barrel_[i] = 0;
        n_segments_by_layer_barrel_[i] = 0;
        n_tracklets_by_layer_barrel_[i] = 0;
        n_triplets_by_layer_barrel_[i] = 0;
        n_trackCandidates_by_layer_barrel_[i] = 0;
        n_quintuplets_by_layer_barrel_[i] = 0;
        if(i<5)
        {
            n_hits_by_layer_endcap_[i] = 0;
            n_minidoublets_by_layer_endcap_[i] = 0;
            n_segments_by_layer_endcap_[i] = 0;
            n_tracklets_by_layer_endcap_[i] = 0;
            n_triplets_by_layer_endcap_[i] = 0;
            n_trackCandidates_by_layer_endcap_[i] = 0;
            n_quintuplets_by_layer_endcap_[i] = 0;
        }
    }
    resetObjectsInModule();

}

SDL::Event::~Event()
{

#ifdef CACHE_ALLOC
    mdsInGPU->freeMemoryCache();
    segmentsInGPU->freeMemoryCache();
    tripletsInGPU->freeMemoryCache();
    pixelTrackletsInGPU->freeMemoryCache();
    trackCandidatesInGPU->freeMemoryCache();
#ifdef FINAL_T5
    quintupletsInGPU->freeMemoryCache();
#endif
#ifdef FINAL_T3T4
    trackletsInGPU->freeMemoryCache();
#endif
#else
    mdsInGPU->freeMemory();
    segmentsInGPU->freeMemory();
    tripletsInGPU->freeMemory();
    pixelTrackletsInGPU->freeMemory();
    trackCandidatesInGPU->freeMemory();
#ifdef FINAL_T5
    quintupletsInGPU->freeMemory();
#endif
#ifdef FINAL_T3T4
    trackletsInGPU->freeMemory();
#endif
#endif
    cudaFreeHost(mdsInGPU);
    cudaFreeHost(segmentsInGPU);
    cudaFreeHost(tripletsInGPU);
    cudaFreeHost(pixelTrackletsInGPU);
    cudaFreeHost(trackCandidatesInGPU);
    hitsInGPU->freeMemory();
    cudaFreeHost(hitsInGPU);

    pixelTripletsInGPU->freeMemory();
    cudaFreeHost(pixelTripletsInGPU);

#ifdef FINAL_T5
    cudaFreeHost(quintupletsInGPU);
#endif
#ifdef FINAL_T3T4
    cudaFreeHost(trackletsInGPU);
#endif

#ifdef Explicit_Hit
    if(hitsInCPU != nullptr)
    {
        delete[] hitsInCPU->idxs;
        delete[] hitsInCPU->xs;
        delete[] hitsInCPU->ys;
        delete[] hitsInCPU->zs;
        delete[] hitsInCPU->moduleIndices;
        delete hitsInCPU->nHits;
        delete hitsInCPU;
    }
#endif
#ifdef Explicit_MD
    if(mdsInCPU != nullptr)
    {
        delete[] mdsInCPU->hitIndices;
        delete[] mdsInCPU->nMDs;
        delete mdsInCPU;
    }
#endif
#ifdef Explicit_Seg
    if(segmentsInCPU != nullptr)
    {
        delete[] segmentsInCPU->mdIndices;
        delete[] segmentsInCPU->nSegments;
        delete[] segmentsInCPU->innerMiniDoubletAnchorHitIndices;
        delete[] segmentsInCPU->outerMiniDoubletAnchorHitIndices;
        delete[] segmentsInCPU->ptIn;
        delete[] segmentsInCPU->eta;
        delete[] segmentsInCPU->phi;
        delete segmentsInCPU;
    }
#endif
#ifdef Explicit_Tracklet
    if(trackletsInCPU != nullptr)
    {
        delete[] trackletsInCPU->segmentIndices;
        delete[] trackletsInCPU->nTracklets;
        delete[] trackletsInCPU->betaIn;
        delete[] trackletsInCPU->betaOut;
        delete[] trackletsInCPU->pt_beta;
        delete trackletsInCPU;
    }
    if(pixelTrackletsInCPU != nullptr)
    {
        delete[] pixelTrackletsInCPU->segmentIndices;
        delete pixelTrackletsInCPU->nPixelTracklets;
        delete[] pixelTrackletsInCPU->betaIn;
        delete[] pixelTrackletsInCPU->betaOut;
        delete[] pixelTrackletsInCPU->pt_beta;
        delete pixelTrackletsInCPU;
    }
#endif
#ifdef Explicit_Trips
    if(tripletsInCPU != nullptr)
    {
        delete[] tripletsInCPU->segmentIndices;
        delete[] tripletsInCPU->nTriplets;
        delete[] tripletsInCPU->betaIn;
        delete[] tripletsInCPU->betaOut;
        delete[] tripletsInCPU->pt_beta;
        delete tripletsInCPU;
    }
#endif
#ifdef Explicit_T5
#ifdef FINAL_T5
    if(quintupletsInCPU != nullptr)
    {
        delete[] quintupletsInCPU->tripletIndices;
        delete[] quintupletsInCPU->nQuintuplets;
        delete[] quintupletsInCPU->lowerModuleIndices;
        delete[] quintupletsInCPU->innerRadius;
        delete[] quintupletsInCPU->outerRadius;
        delete quintupletsInCPU;
    }
#endif
#endif

#ifdef Explicit_PT3
    if(pixelTripletsInCPU != nullptr)
    {
        delete[] pixelTripletsInCPU->tripletIndices;
        delete[] pixelTripletsInCPU->pixelSegmentIndices;
        delete[] pixelTripletsInCPU->pixelRadius;
        delete[] pixelTripletsInCPU->tripletRadius;
        delete pixelTripletsInCPU->nPixelTriplets;
        delete pixelTripletsInCPU;
    }
#endif

#ifdef Explicit_Track
    if(trackCandidatesInCPU != nullptr)
    {
        delete[] trackCandidatesInCPU->objectIndices;
        delete[] trackCandidatesInCPU->trackCandidateType;
        delete[] trackCandidatesInCPU->nTrackCandidates;
        delete trackCandidatesInCPU;
    }
#endif
#ifdef Explicit_Module
    if(modulesInCPU != nullptr)
    {
        delete[] modulesInCPU->nLowerModules;
        delete[] modulesInCPU->nModules;
        delete[] modulesInCPU->lowerModuleIndices;
        delete[] modulesInCPU->detIds;
        delete[] modulesInCPU->hitRanges;
        delete[] modulesInCPU->isLower;
        delete[] modulesInCPU->trackCandidateModuleIndices;
        delete[] modulesInCPU->quintupletModuleIndices;
        delete[] modulesInCPU->layers;
        delete[] modulesInCPU->subdets;
        delete[] modulesInCPU->rings;
        delete[] modulesInCPU;
    }
    if(modulesInCPUFull != nullptr)
    {
        delete[] modulesInCPUFull->detIds;
        delete[] modulesInCPUFull->moduleMap;
        delete[] modulesInCPUFull->nConnectedModules;
        delete[] modulesInCPUFull->drdzs;
        delete[] modulesInCPUFull->slopes;
        delete[] modulesInCPUFull->nModules;
        delete[] modulesInCPUFull->nLowerModules;
        delete[] modulesInCPUFull->layers;
        delete[] modulesInCPUFull->rings;
        delete[] modulesInCPUFull->modules;
        delete[] modulesInCPUFull->rods;
        delete[] modulesInCPUFull->subdets;
        delete[] modulesInCPUFull->sides;
        delete[] modulesInCPUFull->isInverted;
        delete[] modulesInCPUFull->isLower;

        delete[] modulesInCPUFull->hitRanges;
        delete[] modulesInCPUFull->mdRanges;
        delete[] modulesInCPUFull->segmentRanges;
        delete[] modulesInCPUFull->trackletRanges;
        delete[] modulesInCPUFull->tripletRanges;
        delete[] modulesInCPUFull->trackCandidateRanges;

        delete[] modulesInCPUFull->moduleType;
        delete[] modulesInCPUFull->moduleLayerType;

        delete[] modulesInCPUFull->lowerModuleIndices;
        delete[] modulesInCPUFull->reverseLookupLowerModuleIndices;
        delete[] modulesInCPUFull->trackCandidateModuleIndices;
        delete[] modulesInCPUFull->quintupletModuleIndices;
        delete[] modulesInCPUFull;
    }
#endif
}

void SDL::initModules(const char* moduleMetaDataFilePath)
{
    if(modulesInGPU == nullptr)
    {
        cudaMallocHost(&modulesInGPU, sizeof(struct SDL::modules));
        //pixelMapping = new pixelMap;
        cudaMallocHost(&pixelMapping, sizeof(struct SDL::pixelMap));
        loadModulesFromFile(*modulesInGPU,nModules,*pixelMapping,moduleMetaDataFilePath); //nModules gets filled here
    }
    resetObjectRanges(*modulesInGPU,nModules);
}

void SDL::cleanModules()
{
  #ifdef CACHE_ALLOC
  freeModulesCache(*modulesInGPU,*pixelMapping);
  #else
  freeModules(*modulesInGPU,*pixelMapping);
  #endif
  cudaFreeHost(modulesInGPU);
  cudaFreeHost(pixelMapping);
}

void SDL::Event::resetObjectsInModule()
{
    resetObjectRanges(*modulesInGPU,nModules);
}

// Best working hit loading method. Previously named OMP
void SDL::Event::addHitToEvent(std::vector<float> x, std::vector<float> y, std::vector<float> z, std::vector<unsigned int> detId, std::vector<unsigned int> idxInNtuple)
{
    const int loopsize = x.size();// use the actual number of hits instead of a "max"

    if(hitsInGPU == nullptr)
    {

        cudaMallocHost(&hitsInGPU, sizeof(SDL::hits));
        #ifdef Explicit_Hit
    	  createHitsInExplicitMemory(*hitsInGPU, 2*loopsize); //unclear why but this has to be 2*loopsize to avoid crashing later (reported in tracklet allocation). seems to do with nHits values as well. this allows nhits to be set to the correct value of loopsize to get correct results without crashing. still beats the "max hits" so i think this is fine.
        #else
        createHitsInUnifiedMemory(*hitsInGPU,2*loopsize,0);
        #endif
    }


    float* host_x = &x[0]; // convert from std::vector to host array easily since vectors are ordered
    float* host_y = &y[0];
    float* host_z = &z[0];
    float* host_phis;
    float* host_etas;
    unsigned int* host_detId = &detId[0];
    unsigned int* host_idxs = &idxInNtuple[0];
    unsigned int* host_moduleIndex;
    float* host_rts;
    //float* host_idxs;
    float* host_highEdgeXs;
    float* host_highEdgeYs;
    float* host_lowEdgeXs;
    float* host_lowEdgeYs;
    cudaMallocHost(&host_moduleIndex,sizeof(unsigned int)*loopsize);
    cudaMallocHost(&host_phis,sizeof(float)*loopsize);
    cudaMallocHost(&host_etas,sizeof(float)*loopsize);
    cudaMallocHost(&host_rts,sizeof(float)*loopsize);
    //cudaMallocHost(&host_idxs,sizeof(unsigned int)*loopsize);
    cudaMallocHost(&host_highEdgeXs,sizeof(float)*loopsize);
    cudaMallocHost(&host_highEdgeYs,sizeof(float)*loopsize);
    cudaMallocHost(&host_lowEdgeXs,sizeof(float)*loopsize);
    cudaMallocHost(&host_lowEdgeYs,sizeof(float)*loopsize);


    short* module_layers;
    short* module_subdet;
    int* module_hitRanges;
    ModuleType* module_moduleType;
    cudaMallocHost(&module_layers,sizeof(short)*nModules);
    cudaMallocHost(&module_subdet,sizeof(short)*nModules);
    cudaMallocHost(&module_hitRanges,sizeof(int)*2*nModules);
    cudaMallocHost(&module_moduleType,sizeof(ModuleType)*nModules);
    cudaMemcpy(module_layers,modulesInGPU->layers,nModules*sizeof(short),cudaMemcpyDeviceToHost);
    cudaMemcpy(module_subdet,modulesInGPU->subdets,nModules*sizeof(short),cudaMemcpyDeviceToHost);
    cudaMemcpy(module_hitRanges,modulesInGPU->hitRanges,nModules*2*sizeof(int),cudaMemcpyDeviceToHost);
    cudaMemcpy(module_moduleType,modulesInGPU->moduleType,nModules*sizeof(ModuleType),cudaMemcpyDeviceToHost);


  for (int ihit=0; ihit<loopsize;ihit++){
    unsigned int moduleLayer = module_layers[(*detIdToIndex)[host_detId[ihit]]];
    unsigned int subdet = module_subdet[(*detIdToIndex)[host_detId[ihit]]];
    host_moduleIndex[ihit] = (*detIdToIndex)[host_detId[ihit]];


      host_rts[ihit] = sqrt(host_x[ihit]*host_x[ihit] + host_y[ihit]*host_y[ihit]);
      host_phis[ihit] = phi(host_x[ihit],host_y[ihit],host_z[ihit]);
      host_etas[ihit] = ((host_z[ihit]>0)-(host_z[ihit]<0))* std::acosh(sqrt(host_x[ihit]*host_x[ihit]+host_y[ihit]*host_y[ihit]+host_z[ihit]*host_z[ihit])/host_rts[ihit]);
//// This part i think has a race condition. so this is not run in parallel.
      unsigned int this_index = host_moduleIndex[ihit];
      if(module_subdet[this_index] == Endcap && module_moduleType[this_index] == TwoS)
      {
          float xhigh, yhigh, xlow, ylow;
          getEdgeHits(host_detId[ihit],host_x[ihit],host_y[ihit],xhigh,yhigh,xlow,ylow);
          host_highEdgeXs[ihit] = xhigh;
          host_highEdgeYs[ihit] = yhigh;
          host_lowEdgeXs[ihit] = xlow;
          host_lowEdgeYs[ihit] = ylow;

      }

      //set the hit ranges appropriately in the modules struct

      ////start the index rolling if the module is encountered for the first time
      ////always update the end index
      //modulesInGPU->hitRanges[this_index * 2 + 1] = ihit;
      //start the index rolling if the module is encountered for the first time
      if(module_hitRanges[this_index * 2] == -1)
      {
          module_hitRanges[this_index * 2] = ihit;
      }
      //always update the end index
      module_hitRanges[this_index * 2 + 1] = ihit;

  }
//simply copy the host arrays to the hitsInGPU struct
    cudaMemcpy(hitsInGPU->xs,host_x,loopsize*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->ys,host_y,loopsize*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->zs,host_z,loopsize*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->rts,host_rts,loopsize*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->phis,host_phis,loopsize*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->etas,host_etas,loopsize*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->idxs,host_idxs,loopsize*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->moduleIndices,host_moduleIndex,loopsize*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->highEdgeXs,host_highEdgeXs,loopsize*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->highEdgeYs,host_highEdgeYs,loopsize*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->lowEdgeXs,host_lowEdgeXs,loopsize*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->lowEdgeYs,host_lowEdgeYs,loopsize*sizeof(float),cudaMemcpyHostToDevice);
    cudaMemcpy(hitsInGPU->nHits,&loopsize,sizeof(unsigned int),cudaMemcpyHostToDevice);// value can't correctly be set in hit allocation
    cudaMemcpy(modulesInGPU->hitRanges,module_hitRanges,nModules*2*sizeof(int),cudaMemcpyHostToDevice);// value can't correctly be set in hit allocation
    cudaDeviceSynchronize(); //doesn't seem to make a difference

    cudaFreeHost(host_rts);
    //cudaFreeHost(host_idxs);
    cudaFreeHost(host_phis);
    cudaFreeHost(host_etas);
    cudaFreeHost(host_moduleIndex);
    cudaFreeHost(host_highEdgeXs);
    cudaFreeHost(host_highEdgeYs);
    cudaFreeHost(host_lowEdgeXs);
    cudaFreeHost(host_lowEdgeYs);
    cudaFreeHost(module_layers);
    cudaFreeHost(module_subdet);
    cudaFreeHost(module_hitRanges);
    cudaFreeHost(module_moduleType);

}
__global__ void addPixelSegmentToEventKernel(unsigned int* hitIndices0,unsigned int* hitIndices1,unsigned int* hitIndices2,unsigned int* hitIndices3, float* dPhiChange, float* ptIn, float* ptErr, float* px, float* py, float* pz, float* eta, float* etaErr,float* phi, unsigned int pixelModuleIndex, struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU,const int size, int* superbin, int* pixelType)
{

    for( int tid = blockIdx.x * blockDim.x + threadIdx.x; tid < size; tid += blockDim.x*gridDim.x)
    {

      unsigned int innerMDIndex = pixelModuleIndex * N_MAX_MD_PER_MODULES + 2*(tid);
      unsigned int outerMDIndex = pixelModuleIndex * N_MAX_MD_PER_MODULES + 2*(tid) +1;
      unsigned int pixelSegmentIndex = pixelModuleIndex * N_MAX_SEGMENTS_PER_MODULE + tid;
#ifdef DUP_RM
    bool dup = false;
    for (int i=0; i<tid; i++){
        if(abs(eta[i] - eta[tid]) > 0.3){continue;}
        if(abs(phi[i] - phi[tid]) > 0.3){continue;}
        //if(abs(ptIn[i] - ptIn[tid])/ptIn[tid] > 0.3){continue;}
        float dR2 = (eta[i]-eta[tid])*(eta[i]-eta[tid]) + (phi[i]-phi[tid])*(phi[i]-phi[tid]);
        //if(dR2 > 0.001){continue;}
        dup = true;
        break;
      }
      if(!dup){
#ifdef CUT_VALUE_DEBUG
      addMDToMemory(mdsInGPU, hitsInGPU, modulesInGPU, hitIndices0[tid], hitIndices1[tid], pixelModuleIndex, 0,0,0,0,0,0,0,0,0,0,0,0,0,innerMDIndex);
      addMDToMemory(mdsInGPU, hitsInGPU, modulesInGPU, hitIndices2[tid], hitIndices3[tid], pixelModuleIndex, 0,0,0,0,0,0,0,0,0,0,0,0,0,outerMDIndex);
#else
      addMDToMemory(mdsInGPU, hitsInGPU, modulesInGPU, hitIndices0[tid], hitIndices1[tid], pixelModuleIndex, 0,0,0,0,0,0,0,0,0,innerMDIndex);
      addMDToMemory(mdsInGPU, hitsInGPU, modulesInGPU, hitIndices2[tid], hitIndices3[tid], pixelModuleIndex, 0,0,0,0,0,0,0,0,0,outerMDIndex);
#endif
      addPixelSegmentToMemory(segmentsInGPU, mdsInGPU, hitsInGPU, modulesInGPU, innerMDIndex, outerMDIndex, pixelModuleIndex, hitIndices0[tid], hitIndices2[tid], dPhiChange[tid], ptIn[tid], ptErr[tid], px[tid], py[tid], pz[tid], etaErr[tid], eta[tid], phi[tid], pixelSegmentIndex, tid, superbin[tid], pixelType[tid]);
    }
#else
#ifdef CUT_VALUE_DEBUG
      addMDToMemory(mdsInGPU, hitsInGPU, modulesInGPU, hitIndices0[tid], hitIndices1[tid], pixelModuleIndex, 0,0,0,0,0,0,0,0,0,0,0,0,0,innerMDIndex);
      addMDToMemory(mdsInGPU, hitsInGPU, modulesInGPU, hitIndices2[tid], hitIndices3[tid], pixelModuleIndex, 0,0,0,0,0,0,0,0,0,0,0,0,0,outerMDIndex);
#else
      addMDToMemory(mdsInGPU, hitsInGPU, modulesInGPU, hitIndices0[tid], hitIndices1[tid], pixelModuleIndex, 0,0,0,0,0,0,0,0,0,innerMDIndex);
      addMDToMemory(mdsInGPU, hitsInGPU, modulesInGPU, hitIndices2[tid], hitIndices3[tid], pixelModuleIndex, 0,0,0,0,0,0,0,0,0,outerMDIndex);
#endif
      addPixelSegmentToMemory(segmentsInGPU, mdsInGPU, hitsInGPU, modulesInGPU, innerMDIndex, outerMDIndex, pixelModuleIndex, hitIndices0[tid], hitIndices2[tid], dPhiChange[tid], ptIn[tid], ptErr[tid], px[tid], py[tid], pz[tid], etaErr[tid], eta[tid], phi[tid], pixelSegmentIndex, tid, superbin[tid], pixelType[tid]);
#endif
    }
}
void SDL::Event::addPixelSegmentToEvent(std::vector<unsigned int> hitIndices0,std::vector<unsigned int> hitIndices1,std::vector<unsigned int> hitIndices2,std::vector<unsigned int> hitIndices3, std::vector<float> dPhiChange, std::vector<float> ptIn, std::vector<float> ptErr, std::vector<float> px, std::vector<float> py, std::vector<float> pz, std::vector<float> eta, std::vector<float> etaErr, std::vector<float> phi, std::vector<int> superbin, std::vector<int> pixelType)
{
    if(mdsInGPU == nullptr)
    {
        cudaMallocHost(&mdsInGPU, sizeof(SDL::miniDoublets));
#ifdef Explicit_MD
    	createMDsInExplicitMemory(*mdsInGPU, N_MAX_MD_PER_MODULES, nModules, N_MAX_PIXEL_MD_PER_MODULES);
#else
    	createMDsInUnifiedMemory(*mdsInGPU, N_MAX_MD_PER_MODULES, nModules, N_MAX_PIXEL_MD_PER_MODULES);
#endif
    }
    if(segmentsInGPU == nullptr)
    {
        cudaMallocHost(&segmentsInGPU, sizeof(SDL::segments));
#ifdef Explicit_Seg
        createSegmentsInExplicitMemory(*segmentsInGPU, N_MAX_SEGMENTS_PER_MODULE, nModules, N_MAX_PIXEL_SEGMENTS_PER_MODULE);
#else
        createSegmentsInUnifiedMemory(*segmentsInGPU, N_MAX_SEGMENTS_PER_MODULE, nModules, N_MAX_PIXEL_SEGMENTS_PER_MODULE);
#endif
    }
    const int size = ptIn.size();
    unsigned int pixelModuleIndex = (*detIdToIndex)[1];
    unsigned int* hitIndices0_host = &hitIndices0[0];
    unsigned int* hitIndices1_host = &hitIndices1[0];
    unsigned int* hitIndices2_host = &hitIndices2[0];
    unsigned int* hitIndices3_host = &hitIndices3[0];
    float* dPhiChange_host = &dPhiChange[0];
    float* ptIn_host = &ptIn[0];
    float* ptErr_host = &ptErr[0];
    float* px_host = &px[0];
    float* py_host = &py[0];
    float* pz_host = &pz[0];
    float* etaErr_host = &etaErr[0];
    float* eta_host = &eta[0];
    float* phi_host = &phi[0];
    int* superbin_host = &superbin[0];
    int* pixelType_host = &pixelType[0];

    unsigned int* hitIndices0_dev;
    unsigned int* hitIndices1_dev;
    unsigned int* hitIndices2_dev;
    unsigned int* hitIndices3_dev;
    float* dPhiChange_dev;
    float* ptIn_dev;
    float* ptErr_dev;
    float* px_dev;
    float* py_dev;
    float* pz_dev;
    float* etaErr_dev;
    float* eta_dev;
    float* phi_dev;
    int* superbin_dev;
    int* pixelType_dev;

    cudaMalloc(&hitIndices0_dev,size*sizeof(unsigned int));
    cudaMalloc(&hitIndices1_dev,size*sizeof(unsigned int));
    cudaMalloc(&hitIndices2_dev,size*sizeof(unsigned int));
    cudaMalloc(&hitIndices3_dev,size*sizeof(unsigned int));
    cudaMalloc(&dPhiChange_dev,size*sizeof(unsigned int));
    cudaMalloc(&ptIn_dev,size*sizeof(unsigned int));
    cudaMalloc(&ptErr_dev,size*sizeof(unsigned int));
    cudaMalloc(&px_dev,size*sizeof(unsigned int));
    cudaMalloc(&py_dev,size*sizeof(unsigned int));
    cudaMalloc(&pz_dev,size*sizeof(unsigned int));
    cudaMalloc(&etaErr_dev,size*sizeof(unsigned int));
    cudaMalloc(&eta_dev, size*sizeof(unsigned int));
    cudaMalloc(&phi_dev, size*sizeof(unsigned int));
    cudaMalloc(&superbin_dev,size*sizeof(int));
    cudaMalloc(&pixelType_dev,size*sizeof(int));

    cudaMemcpy(hitIndices0_dev,hitIndices0_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(hitIndices1_dev,hitIndices1_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(hitIndices2_dev,hitIndices2_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(hitIndices3_dev,hitIndices3_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(dPhiChange_dev,dPhiChange_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(ptIn_dev,ptIn_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(ptErr_dev,ptErr_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(px_dev,px_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(py_dev,py_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(pz_dev,pz_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(etaErr_dev,etaErr_host,size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(eta_dev, eta_host, size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(phi_dev, phi_host, size*sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaMemcpy(superbin_dev,superbin_host,size*sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(pixelType_dev,pixelType_host,size*sizeof(int),cudaMemcpyHostToDevice);

    unsigned int nThreads = 256;
    unsigned int nBlocks =  size % nThreads == 0 ? size/nThreads : size/nThreads + 1;

  addPixelSegmentToEventKernel<<<nBlocks,nThreads>>>(hitIndices0_dev,hitIndices1_dev,hitIndices2_dev,hitIndices3_dev,dPhiChange_dev,ptIn_dev,ptErr_dev,px_dev,py_dev,pz_dev,eta_dev, etaErr_dev, phi_dev, pixelModuleIndex, *modulesInGPU,*hitsInGPU,*mdsInGPU,*segmentsInGPU,size, superbin_dev, pixelType_dev);
   //std::cout<<"Number of pixel segments = "<<size<<std::endl;
   cudaDeviceSynchronize();
   cudaMemcpy(&(segmentsInGPU->nSegments)[pixelModuleIndex], &size, sizeof(unsigned int), cudaMemcpyHostToDevice);
   unsigned int mdSize = 2 * size;
   cudaMemcpy(&(mdsInGPU->nMDs)[pixelModuleIndex], &mdSize, sizeof(unsigned int), cudaMemcpyHostToDevice);

  cudaFree(hitIndices0_dev);
  cudaFree(hitIndices1_dev);
  cudaFree(hitIndices2_dev);
  cudaFree(hitIndices3_dev);
  cudaFree(dPhiChange_dev);
  cudaFree(ptIn_dev);
  cudaFree(ptErr_dev);
  cudaFree(px_dev);
  cudaFree(py_dev);
  cudaFree(pz_dev);
  cudaFree(etaErr_dev);
  cudaFree(eta_dev);
  cudaFree(phi_dev);
  cudaFree(superbin_dev);
  cudaFree(pixelType_dev);
}

void SDL::Event::addMiniDoubletsToEvent()
{
    unsigned int idx;
    for(unsigned int i = 0; i<*(SDL::modulesInGPU->nLowerModules); i++)
    {
        idx = SDL::modulesInGPU->lowerModuleIndices[i];
        if(mdsInGPU->nMDs[idx] == 0 or modulesInGPU->hitRanges[idx * 2] == -1)
        {
            modulesInGPU->mdRanges[idx * 2] = -1;
            modulesInGPU->mdRanges[idx * 2 + 1] = -1;
        }
        else
        {
            modulesInGPU->mdRanges[idx * 2] = idx * N_MAX_MD_PER_MODULES;
            modulesInGPU->mdRanges[idx * 2 + 1] = (idx * N_MAX_MD_PER_MODULES) + mdsInGPU->nMDs[idx] - 1;

            if(modulesInGPU->subdets[idx] == Barrel)
            {
                n_minidoublets_by_layer_barrel_[modulesInGPU->layers[idx] -1] += mdsInGPU->nMDs[idx];
            }
            else
            {
                n_minidoublets_by_layer_endcap_[modulesInGPU->layers[idx] - 1] += mdsInGPU->nMDs[idx];
            }

        }
    }
}
void SDL::Event::addMiniDoubletsToEventExplicit()
{
unsigned int nLowerModules;
cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
unsigned int* nMDsCPU;
cudaMallocHost(&nMDsCPU, nModules * sizeof(unsigned int));
cudaMemcpy(nMDsCPU,mdsInGPU->nMDs,nModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);

short* module_subdets;
cudaMallocHost(&module_subdets, nModules* sizeof(short));
cudaMemcpy(module_subdets,modulesInGPU->subdets,nModules*sizeof(short),cudaMemcpyDeviceToHost);
unsigned int* module_lowerModuleIndices;
cudaMallocHost(&module_lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
cudaMemcpy(module_lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);
int* module_mdRanges;
cudaMallocHost(&module_mdRanges, nModules* 2*sizeof(int));
cudaMemcpy(module_mdRanges,modulesInGPU->mdRanges,nModules*2*sizeof(int),cudaMemcpyDeviceToHost);
short* module_layers;
cudaMallocHost(&module_layers, nModules * sizeof(short));
cudaMemcpy(module_layers,modulesInGPU->layers,nModules*sizeof(short),cudaMemcpyDeviceToHost);
int* module_hitRanges;
cudaMallocHost(&module_hitRanges, nModules* 2*sizeof(int));
cudaMemcpy(module_hitRanges,modulesInGPU->hitRanges,nModules*2*sizeof(int),cudaMemcpyDeviceToHost);

    unsigned int idx;
    for(unsigned int i = 0; i<nLowerModules; i++)
    {
        idx = module_lowerModuleIndices[i];
        if(nMDsCPU[idx] == 0 or module_hitRanges[idx * 2] == -1)
        {
            module_mdRanges[idx * 2] = -1;
            module_mdRanges[idx * 2 + 1] = -1;
        }
        else
        {
            module_mdRanges[idx * 2] = idx * N_MAX_MD_PER_MODULES;
            module_mdRanges[idx * 2 + 1] = (idx * N_MAX_MD_PER_MODULES) + nMDsCPU[idx] - 1;

            if(module_subdets[idx] == Barrel)
            {
                n_minidoublets_by_layer_barrel_[module_layers[idx] -1] += nMDsCPU[idx];
            }
            else
            {
                n_minidoublets_by_layer_endcap_[module_layers[idx] - 1] += nMDsCPU[idx];
            }

        }
    }
cudaMemcpy(modulesInGPU->mdRanges,module_mdRanges,nModules*2*sizeof(int),cudaMemcpyHostToDevice);
cudaFreeHost(nMDsCPU);
cudaFreeHost(module_subdets);
cudaFreeHost(module_lowerModuleIndices);
cudaFreeHost(module_mdRanges);
cudaFreeHost(module_layers);
cudaFreeHost(module_hitRanges);
}

void SDL::Event::addSegmentsToEvent()
{
    unsigned int idx;
    for(unsigned int i = 0; i<*(SDL::modulesInGPU->nLowerModules); i++)
    {
        idx = SDL::modulesInGPU->lowerModuleIndices[i];
        if(segmentsInGPU->nSegments[idx] == 0)
        {
            modulesInGPU->segmentRanges[idx * 2] = -1;
            modulesInGPU->segmentRanges[idx * 2 + 1] = -1;
        }
        else
        {
            modulesInGPU->segmentRanges[idx * 2] = idx * N_MAX_SEGMENTS_PER_MODULE;
            modulesInGPU->segmentRanges[idx * 2 + 1] = idx * N_MAX_SEGMENTS_PER_MODULE + segmentsInGPU->nSegments[idx] - 1;

            if(modulesInGPU->subdets[idx] == Barrel)
            {

                n_segments_by_layer_barrel_[modulesInGPU->layers[idx] - 1] += segmentsInGPU->nSegments[idx];
            }
            else
            {
                n_segments_by_layer_endcap_[modulesInGPU->layers[idx] -1] += segmentsInGPU->nSegments[idx];
            }
        }
    }
}
void SDL::Event::addSegmentsToEventExplicit()
{
unsigned int nLowerModules;
cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

unsigned int* nSegmentsCPU;
cudaMallocHost(&nSegmentsCPU, nModules * sizeof(unsigned int));
cudaMemcpy(nSegmentsCPU,segmentsInGPU->nSegments,nModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);

short* module_subdets;
cudaMallocHost(&module_subdets, nModules* sizeof(short));
cudaMemcpy(module_subdets,modulesInGPU->subdets,nModules*sizeof(short),cudaMemcpyDeviceToHost);
unsigned int* module_lowerModuleIndices;
cudaMallocHost(&module_lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
cudaMemcpy(module_lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);
int* module_segmentRanges;
cudaMallocHost(&module_segmentRanges, nModules* 2*sizeof(int));
cudaMemcpy(module_segmentRanges,modulesInGPU->segmentRanges,nModules*2*sizeof(int),cudaMemcpyDeviceToHost);
short* module_layers;
cudaMallocHost(&module_layers, nModules * sizeof(short));
cudaMemcpy(module_layers,modulesInGPU->layers,nModules*sizeof(short),cudaMemcpyDeviceToHost);
    unsigned int idx;
    for(unsigned int i = 0; i<nLowerModules; i++)
    {
        idx = module_lowerModuleIndices[i];
        if(nSegmentsCPU[idx] == 0)
        {
            module_segmentRanges[idx * 2] = -1;
            module_segmentRanges[idx * 2 + 1] = -1;
        }
        else
        {
            module_segmentRanges[idx * 2] = idx * N_MAX_SEGMENTS_PER_MODULE;
            module_segmentRanges[idx * 2 + 1] = idx * N_MAX_SEGMENTS_PER_MODULE + nSegmentsCPU[idx] - 1;

            if(module_subdets[idx] == Barrel)
            {

                n_segments_by_layer_barrel_[module_layers[idx] - 1] += nSegmentsCPU[idx];
            }
            else
            {
                n_segments_by_layer_endcap_[module_layers[idx] -1] += nSegmentsCPU[idx];
            }
        }
    }
cudaFreeHost(nSegmentsCPU);
cudaFreeHost(module_subdets);
cudaFreeHost(module_lowerModuleIndices);
cudaFreeHost(module_segmentRanges);
cudaFreeHost(module_layers);
}

void SDL::Event::createMiniDoublets()
{
    cudaDeviceSynchronize();
    auto memStart = std::chrono::high_resolution_clock::now();
    if(mdsInGPU == nullptr)
    {
        cudaMallocHost(&mdsInGPU, sizeof(SDL::miniDoublets));
#ifdef Explicit_MD
        //FIXME: Add memory locations for pixel MDs
    	createMDsInExplicitMemory(*mdsInGPU, N_MAX_MD_PER_MODULES, nModules, N_MAX_PIXEL_MD_PER_MODULES);
#else
    	createMDsInUnifiedMemory(*mdsInGPU, N_MAX_MD_PER_MODULES, nModules, N_MAX_PIXEL_MD_PER_MODULES);
#endif
    }
    cudaDeviceSynchronize();
    auto memStop = std::chrono::high_resolution_clock::now();
    auto memDuration = std::chrono::duration_cast<std::chrono::milliseconds>(memStop - memStart); //in milliseconds

    unsigned int nLowerModules;
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

#ifdef NESTED_PARA
    int nThreads = 1;
    int nBlocks = nLowerModules % nThreads == 0 ? nLowerModules/nThreads : nLowerModules/nThreads + 1;
#else
#ifdef NEWGRID_MD
    int maxThreadsPerModule=0;
    #ifdef Explicit_Module
    unsigned int* module_lowerModuleIndices;
    cudaMallocHost(&module_lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
    cudaMemcpy(module_lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    int* module_hitRanges;
    cudaMallocHost(&module_hitRanges, nModules* 2*sizeof(int));
    cudaMemcpy(module_hitRanges,modulesInGPU->hitRanges,nModules*2*sizeof(int),cudaMemcpyDeviceToHost);
    bool* module_isLower;
    cudaMallocHost(&module_isLower, nModules*sizeof(bool));
    cudaMemcpy(module_isLower,modulesInGPU->isLower,nModules*sizeof(bool),cudaMemcpyDeviceToHost);
    bool* module_isInverted;
    cudaMallocHost(&module_isInverted, nModules*sizeof(bool));
    cudaMemcpy(module_isInverted,modulesInGPU->isInverted,nModules*sizeof(bool),cudaMemcpyDeviceToHost);

    for (int i=0; i<nLowerModules; i++) {
      int lowerModuleIndex = module_lowerModuleIndices[i];
      int upperModuleIndex = modulesInGPU->partnerModuleIndexExplicit(lowerModuleIndex,module_isLower[lowerModuleIndex],module_isInverted[lowerModuleIndex]);
      int lowerHitRanges = module_hitRanges[lowerModuleIndex*2];
      int upperHitRanges = module_hitRanges[upperModuleIndex*2];
      if(lowerHitRanges!=-1&&upperHitRanges!=-1) {
        unsigned int nLowerHits = module_hitRanges[lowerModuleIndex * 2 + 1] - lowerHitRanges + 1;
        unsigned int nUpperHits = module_hitRanges[upperModuleIndex * 2 + 1] - upperHitRanges + 1;
        maxThreadsPerModule = maxThreadsPerModule > (nLowerHits*nUpperHits) ? maxThreadsPerModule : nLowerHits*nUpperHits;
      }
    }
    cudaFreeHost(module_lowerModuleIndices);
    cudaFreeHost(module_hitRanges);
    cudaFreeHost(module_isLower);
    cudaFreeHost(module_isInverted);
    #else
    //int maxThreadsPerModule=0;
    for (int i=0; i<nLowerModules; i++) {
      int lowerModuleIndex = modulesInGPU->lowerModuleIndices[i];
      int upperModuleIndex = modulesInGPU->partnerModuleIndex(lowerModuleIndex);
      int lowerHitRanges = modulesInGPU->hitRanges[lowerModuleIndex*2];
      int upperHitRanges = modulesInGPU->hitRanges[upperModuleIndex*2];
      if(lowerHitRanges!=-1&&upperHitRanges!=-1) {
        unsigned int nLowerHits = modulesInGPU->hitRanges[lowerModuleIndex * 2 + 1] - lowerHitRanges + 1;
        unsigned int nUpperHits = modulesInGPU->hitRanges[upperModuleIndex * 2 + 1] - upperHitRanges + 1;
        maxThreadsPerModule = maxThreadsPerModule > (nLowerHits*nUpperHits) ? maxThreadsPerModule : nLowerHits*nUpperHits;
      }
    }
    #endif
    //printf("maxThreadsPerModule=%d\n", maxThreadsPerModule);
    dim3 nThreads(1,128);
    dim3 nBlocks((nLowerModules % nThreads.x == 0 ? nLowerModules/nThreads.x : nLowerModules/nThreads.x + 1), (maxThreadsPerModule % nThreads.y == 0 ? maxThreadsPerModule/nThreads.y : maxThreadsPerModule/nThreads.y + 1));
#else
    dim3 nThreads(1,16,16);
    dim3 nBlocks((nLowerModules % nThreads.x == 0 ? nLowerModules/nThreads.x : nLowerModules/nThreads.x + 1),(N_MAX_HITS_PER_MODULE % nThreads.y == 0 ? N_MAX_HITS_PER_MODULE/nThreads.y : N_MAX_HITS_PER_MODULE/nThreads.y + 1), (N_MAX_HITS_PER_MODULE % nThreads.z == 0 ? N_MAX_HITS_PER_MODULE/nThreads.z : N_MAX_HITS_PER_MODULE/nThreads.z + 1));
#endif
#endif

    cudaDeviceSynchronize();
    auto syncStart = std::chrono::high_resolution_clock::now();

    createMiniDoubletsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU,*hitsInGPU,*mdsInGPU);

    cudaError_t cudaerr = cudaDeviceSynchronize();
    auto syncStop = std::chrono::high_resolution_clock::now();

    auto syncDuration =  std::chrono::duration_cast<std::chrono::milliseconds>(syncStop - syncStart);

    if(cudaerr != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
    }

#if defined(AddObjects)
#ifdef Explicit_MD
    addMiniDoubletsToEventExplicit();
#else
    addMiniDoubletsToEvent();
#endif
#endif


}

void SDL::Event::createSegmentsWithModuleMap()
{
    if(segmentsInGPU == nullptr)
    {
        cudaMallocHost(&segmentsInGPU, sizeof(SDL::segments));
#ifdef Explicit_Seg
        createSegmentsInExplicitMemory(*segmentsInGPU, N_MAX_SEGMENTS_PER_MODULE, nModules, N_MAX_PIXEL_SEGMENTS_PER_MODULE);
#else
        createSegmentsInUnifiedMemory(*segmentsInGPU, N_MAX_SEGMENTS_PER_MODULE, nModules, N_MAX_PIXEL_SEGMENTS_PER_MODULE);
#endif
    }
    unsigned int nLowerModules;
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

#ifdef NESTED_PARA
    unsigned int nThreads = 1;
    unsigned int nBlocks = nLowerModules % nThreads == 0 ? nLowerModules/nThreads : nLowerModules/nThreads + 1;
#else
#ifdef NEWGRID_Seg
    int max_cModules=0;
    int sq_max_nMDs = 0;
    int nonZeroModules = 0;
  #ifdef Explicit_Module
    unsigned int nModules;
    cudaMemcpy(&nModules,modulesInGPU->nModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
    unsigned int* nMDs = (unsigned int*)malloc(nModules*sizeof(unsigned int));
    cudaMemcpy((void *)nMDs, mdsInGPU->nMDs, nModules*sizeof(unsigned int), cudaMemcpyDeviceToHost);

    unsigned int* module_lowerModuleIndices;
    cudaMallocHost(&module_lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
    cudaMemcpy(module_lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    unsigned int* module_nConnectedModules;
    cudaMallocHost(&module_nConnectedModules, nModules* sizeof(unsigned int));
    cudaMemcpy(module_nConnectedModules,modulesInGPU->nConnectedModules,nModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    unsigned int* module_moduleMap;
    cudaMallocHost(&module_moduleMap, nModules*40* sizeof(unsigned int));
    cudaMemcpy(module_moduleMap,modulesInGPU->moduleMap,nModules*40*sizeof(unsigned int),cudaMemcpyDeviceToHost);

    for (int i=0; i<nLowerModules; i++) {
      unsigned int innerLowerModuleIndex = module_lowerModuleIndices[i];
      unsigned int nConnectedModules = module_nConnectedModules[innerLowerModuleIndex];
      unsigned int nInnerMDs = nMDs[innerLowerModuleIndex];
      max_cModules = max_cModules > nConnectedModules ? max_cModules : nConnectedModules;
      int limit_local = 0;
      if (nConnectedModules!=0) nonZeroModules++;
      for (int j=0; j<nConnectedModules; j++) {
        int outerLowerModuleIndex = module_moduleMap[innerLowerModuleIndex * MAX_CONNECTED_MODULES + j];
        int nOuterMDs = nMDs[outerLowerModuleIndex];
        int total = nInnerMDs*nOuterMDs;
        limit_local = limit_local > total ? limit_local : total;
      }
      sq_max_nMDs = sq_max_nMDs > limit_local ? sq_max_nMDs : limit_local;
    }
    cudaFreeHost(module_lowerModuleIndices);
    cudaFreeHost(module_nConnectedModules);
    cudaFreeHost(module_moduleMap);
  #else

    unsigned int nModules = *modulesInGPU->nModules;
    unsigned int* nMDs = (unsigned int*)malloc(nModules*sizeof(unsigned int));
    cudaMemcpy((void *)nMDs, mdsInGPU->nMDs, nModules*sizeof(unsigned int), cudaMemcpyDeviceToHost);
    for (int i=0; i<nLowerModules; i++) {
      unsigned int innerLowerModuleIndex = modulesInGPU->lowerModuleIndices[i];
      unsigned int nConnectedModules = modulesInGPU->nConnectedModules[innerLowerModuleIndex];
      unsigned int nInnerMDs = nMDs[innerLowerModuleIndex] > N_MAX_MD_PER_MODULES ? N_MAX_MD_PER_MODULES : nMDs[innerLowerModuleIndex];
      max_cModules = max_cModules > nConnectedModules ? max_cModules : nConnectedModules;
      int limit_local = 0;
      if (nConnectedModules!=0) nonZeroModules++;
      for (int j=0; j<nConnectedModules; j++) {
        int outerLowerModuleIndex = modulesInGPU->moduleMap[innerLowerModuleIndex * MAX_CONNECTED_MODULES + j];
        int nOuterMDs = nMDs[outerLowerModuleIndex] > N_MAX_MD_PER_MODULES ? N_MAX_MD_PER_MODULES : nMDs[outerLowerModuleIndex];
        int total = nInnerMDs*nOuterMDs;
        limit_local = limit_local > total ? limit_local : total;
      }
      sq_max_nMDs = sq_max_nMDs > limit_local ? sq_max_nMDs : limit_local;
    }
  #endif
    //printf("max nConnectedModules=%d nonZeroModules=%d max sq_max_nMDs=%d\n", max_cModules, nonZeroModules, sq_max_nMDs);
    dim3 nThreads(256,1,1);
    dim3 nBlocks((sq_max_nMDs%nThreads.x==0 ? sq_max_nMDs/nThreads.x : sq_max_nMDs/nThreads.x + 1), (max_cModules%nThreads.y==0 ? max_cModules/nThreads.y : max_cModules/nThreads.y + 1), (nLowerModules%nThreads.z==0 ? nLowerModules/nThreads.z : nLowerModules/nThreads.z + 1));
    free(nMDs);
#else
    dim3 nThreads(1,16,16);
    dim3 nBlocks(((nLowerModules * MAX_CONNECTED_MODULES)  % nThreads.x == 0 ? (nLowerModules * MAX_CONNECTED_MODULES)/nThreads.x : (nLowerModules * MAX_CONNECTED_MODULES)/nThreads.x + 1),(N_MAX_MD_PER_MODULES % nThreads.y == 0 ? N_MAX_MD_PER_MODULES/nThreads.y : N_MAX_MD_PER_MODULES/nThreads.y + 1), (N_MAX_MD_PER_MODULES % nThreads.z == 0  ? N_MAX_MD_PER_MODULES/nThreads.z : N_MAX_MD_PER_MODULES/nThreads.z + 1));
#endif
#endif

    createSegmentsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU);

    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
    }
#if defined(AddObjects)
#ifdef Explicit_Seg
    addSegmentsToEventExplicit();
#else
    addSegmentsToEvent();
#endif
#endif

}


void SDL::Event::createTriplets()
{
    unsigned int nLowerModules;
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

    if(tripletsInGPU == nullptr)
    {
        cudaMallocHost(&tripletsInGPU, sizeof(SDL::triplets));
#ifdef Explicit_Trips
        createTripletsInExplicitMemory(*tripletsInGPU, N_MAX_TRIPLETS_PER_MODULE, nLowerModules);
#else
        createTripletsInUnifiedMemory(*tripletsInGPU, N_MAX_TRIPLETS_PER_MODULE, nLowerModules);
#endif
    }

#ifdef NESTED_PARA
    unsigned int nThreads = 1;
    unsigned int nBlocks = nLowerModules % nThreads == 0 ? nLowerModules/nThreads : nLowerModules/nThreads + 1;

    createTripletsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *tripletsInGPU);
    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
      {
	std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
      }
#else
#ifdef NEWGRID_Trips
  #ifdef Explicit_Module
    unsigned int nonZeroModules=0;
    unsigned int max_InnerSeg=0;
    unsigned int *index = (unsigned int*)malloc(nLowerModules*sizeof(unsigned int));
    unsigned int *index_gpu;
    cudaMalloc((void **)&index_gpu, nLowerModules*sizeof(unsigned int));
    //unsigned int nModules = *modulesInGPU->nModules;
    unsigned int *nSegments = (unsigned int*)malloc(nModules*sizeof(unsigned int));
    cudaMemcpy((void *)nSegments, segmentsInGPU->nSegments, nModules*sizeof(unsigned int), cudaMemcpyDeviceToHost);
    unsigned int* module_lowerModuleIndices;
    cudaMallocHost(&module_lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
    cudaMemcpy(module_lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    unsigned int* module_nConnectedModules;
    cudaMallocHost(&module_nConnectedModules, nModules* sizeof(unsigned int));
    cudaMemcpy(module_nConnectedModules,modulesInGPU->nConnectedModules,nModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    for (int i=0; i<nLowerModules; i++) {
      unsigned int innerLowerModuleIndex = module_lowerModuleIndices[i];
      unsigned int nConnectedModules = module_nConnectedModules[innerLowerModuleIndex];
      unsigned int nInnerSegments = nSegments[innerLowerModuleIndex];
      if (nConnectedModules!=0&&nInnerSegments!=0) {
        index[nonZeroModules] = i;
        nonZeroModules++;
      }
      max_InnerSeg = max_InnerSeg > nInnerSegments ? max_InnerSeg : nInnerSegments;
    }
    cudaFreeHost(module_lowerModuleIndices);
    cudaFreeHost(module_nConnectedModules);
  #else
    unsigned int nonZeroModules=0;
    unsigned int max_InnerSeg=0;
    unsigned int *index = (unsigned int*)malloc(nLowerModules*sizeof(unsigned int));
    unsigned int *index_gpu;
    cudaMalloc((void **)&index_gpu, nLowerModules*sizeof(unsigned int));
    unsigned int nModules = *modulesInGPU->nModules;
    unsigned int *nSegments = (unsigned int*)malloc(nModules*sizeof(unsigned int));
    cudaMemcpy((void *)nSegments, segmentsInGPU->nSegments, nModules*sizeof(unsigned int), cudaMemcpyDeviceToHost);
    for (int i=0; i<nLowerModules; i++) {
      unsigned int innerLowerModuleIndex = modulesInGPU->lowerModuleIndices[i];
      unsigned int nConnectedModules = modulesInGPU->nConnectedModules[innerLowerModuleIndex];
      unsigned int nInnerSegments = nSegments[innerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : nSegments[innerLowerModuleIndex];
      if (nConnectedModules!=0&&nInnerSegments!=0) {
        index[nonZeroModules] = i;
        nonZeroModules++;
      }
      max_InnerSeg = max_InnerSeg > nInnerSegments ? max_InnerSeg : nInnerSegments;
    }
  #endif
    cudaMemcpy(index_gpu, index, nonZeroModules*sizeof(unsigned int), cudaMemcpyHostToDevice);
    int max_OuterSeg = 0;
    max_OuterSeg = N_MAX_SEGMENTS_PER_MODULE;
    dim3 nThreads(16,16,1);
    dim3 nBlocks((max_OuterSeg % nThreads.x == 0 ? max_OuterSeg / nThreads.x : max_OuterSeg / nThreads.x + 1),(max_InnerSeg % nThreads.y == 0 ? max_InnerSeg/nThreads.y : max_InnerSeg/nThreads.y + 1), (nonZeroModules % nThreads.z == 0 ? nonZeroModules/nThreads.z : nonZeroModules/nThreads.z + 1));
    createTripletsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *tripletsInGPU, index_gpu);
    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
      {
	std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
      }
    free(nSegments);
    free(index);
    cudaFree(index_gpu);
#else
    printf("original 3D grid launching in createTriplets does not exist");
    exit(1);
#endif
#endif

#if defined(AddObjects)
#ifdef Explicit_Trips
    addTripletsToEventExplicit();
#else
    addTripletsToEvent();
#endif
#endif
}

void SDL::Event::createTrackletsWithModuleMap()
{
    unsigned int nLowerModules;// = *modulesInGPU->nLowerModules;
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

    //TRCAKLETS - To conserve memory, we shall be only declaring nLowerModules amount of memory!!!!!!!
    if(trackletsInGPU == nullptr)
    {
        cudaMallocHost(&trackletsInGPU, sizeof(SDL::tracklets));
#ifdef Explicit_Tracklet
        //FIXME:Add memory locations for pixel tracklets
        createTrackletsInExplicitMemory(*trackletsInGPU, N_MAX_TRACKLETS_PER_MODULE, nLowerModules);
#else
        createTrackletsInUnifiedMemory(*trackletsInGPU, N_MAX_TRACKLETS_PER_MODULE, nLowerModules);
#endif
    }

#ifdef NESTED_PARA
    unsigned int nThreads = 1;
    unsigned int nBlocks = nLowerModules % nThreads == 0 ? nLowerModules/nThreads : nLowerModules/nThreads + 1;

    #ifdef T4FromT3
      createTrackletsFromTriplets<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *tripletsInGPU, *trackletsInGPU);
    #else
      createTrackletsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *trackletsInGPU);
    #endif

    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
      {
	std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
      }
#else
#ifdef NEWGRID_Tracklet
  #ifdef T4FromT3
    int threadSize=230000;
    unsigned int *nTriplets = (unsigned int*)malloc((nLowerModules-1)*sizeof(unsigned int));
    unsigned int *threadIdx = (unsigned int*)malloc(2*threadSize*sizeof(unsigned int));
    unsigned int *threadIdx_offset = threadIdx+threadSize;
    unsigned int *threadIdx_gpu;
    unsigned int *threadIdx_gpu_offset;
    cudaMalloc((void **)&threadIdx_gpu, 2*threadSize*sizeof(unsigned int));
    threadIdx_gpu_offset = threadIdx_gpu + threadSize;
    cudaMemset(threadIdx_gpu, nLowerModules, threadSize*sizeof(unsigned int));
    cudaMemcpy(nTriplets, tripletsInGPU->nTriplets, (nLowerModules-1)*sizeof(unsigned int), cudaMemcpyDeviceToHost);
    unsigned int totalCand=0;
    for (int i=0; i< nLowerModules-1; i++) {
      unsigned int nInnerTriplets = nTriplets[i];
      if(nInnerTriplets > N_MAX_TRIPLETS_PER_MODULE)
        nInnerTriplets = N_MAX_TRIPLETS_PER_MODULE;
      if (nInnerTriplets !=0) {
        for (int k=0; k<nInnerTriplets; k++) {
          threadIdx[totalCand+k] = i;
          threadIdx_offset[totalCand+k] = k;
        }
        totalCand += nInnerTriplets;
      }
    }
    cudaMemcpy(threadIdx_gpu, threadIdx, threadSize*sizeof(unsigned int), cudaMemcpyHostToDevice);
    cudaMemcpy(threadIdx_gpu_offset, threadIdx_offset, threadSize*sizeof(unsigned int), cudaMemcpyHostToDevice);

    dim3 nThreads(16, 32, 1);
    dim3 nBlocks((N_MAX_TRIPLETS_PER_MODULE % nThreads.x == 0 ? N_MAX_TRIPLETS_PER_MODULE/nThreads.x : N_MAX_TRIPLETS_PER_MODULE/nThreads.x + 1), (totalCand % nThreads.y == 0 ? totalCand/nThreads.y : totalCand/nThreads.y + 1), 1);

    createTrackletsFromTriplets<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *tripletsInGPU, *trackletsInGPU,threadIdx_gpu,threadIdx_gpu_offset);
    free(threadIdx);
    cudaFree(threadIdx_gpu);
    free(nTriplets);

  #else
      int max_cModules = 0;
      int sq_max_segments = 0;
      int nonZeroSegModules = 0;
      int inner_max_segments = 0;
      int outer_max_segments = 0;
      unsigned int *index_gpu;
      unsigned int *outerLowerModuleIndices = (unsigned int*)malloc(nModules*N_MAX_SEGMENTS_PER_MODULE*sizeof(unsigned int));
      unsigned int *nSegments = (unsigned int*)malloc(nModules*sizeof(unsigned int));
      unsigned int *index = (unsigned int*)malloc(nLowerModules*sizeof(unsigned int));
      cudaMalloc((void **)&index_gpu, nLowerModules*sizeof(unsigned int));
    #ifdef Explicit_Module
      cudaMemcpy((void *)outerLowerModuleIndices, segmentsInGPU->outerLowerModuleIndices, nModules*N_MAX_SEGMENTS_PER_MODULE*sizeof(unsigned int), cudaMemcpyDeviceToHost);
      cudaMemcpy((void *)nSegments, segmentsInGPU->nSegments, nModules*sizeof(unsigned int), cudaMemcpyDeviceToHost);
      unsigned int* module_lowerModuleIndices;
      cudaMallocHost(&module_lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
      cudaMemcpy(module_lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);
      unsigned int* module_nConnectedModules;
      cudaMallocHost(&module_nConnectedModules, nModules* sizeof(unsigned int));
      cudaMemcpy(module_nConnectedModules,modulesInGPU->nConnectedModules,nModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);
      unsigned int* module_moduleMap;
      cudaMallocHost(&module_moduleMap, nModules*40* sizeof(unsigned int));
      cudaMemcpy(module_moduleMap,modulesInGPU->moduleMap,nModules*40*sizeof(unsigned int),cudaMemcpyDeviceToHost);
      for (int i=0; i<nLowerModules; i++) {
        unsigned int innerInnerLowerModuleIndex = module_lowerModuleIndices[i];
        unsigned int nInnerSegments = nSegments[innerInnerLowerModuleIndex];
        if (nInnerSegments!=0) {
          index[nonZeroSegModules] = i;
          nonZeroSegModules++;
        }
        inner_max_segments = inner_max_segments > nInnerSegments ? inner_max_segments : nInnerSegments;

        for (int j=0; j<nInnerSegments; j++) {
          unsigned int innerSegmentIndex = innerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + j;
          unsigned int innerOuterLowerModuleIndex = outerLowerModuleIndices[innerSegmentIndex];
          unsigned int nOuterInnerLowerModules = module_nConnectedModules[innerOuterLowerModuleIndex];
          max_cModules = max_cModules > nOuterInnerLowerModules ? max_cModules : nOuterInnerLowerModules;
          for (int k=0; k<nOuterInnerLowerModules; k++) {
            unsigned int outerInnerLowerModuleIndex = module_moduleMap[innerOuterLowerModuleIndex * MAX_CONNECTED_MODULES + k];
            unsigned int nOuterSegments = nSegments[outerInnerLowerModuleIndex];
            sq_max_segments = sq_max_segments > nInnerSegments*nOuterSegments ? sq_max_segments : nInnerSegments*nOuterSegments;
          }
        }
      }
      cudaFreeHost(module_lowerModuleIndices);
      cudaFreeHost(module_nConnectedModules);
      cudaFreeHost(module_moduleMap);
    #else
      //unsigned int nModules = *modulesInGPU->nModules;
      cudaMemcpy((void *)outerLowerModuleIndices, segmentsInGPU->outerLowerModuleIndices, nModules*N_MAX_SEGMENTS_PER_MODULE*sizeof(unsigned int), cudaMemcpyDeviceToHost);
      cudaMemcpy((void *)nSegments, segmentsInGPU->nSegments, nModules*sizeof(unsigned int), cudaMemcpyDeviceToHost);
      for (int i=0; i<nLowerModules; i++) {
        unsigned int innerInnerLowerModuleIndex = modulesInGPU->lowerModuleIndices[i];
        unsigned int nInnerSegments = nSegments[innerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE  ? N_MAX_SEGMENTS_PER_MODULE : nSegments[innerInnerLowerModuleIndex];
        if (nInnerSegments!=0) {
          index[nonZeroSegModules] = i;
          nonZeroSegModules++;
        }
        inner_max_segments = inner_max_segments > nInnerSegments ? inner_max_segments : nInnerSegments;

        for (int j=0; j<nInnerSegments; j++) {
          unsigned int innerSegmentIndex = innerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + j;
          unsigned int innerOuterLowerModuleIndex = outerLowerModuleIndices[innerSegmentIndex];
          unsigned int nOuterInnerLowerModules = modulesInGPU->nConnectedModules[innerOuterLowerModuleIndex];
          max_cModules = max_cModules > nOuterInnerLowerModules ? max_cModules : nOuterInnerLowerModules;
          for (int k=0; k<nOuterInnerLowerModules; k++) {
            unsigned int outerInnerLowerModuleIndex = modulesInGPU->moduleMap[innerOuterLowerModuleIndex * MAX_CONNECTED_MODULES + k];
            unsigned int nOuterSegments = nSegments[outerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : nSegments[outerInnerLowerModuleIndex];
            sq_max_segments = sq_max_segments > nInnerSegments*nOuterSegments ? sq_max_segments : nInnerSegments*nOuterSegments;
          }
        }
      }
    #endif
    cudaMemcpy(index_gpu, index, nonZeroSegModules*sizeof(unsigned int), cudaMemcpyHostToDevice);

    dim3 nThreads(128,1,1);
    dim3 nBlocks((sq_max_segments%nThreads.x==0 ? sq_max_segments/nThreads.x : sq_max_segments/nThreads.x + 1), (max_cModules%nThreads.y==0 ? max_cModules/nThreads.y : max_cModules/nThreads.y + 1), (nonZeroSegModules%nThreads.z==0 ? nonZeroSegModules/nThreads.z : nonZeroSegModules/nThreads.z + 1));

    createTrackletsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *trackletsInGPU, index_gpu);
    free(outerLowerModuleIndices);
    free(nSegments);
    free(index);
    cudaFree(index_gpu);
  #endif
    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
      {
	std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
      }


#else
    printf("original 3D grid launching in createTracklets does not exist");
    exit(1);
#endif
#endif
#if defined(AddObjects)
#ifdef Explicit_Tracklet
    addTrackletsToEventExplicit();
#else
    addTrackletsToEvent();
#endif
#endif

}

void SDL::Event::createPixelTrackletsWithMap()
{
    if(pixelTrackletsInGPU == nullptr)
    {
        cudaMallocHost(&pixelTrackletsInGPU, sizeof(SDL::pixelTracklets));
#ifdef Explicit_Tracklet
        createPixelTrackletsInExplicitMemory(*pixelTrackletsInGPU, N_MAX_PIXEL_TRACKLETS_PER_MODULE);
#else
        createPixelTrackletsInUnifiedMemory(*pixelTrackletsInGPU, N_MAX_PIXEL_TRACKLETS_PER_MODULE);
#endif
    }
    unsigned int nLowerModules;
    cudaMemcpy(&nLowerModules, modulesInGPU->nLowerModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);
#ifdef NESTED_PARA
    unsigned int nThreads = 1;
    unsigned int nBlocks = nLowerModules % nThreads == 0 ? nLowerModules/nThreads : nLowerModules/nThreads + 1;

    createPixelTrackletsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *pixelTrackletsInGPU);

    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;

    }
#else
#ifdef NEWGRID_Pixel
    unsigned int pixelModuleIndex;
    unsigned int nInnerSegments;
    int* superbins;
    int* pixelTypes;
#ifdef Explicit_Module
    unsigned int nModules;
    cudaMemcpy(&nModules,modulesInGPU->nModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
    pixelModuleIndex = nModules-1;
    unsigned int* nSegments;
    cudaMallocHost(& nSegments,nModules*sizeof(unsigned int));
    cudaMemcpy(nSegments,segmentsInGPU->nSegments,nModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    nInnerSegments = nSegments[pixelModuleIndex] > N_MAX_PIXEL_SEGMENTS_PER_MODULE ? N_MAX_PIXEL_SEGMENTS_PER_MODULE : nSegments[pixelModuleIndex]; // number of pLS
    cudaMallocHost(& superbins,N_MAX_PIXEL_SEGMENTS_PER_MODULE*sizeof(int));
    cudaMallocHost(& pixelTypes,N_MAX_PIXEL_SEGMENTS_PER_MODULE*sizeof(int));
    cudaMemcpy(superbins,segmentsInGPU->superbin,N_MAX_PIXEL_SEGMENTS_PER_MODULE*sizeof(int),cudaMemcpyDeviceToHost);
    cudaMemcpy(pixelTypes,segmentsInGPU->pixelType,N_MAX_PIXEL_SEGMENTS_PER_MODULE*sizeof(int),cudaMemcpyDeviceToHost);

#else
    pixelModuleIndex = *modulesInGPU->nModules - 1; // pixel module index
    nInnerSegments = segmentsInGPU->nSegments[pixelModuleIndex] > N_MAX_PIXEL_SEGMENTS_PER_MODULE ? N_MAX_PIXEL_SEGMENTS_PER_MODULE : segmentsInGPU->nSegments[pixelModuleIndex]; // number of pLS
    superbins = segmentsInGPU->superbin;
    pixelTypes = segmentsInGPU->pixelType;
#endif
////////DUPs
float* etas;
float* phis;
float* pts;
    cudaMallocHost(&etas,N_MAX_PIXEL_SEGMENTS_PER_MODULE*sizeof(float));
    cudaMallocHost(&phis,N_MAX_PIXEL_SEGMENTS_PER_MODULE*sizeof(float));
    cudaMallocHost(&pts,N_MAX_PIXEL_SEGMENTS_PER_MODULE*sizeof(float));
    cudaMemcpy(etas,segmentsInGPU->eta,N_MAX_PIXEL_SEGMENTS_PER_MODULE*sizeof(float),cudaMemcpyDeviceToHost);
    cudaMemcpy(phis,segmentsInGPU->phi,N_MAX_PIXEL_SEGMENTS_PER_MODULE*sizeof(float),cudaMemcpyDeviceToHost);
    cudaMemcpy(pts,segmentsInGPU->ptIn,N_MAX_PIXEL_SEGMENTS_PER_MODULE*sizeof(float),cudaMemcpyDeviceToHost);

/////////
    unsigned int* connectedPixelSize_host;
    unsigned int* connectedPixelIndex_host;
    cudaMallocHost(&connectedPixelSize_host, nInnerSegments* sizeof(unsigned int));
    cudaMallocHost(&connectedPixelIndex_host, nInnerSegments* sizeof(unsigned int));
    unsigned int* connectedPixelSize_dev;
    unsigned int* connectedPixelIndex_dev;
    cudaMalloc(&connectedPixelSize_dev, nInnerSegments* sizeof(unsigned int));
    cudaMalloc(&connectedPixelIndex_dev, nInnerSegments* sizeof(unsigned int));
    unsigned int max_size =0;
    int threadSize = 1000000;
    unsigned int *segs_pix = (unsigned int*)malloc(2*threadSize*sizeof(unsigned int));
    unsigned int *segs_pix_offset = segs_pix+threadSize;
    unsigned int *segs_pix_gpu;
    unsigned int *segs_pix_gpu_offset;
    cudaMalloc((void **)&segs_pix_gpu, 2*threadSize*sizeof(unsigned int));
    segs_pix_gpu_offset = segs_pix_gpu + threadSize;
    cudaMemset(segs_pix_gpu, nInnerSegments, threadSize*sizeof(unsigned int)); // so if not set, it will pass in the kernel
    unsigned int totalSegs=0;
    int pixelIndexOffsetPos = pixelMapping->connectedPixelsIndex[44999];
    int pixelIndexOffsetNeg = pixelMapping->connectedPixelsIndexPos[44999] + pixelIndexOffsetPos;
    int i =-1;
    for (int ix=0; ix < nInnerSegments;ix++){// loop over # pLS
      int pixelType = pixelTypes[ix];// get pixel type for this pLS
      int superbin = superbins[ix]; //get superbin for this pixel
      if(superbin <0) {/*printf("bad neg %d\n",ix);*/continue;}
      if(superbin >=45000) {/*printf("bad pos %d %d %d\n",ix,superbin,pixelType);*/continue;}// skip any weird out of range values
      if(pixelType >2 || pixelType < 0){/*printf("bad pixel type %d %d\n",ix,pixelType);*/continue;}
/////////////////DUP
//    bool dup = false;
//    for (int jx=0; jx<ix; jx++){
//        float dEta = abs(etas[ix] - etas[jx]);
//        float dPhi = abs(phis[ix] - phis[jx]);
//        if(dPhi > M_PI){dPhi= dPhi - 2*M_PI;}
//        if( dEta> 0.0003){continue;}
//        if( dPhi > 0.0003){continue;}
//        //if(abs(pts[ix] - pts[jx])/pts[jx] > 0.3){continue;}
//        float dR2 = dEta*dEta + dPhi*dPhi; 
//        if(dR2 > 0.000000000){continue;}
//        //printf("dR2: %e %f %f \n",dR2,pts[ix],pts[jx]);
//        dup = true;
//        break;
//      }
//      if(dup){continue;}
///////////////////////
      i++;
      if(pixelType ==0){ // used pixel type to select correct size-index arrays
        connectedPixelSize_host[i]  = pixelMapping->connectedPixelsSizes[superbin]; //number of connected modules to this pixel
        connectedPixelIndex_host[i] = pixelMapping->connectedPixelsIndex[superbin];// index to get start of connected modules for this superbin in map
        for (int j=0; j < pixelMapping->connectedPixelsSizes[superbin]; j++){ // loop over modules from the size
          segs_pix[totalSegs+j] = i; // save the pixel index in array to be transfered to kernel
          segs_pix_offset[totalSegs+j] = j; // save this segment in array to be transfered to kernel
        }
        totalSegs += connectedPixelSize_host[i]; // increment counter
      if (pixelMapping->connectedPixelsSizes[superbin] > max_size){ max_size = pixelMapping->connectedPixelsSizes[superbin];} // set the maximum number of modules in a row
      }
      else if(pixelType ==1){
        connectedPixelSize_host[i] = pixelMapping->connectedPixelsSizesPos[superbin]; //number of pixel connected modules
        connectedPixelIndex_host[i] = pixelMapping->connectedPixelsIndexPos[superbin]+pixelIndexOffsetPos;// index to get start of connected pixel modules
        for (int j=0; j < pixelMapping->connectedPixelsSizesPos[superbin]; j++){
          segs_pix[totalSegs+j] = i;
          segs_pix_offset[totalSegs+j] = j;
        }
        totalSegs += connectedPixelSize_host[i];
      if (pixelMapping->connectedPixelsSizesPos[superbin]> max_size){ max_size = pixelMapping->connectedPixelsSizesPos[superbin];}
      }
      else if(pixelType ==2){
        connectedPixelSize_host[i] = pixelMapping->connectedPixelsSizesNeg[superbin]; //number of pixel connected modules
        connectedPixelIndex_host[i] =pixelMapping->connectedPixelsIndexNeg[superbin] + pixelIndexOffsetNeg;// index to get start of connected pixel modules
        for (int j=0; j < pixelMapping->connectedPixelsSizesNeg[superbin]; j++){
          segs_pix[totalSegs+j] = i;
          segs_pix_offset[totalSegs+j] = j;
        }
        totalSegs += connectedPixelSize_host[i];
      if (pixelMapping->connectedPixelsSizesNeg[superbin] > max_size){max_size = pixelMapping->connectedPixelsSizesNeg[superbin];}
      }
      else{continue;}
    }

    cudaMemcpy(connectedPixelSize_dev, connectedPixelSize_host, nInnerSegments*sizeof(unsigned int), cudaMemcpyHostToDevice);
    cudaMemcpy(connectedPixelIndex_dev, connectedPixelIndex_host, nInnerSegments*sizeof(unsigned int), cudaMemcpyHostToDevice);
    cudaMemcpy(segs_pix_gpu,segs_pix,threadSize*sizeof(unsigned int), cudaMemcpyHostToDevice);
    cudaMemcpy(segs_pix_gpu_offset,segs_pix_offset,threadSize*sizeof(unsigned int), cudaMemcpyHostToDevice);

    dim3 nThreads(32,16,1);
    dim3 nBlocks((totalSegs % nThreads.x == 0 ? totalSegs / nThreads.x : totalSegs / nThreads.x + 1),
                  (max_size % nThreads.y == 0 ? max_size/nThreads.y : max_size/nThreads.y + 1),1);
    createPixelTrackletsInGPUFromMap<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *pixelTrackletsInGPU,
    connectedPixelSize_dev,connectedPixelIndex_dev,i,segs_pix_gpu,segs_pix_gpu_offset);

    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
      {
	std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;

      }
    //dim3 nThreads_dup(32,32,1);
    //dim3 nBlocks_dup(16,16,1);
    dim3 nThreads_dup(1024,1,1); //about exhaustive
    dim3 nBlocks_dup(64,1,1);
    removeDupPixelTrackletsInGPUFromMap<<<nThreads_dup,nBlocks_dup>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *pixelTrackletsInGPU);
    //removeDupPixelTrackletsInGPUFromMap<<<1,1>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *pixelTrackletsInGPU,
    cudaDeviceSynchronize();

    cudaFreeHost(connectedPixelSize_host);
    cudaFreeHost(connectedPixelIndex_host);
    cudaFree(connectedPixelSize_dev);
    cudaFree(connectedPixelIndex_dev);
#ifdef Explicit_Module
    cudaFreeHost(nSegments);
    cudaFreeHost(superbins);
    cudaFreeHost(pixelTypes);
#endif
    free(segs_pix);
    cudaFree(segs_pix_gpu);

#else
    printf("original 3D grid launching in createPixelTracklets does not exist");
    exit(2);
#endif
#endif

    unsigned int nPixelTracklets;
    cudaMemcpy(&nPixelTracklets, &(pixelTrackletsInGPU->nPixelTracklets), sizeof(unsigned int), cudaMemcpyDeviceToHost);
}

void SDL::Event::createPixelTracklets()
{
    unsigned int nLowerModules;// = *modulesInGPU->nLowerModules;
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
    if(pixelTrackletsInGPU == nullptr)
    {
        cudaMallocHost(&pixelTrackletsInGPU, sizeof(SDL::pixelTracklets));
#ifdef Explicit_Tracklet
        createPixelTrackletsInExplicitMemory(*pixelTrackletsInGPU, N_MAX_PIXEL_TRACKLETS_PER_MODULE);
#else
        createPixelTrackletsInUnifiedMemory(*pixelTrackletsInGPU, N_MAX_PIXEL_TRACKLETS_PER_MODULE);
#endif
    }

#ifdef NESTED_PARA
    unsigned int nThreads = 1;
    unsigned int nBlocks = nLowerModules % nThreads == 0 ? nLowerModules/nThreads : nLowerModules/nThreads + 1;

    createPixelTrackletsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *pixelTrackletsInGPU);

    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;

    }
#else
#ifdef NEWGRID_Pixel
#ifdef Explicit_Module
    unsigned int nModules; //= *modulesInGPU->nModules;
    cudaMemcpy(&nModules,modulesInGPU->nModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
#else
    unsigned int nModules = *modulesInGPU->nModules;
#endif
    unsigned int *nSegments = (unsigned int*)malloc(nModules*sizeof(unsigned int));
    cudaMemcpy((void *)nSegments, segmentsInGPU->nSegments, nModules*sizeof(unsigned int), cudaMemcpyDeviceToHost);
    unsigned int pixelModuleIndex = nModules - 1;
    unsigned int nInnerSegments = nSegments[pixelModuleIndex] > N_MAX_PIXEL_SEGMENTS_PER_MODULE ? N_MAX_PIXEL_SEGMENTS_PER_MODULE : nSegments[pixelModuleIndex];
#ifdef Explicit_Module
    unsigned int* lowerModuleIndices;
    cudaMallocHost(&lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
    cudaMemcpy(lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);
#endif
    int threadSize = 100000;
    unsigned int *threadIdx = (unsigned int*)malloc(2*threadSize*sizeof(unsigned int));
    unsigned int *threadIdx_offset = threadIdx+threadSize;
    unsigned int *threadIdx_gpu;
    unsigned int *threadIdx_gpu_offset;
    cudaMalloc((void **)&threadIdx_gpu, 2*threadSize*sizeof(unsigned int));
    threadIdx_gpu_offset = threadIdx_gpu + threadSize;
    cudaMemset(threadIdx_gpu, nLowerModules, threadSize*sizeof(unsigned int));
    unsigned int totalCand=0;
    for (int i=0; i<nLowerModules; i++) {
#ifdef Explicit_Module
      unsigned int outerInnerLowerModuleIndex = lowerModuleIndices[i];
#else
      unsigned int outerInnerLowerModuleIndex = modulesInGPU->lowerModuleIndices[i];
#endif
      unsigned int nOuterSegments = nSegments[outerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : nSegments[outerInnerLowerModuleIndex];
      if (nOuterSegments!=0) {
	for (int k=0; k<nOuterSegments; k++) {
          threadIdx[totalCand+k] = i;
          threadIdx_offset[totalCand+k] = k;
        }
	totalCand += nOuterSegments;
      }
    }

    if (threadSize < totalCand) {
      printf("threadSize=%d totalCand=%d: increase buffer size for threadIdx in createPixelTracklets\n", threadSize, totalCand);
      exit(1);
    }

    cudaMemcpy(threadIdx_gpu, threadIdx, threadSize*sizeof(unsigned int), cudaMemcpyHostToDevice);
    cudaMemcpy(threadIdx_gpu_offset, threadIdx_offset, threadSize*sizeof(unsigned int), cudaMemcpyHostToDevice);

    dim3 nThreads(16,32,1);
    dim3 nBlocks((nInnerSegments % nThreads.x == 0 ? nInnerSegments / nThreads.x : nInnerSegments / nThreads.x + 1),(totalCand % nThreads.y == 0 ? totalCand/nThreads.y : totalCand/nThreads.y + 1), 1);
    createPixelTrackletsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *pixelTrackletsInGPU, threadIdx_gpu, threadIdx_gpu_offset);

    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
    {
    	std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
    }

    free(nSegments);
    free(threadIdx);
    cudaFree(threadIdx_gpu);
#ifdef Explicit_Module
    cudaFreeHost(lowerModuleIndices);
#endif

#else
    printf("original 3D grid launching in createPixelTracklets does not exist");
    exit(2);
#endif
#endif

    unsigned int nPixelTracklets;
    cudaMemcpy(&nPixelTracklets, &(pixelTrackletsInGPU->nPixelTracklets), sizeof(unsigned int), cudaMemcpyDeviceToHost);
#ifdef Warnings
    std::cout<<"number of pixel tracklets = "<<nPixelTracklets<<std::endl;
#endif
}

void SDL::Event::createTrackCandidates()
{
    unsigned int nLowerModules;// = *modulesInGPU->nLowerModules + 1; //including the pixel module
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
    nLowerModules += 1;// include the pixel module

    //construct the list of eligible modules
    unsigned int nEligibleModules = 0;
    createEligibleModulesListForTrackCandidates(*modulesInGPU, nEligibleModules, N_MAX_TRACK_CANDIDATES_PER_MODULE);

    if(trackCandidatesInGPU == nullptr)
    {
        cudaMallocHost(&trackCandidatesInGPU, sizeof(SDL::trackCandidates));
#ifdef Explicit_Track
        createTrackCandidatesInExplicitMemory(*trackCandidatesInGPU, N_MAX_TRACK_CANDIDATES_PER_MODULE, N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE, nLowerModules, nEligibleModules);
#else
        createTrackCandidatesInUnifiedMemory(*trackCandidatesInGPU, N_MAX_TRACK_CANDIDATES_PER_MODULE, N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE, nLowerModules, nEligibleModules);
#endif
    }

#ifdef FINAL_pT2
    printf("running final state pT2\n");
    unsigned int nThreadsx = 1;
    unsigned int nBlocksx = ( N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE) % nThreadsx == 0 ? N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE/nThreadsx : N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE/nThreadsx + 1;
    addpT2asTrackCandidateInGPU<<<nBlocksx,nThreadsx>>>(*modulesInGPU,*pixelTrackletsInGPU,*trackCandidatesInGPU);
    cudaError_t cudaerr_pT2 = cudaDeviceSynchronize();
    if(cudaerr_pT2 != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr_pT2)<<std::endl;
    }
#elif FINAL_pT3
    printf("running final state pT3\n");
    unsigned int nThreadsx = 1;
    unsigned int nBlocksx = (N_MAX_PIXEL_TRIPLETS) % nThreadsx == 0 ? N_MAX_PIXEL_TRIPLETS / nThreadsx : N_MAX_PIXEL_TRIPLETS / nThreadsx + 1;
    addpT3asTrackCandidateInGPU<<<nBlocksx, nThreadsx>>>(*modulesInGPU, *pixelTripletsInGPU, *trackCandidatesInGPU);
    cudaError_t cudaerr_pT3 = cudaDeviceSynchronize();
    if(cudaerr_pT3 != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr_pT3)<<std::endl;
    }
#endif // final state pT2 and pT3
#ifdef FINAL_T5
    printf("running final state T5\n");
    dim3 nThreads(32,16,1);
    dim3 nBlocks(((nLowerModules-1) % nThreads.x == 0 ? (nLowerModules-1)/nThreads.x : (nLowerModules-1)/nThreads.x + 1),((N_MAX_QUINTUPLETS_PER_MODULE-1) % nThreads.y == 0 ? (N_MAX_QUINTUPLETS_PER_MODULE-1)/nThreads.y : (N_MAX_QUINTUPLETS_PER_MODULE-1)/nThreads.y + 1),1);
    addT5asTrackCandidateInGPU<<<nBlocks,nThreads>>>(*modulesInGPU,*quintupletsInGPU,*trackCandidatesInGPU);

    cudaError_t cudaerr_T5 = cudaDeviceSynchronize();
    if(cudaerr_T5 != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr_T5)<<std::endl;
    }
#endif // final state T5



#ifdef FINAL_T3T4
    printf("running final state T3T4\n");
#ifdef NESTED_PARA
    //auto t0 = std::chrono::high_resolution_clock::now();
    unsigned int nThreads = 1;
    unsigned int nBlocks = (nLowerModules-1) % nThreads == 0 ? (nLowerModules-1)/nThreads : (nLowerModules-1)/nThreads + 1;

    createTrackCandidatesInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *trackletsInGPU, *tripletsInGPU, *trackCandidatesInGPU);

    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
    }

    //Pixel Track Candidates created separately
    nThreads = 1;
    nBlocks = (nLowerModules - 1) % nThreads == 0 ? (nLowerModules - 1)/nThreads : (nLowerModules - 1)/nThreads + 1;

    createPixelTrackCandidatesInGPU<<<nBlocks, nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *pixelTrackletsInGPU, *trackletsInGPU, *tripletsInGPU, *trackCandidatesInGPU);

    cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
    }
#else
#ifdef NEWGRID_Track
    //auto t0 = std::chrono::high_resolution_clock::now();
    int maxOuterTr = max(N_MAX_TRACKLETS_PER_MODULE, N_MAX_TRIPLETS_PER_MODULE);
    unsigned int *nTriplets = (unsigned int*)malloc((2*nLowerModules-1)*sizeof(unsigned int));
    //unsigned int *nTracklets = (unsigned int*)malloc(nLowerModules*sizeof(unsigned int));
    unsigned int *nTracklets = nTriplets + nLowerModules -1;
    //int threadSize=2300000;
    int threadSize=10000000;
    unsigned int *threadIdx = (unsigned int*)malloc(2*threadSize*sizeof(unsigned int));
    unsigned int *threadIdx_offset = threadIdx+threadSize;
    unsigned int *threadIdx_gpu;
    unsigned int *threadIdx_gpu_offset;
    cudaMalloc((void **)&threadIdx_gpu, 2*threadSize*sizeof(unsigned int));
    threadIdx_gpu_offset = threadIdx_gpu + threadSize;
    cudaMemset(threadIdx_gpu, nLowerModules, threadSize*sizeof(unsigned int));
    cudaMemcpy(nTriplets, tripletsInGPU->nTriplets, (nLowerModules-1)*sizeof(unsigned int), cudaMemcpyDeviceToHost);
    cudaMemcpy(nTracklets, trackletsInGPU->nTracklets, nLowerModules*sizeof(unsigned int), cudaMemcpyDeviceToHost);
    int nPixelTracklets;    
    cudaMemcpy(&nPixelTracklets, pixelTrackletsInGPU->nPixelTracklets, sizeof(unsigned int), cudaMemcpyDeviceToHost);
    if(nPixelTracklets > N_MAX_PIXEL_TRACKLETS_PER_MODULE)
      nPixelTracklets = N_MAX_PIXEL_TRACKLETS_PER_MODULE;
    unsigned int totalCand=0;
    for (int i=0; i< nLowerModules-1; i++) {
      unsigned int nInnerTracklets = nTracklets[i];
      if(nInnerTracklets > N_MAX_TRACKLETS_PER_MODULE)
	nInnerTracklets = N_MAX_TRACKLETS_PER_MODULE;
      unsigned int nInnerTriplets = nTriplets[i];
      if(nInnerTriplets > N_MAX_TRIPLETS_PER_MODULE)
        nInnerTriplets = N_MAX_TRIPLETS_PER_MODULE;
      unsigned int temp = max(nInnerTracklets, nInnerTriplets);
      if (temp !=0) {
        for (int k=0; k<temp; k++) {
          threadIdx[totalCand+k] = i;
          //printf("totalCand+k: %d\n",totalCand+k);
          threadIdx_offset[totalCand+k] = k;
        }
	totalCand += temp;
      }
    }
    if (threadSize < totalCand) {
      printf("threadSize=%d totalCand=%d: Increase buffer size for threadIdx in createTrackCandidates\n", threadSize, totalCand);
      exit(2);
    }
    cudaMemcpy(threadIdx_gpu, threadIdx, threadSize*sizeof(unsigned int), cudaMemcpyHostToDevice);
    cudaMemcpy(threadIdx_gpu_offset, threadIdx_offset, threadSize*sizeof(unsigned int), cudaMemcpyHostToDevice);

    dim3 nThreads(16, 32, 1);
    dim3 nBlocks((maxOuterTr % nThreads.x == 0 ? maxOuterTr/nThreads.x : maxOuterTr/nThreads.x + 1), (totalCand % nThreads.y == 0 ? totalCand/nThreads.y : totalCand/nThreads.y + 1), 1);
    createTrackCandidatesInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *trackletsInGPU, *tripletsInGPU, *trackCandidatesInGPU, threadIdx_gpu, threadIdx_gpu_offset);
    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
      {
	std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
      }
    dim3 nThreads_p(16,16,1);
    dim3 nBlocks_p((nPixelTracklets % nThreads_p.x == 0 ? nPixelTracklets/nThreads_p.x : nPixelTracklets/nThreads_p.x + 1), (totalCand % nThreads_p.y == 0 ? totalCand/nThreads_p.y : totalCand/nThreads_p.y + 1), 1);
    createPixelTrackCandidatesInGPU<<<nBlocks_p, nThreads_p>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *pixelTrackletsInGPU, *trackletsInGPU, *tripletsInGPU, *trackCandidatesInGPU, threadIdx_gpu, threadIdx_gpu_offset);
    cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
      {
	std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
      }

    free(threadIdx);
    free(nTriplets);
    cudaFree(threadIdx_gpu);
#else
    printf("original 3D grid launching in createTrackCandidates does not exist");
    exit(3);
#endif
#endif 
#endif // Final state T3+T4
    dim3 nThreads_dup(32, 32, 1);
    dim3 nBlocks_dup(16, 16, 1);
  removeDupTrackCandidates<<<nBlocks_dup,nThreads_dup>>>(*trackCandidatesInGPU,*modulesInGPU);
  //removeDupTrackCandidates<<<1,1>>>(*trackCandidatesInGPU,*modulesInGPU);
  cudaDeviceSynchronize();
#if defined(AddObjects)
#ifdef Explicit_Track
    addTrackCandidatesToEventExplicit();
#else
    addTrackCandidatesToEvent();
#endif
#endif

}

void SDL::Event::createPixelTriplets()
{
    unsigned int nLowerModules;
    cudaMemcpy(&nLowerModules, modulesInGPU->nLowerModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);

    if(pixelTripletsInGPU == nullptr)
    {
        cudaMallocHost(&pixelTripletsInGPU, sizeof(SDL::pixelTriplets));
    }
#ifdef Explicit_PT3
    createPixelTripletsInExplicitMemory(*pixelTripletsInGPU, N_MAX_PIXEL_TRIPLETS);
#else
    createPixelTripletsInUnifiedMemory(*pixelTripletsInGPU, N_MAX_PIXEL_TRIPLETS);
#endif

    unsigned int nThreads = 1;
    unsigned int nBlocks = nLowerModules % nThreads == 0 ? nLowerModules / nThreads : nLowerModules / nThreads + 1;

    createPixelTripletsInGPU<<<nBlocks, nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *tripletsInGPU, *pixelTripletsInGPU);

    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;

    }

    unsigned int nPixelTriplets;
    cudaMemcpy(&nPixelTriplets, &(pixelTripletsInGPU->nPixelTriplets),  sizeof(unsigned int), cudaMemcpyDeviceToHost);
#ifdef Warnings
    std::cout<<"number of pixel triplets = "<<nPixelTriplets<<std::endl;
#endif

}


void SDL::Event::createQuintuplets()
{
    unsigned int nLowerModules;
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

    unsigned int nEligibleT5Modules = 0;
    unsigned int *indicesOfEligibleModules = (unsigned int*)malloc(nLowerModules*sizeof(unsigned int));

    unsigned int maxTriplets;
    createEligibleModulesListForQuintuplets(*modulesInGPU, *tripletsInGPU, nEligibleT5Modules, indicesOfEligibleModules, N_MAX_QUINTUPLETS_PER_MODULE, maxTriplets);

    if(quintupletsInGPU == nullptr)
    {
        cudaMallocHost(&quintupletsInGPU, sizeof(SDL::quintuplets));
#ifdef Explicit_T5
        createQuintupletsInExplicitMemory(*quintupletsInGPU, N_MAX_QUINTUPLETS_PER_MODULE, nLowerModules, nEligibleT5Modules);
#else
        createQuintupletsInUnifiedMemory(*quintupletsInGPU, N_MAX_QUINTUPLETS_PER_MODULE, nLowerModules, nEligibleT5Modules);
#endif
    }


#ifdef NESTED_PARA
    unsigned int nThreads = 1;
    unsigned int nBlocks = nLowerModules % nThreads == 0 ? nLowerModules/nThreads : nLowerModules/nThreads + 1;
    createQuintupletsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *tripletsInGPU, *quintupletsInGPU);


    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
    {
	    std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
    }
#else
#ifdef NEWGRID_T5
    int threadSize=N_MAX_TOTAL_TRIPLETS;
    unsigned int *threadIdx = (unsigned int*)malloc(2*threadSize*sizeof(unsigned int));
    unsigned int *threadIdx_offset = threadIdx+threadSize;
    unsigned int *threadIdx_gpu;
    unsigned int *threadIdx_gpu_offset;
    cudaMalloc((void **)&threadIdx_gpu, 2*threadSize*sizeof(unsigned int));
    threadIdx_gpu_offset = threadIdx_gpu + threadSize;
    cudaMemset(threadIdx_gpu, nLowerModules, threadSize*sizeof(unsigned int));

    unsigned int *nTriplets = (unsigned int*)malloc(nLowerModules*sizeof(unsigned int));
    cudaMemcpy(nTriplets, tripletsInGPU->nTriplets, nLowerModules*sizeof(unsigned int), cudaMemcpyDeviceToHost);

    int nTotalTriplets = 0;
    for (int i=0; i<nEligibleT5Modules; i++) {
      int index = indicesOfEligibleModules[i];
      unsigned int nInnerTriplets = nTriplets[index];
      if (nInnerTriplets > N_MAX_TRIPLETS_PER_MODULE) nInnerTriplets = N_MAX_TRIPLETS_PER_MODULE;
      if (nInnerTriplets !=0) {
        for (int j=0; j<nInnerTriplets; j++) {
          threadIdx[nTotalTriplets + j] = index;
          threadIdx_offset[nTotalTriplets + j] = j;
        }
        nTotalTriplets += nInnerTriplets;
      }
    }
    printf("T5: nTotalTriplets=%d nEligibleT5Modules=%d\n", nTotalTriplets, nEligibleT5Modules);
    if (threadSize < nTotalTriplets) {
      printf("threadSize=%d nTotalTriplets=%d: Increase buffer size for threadIdx in createQuintuplets\n", threadSize, nTotalTriplets);
      exit(1);
    }
    cudaMemcpy(threadIdx_gpu, threadIdx, threadSize*sizeof(unsigned int), cudaMemcpyHostToDevice);
    cudaMemcpy(threadIdx_gpu_offset, threadIdx_offset, threadSize*sizeof(unsigned int), cudaMemcpyHostToDevice);

    dim3 nThreads(16, 16, 1);
    int max_outerTriplets = N_MAX_TRIPLETS_PER_MODULE;
    dim3 nBlocks((max_outerTriplets % nThreads.x == 0 ? max_outerTriplets/nThreads.x : max_outerTriplets/nThreads.x + 1), (nTotalTriplets % nThreads.y == 0 ? nTotalTriplets/nThreads.y : nTotalTriplets/nThreads.y + 1), 1);
    createQuintupletsInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *tripletsInGPU, *quintupletsInGPU, threadIdx_gpu, threadIdx_gpu_offset);
    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
      {
	std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;
      }
    //dim3 dupThreads(1,1,1);
    //dim3 dupBlocks(1,1,1);
    dim3 dupThreads(32,32,1);
    dim3 dupBlocks(16,16,1);
    removeDupQuintupletsInGPU<<<dupBlocks,dupThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *tripletsInGPU, *quintupletsInGPU, threadIdx_gpu, threadIdx_gpu_offset);
    cudaDeviceSynchronize();
    free(threadIdx);
    free(nTriplets);
    cudaFree(threadIdx_gpu);
#else
    printf("original 3D grid launching in createQuintuplets does not exist");
    exit(3);
#endif
#endif
    free(indicesOfEligibleModules);

#if defined(AddObjects)
#ifdef Explicit_T5
    addQuintupletsToEventExplicit();
#else
    addQuintupletsToEvent();
#endif
#endif

}

void SDL::Event::createTrackletsWithAGapWithModuleMap()
{
    //use the same trackletsInGPU as before if it exists
    unsigned int nLowerModules;// = *modulesInGPU->nLowerModules;
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

    //TRCAKLETS - To conserve memory, we shall be only declaring nLowerModules amount of memory!!!!!!!
    if(trackletsInGPU == nullptr)
    {
        cudaMallocHost(&trackletsInGPU, sizeof(SDL::tracklets));
#ifdef Explicit_Tracklet
        createTrackletsInExplicitMemory(*trackletsInGPU, N_MAX_TRACKLETS_PER_MODULE , nLowerModules);
#else
        createTrackletsInUnifiedMemory(*trackletsInGPU, N_MAX_TRACKLETS_PER_MODULE , nLowerModules);
#endif
    }

    unsigned int nThreads = 1;
    unsigned int nBlocks = nLowerModules % nThreads == 0 ? nLowerModules/nThreads : nLowerModules/nThreads + 1;

    createTrackletsWithAGapInGPU<<<nBlocks,nThreads>>>(*modulesInGPU, *hitsInGPU, *mdsInGPU, *segmentsInGPU, *trackletsInGPU);

    cudaError_t cudaerr = cudaDeviceSynchronize();
    if(cudaerr != cudaSuccess)
    {
        std::cout<<"sync failed with error : "<<cudaGetErrorString(cudaerr)<<std::endl;

    }

}


void SDL::Event::addTrackletsToEvent()
{
    unsigned int idx;
    for(unsigned int i = 0; i<*(SDL::modulesInGPU->nLowerModules); i++)
    {
        idx = SDL::modulesInGPU->lowerModuleIndices[i];
        //tracklets run only on lower modules!!!!!!
        if(trackletsInGPU->nTracklets[i] == 0)
        {
            modulesInGPU->trackletRanges[idx * 2] = -1;
            modulesInGPU->trackletRanges[idx * 2 + 1] = -1;
        }
        else
        {
            modulesInGPU->trackletRanges[idx * 2] = idx * N_MAX_TRACKLETS_PER_MODULE;
            modulesInGPU->trackletRanges[idx * 2 + 1] = idx * N_MAX_TRACKLETS_PER_MODULE + trackletsInGPU->nTracklets[i] - 1;


            if(modulesInGPU->subdets[idx] == Barrel)
            {
                n_tracklets_by_layer_barrel_[modulesInGPU->layers[idx] - 1] += trackletsInGPU->nTracklets[i];
            }
            else
            {
                n_tracklets_by_layer_endcap_[modulesInGPU->layers[idx] - 1] += trackletsInGPU->nTracklets[i];
            }
        }
    }
}
void SDL::Event::addTrackletsToEventExplicit()
{
unsigned int nLowerModules;
cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

unsigned int* nTrackletsCPU;
cudaMallocHost(&nTrackletsCPU, nLowerModules * sizeof(unsigned int));
cudaMemcpy(nTrackletsCPU,trackletsInGPU->nTracklets,nLowerModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);

short* module_subdets;
cudaMallocHost(&module_subdets, nModules* sizeof(short));
cudaMemcpy(module_subdets,modulesInGPU->subdets,nModules*sizeof(short),cudaMemcpyDeviceToHost);
unsigned int* module_lowerModuleIndices;
cudaMallocHost(&module_lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
cudaMemcpy(module_lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);
int* module_trackletRanges;
cudaMallocHost(&module_trackletRanges, nModules* 2*sizeof(int));
cudaMemcpy(module_trackletRanges,modulesInGPU->trackletRanges,nModules*2*sizeof(int),cudaMemcpyDeviceToHost);
short* module_layers;
cudaMallocHost(&module_layers, nModules * sizeof(short));
cudaMemcpy(module_layers,modulesInGPU->layers,nModules*sizeof(short),cudaMemcpyDeviceToHost);
    unsigned int idx;
    for(unsigned int i = 0; i<nLowerModules; i++)
    {
        idx = module_lowerModuleIndices[i];
        //tracklets run only on lower modules!!!!!!
        if(nTrackletsCPU[i] == 0)
        {
            module_trackletRanges[idx * 2] = -1;
            module_trackletRanges[idx * 2 + 1] = -1;
        }
        else
        {
            module_trackletRanges[idx * 2] = idx * N_MAX_TRACKLETS_PER_MODULE;
            module_trackletRanges[idx * 2 + 1] = idx * N_MAX_TRACKLETS_PER_MODULE + nTrackletsCPU[i] - 1;


            if(module_subdets[idx] == Barrel)
            {
                n_tracklets_by_layer_barrel_[module_layers[idx] - 1] += nTrackletsCPU[i];
            }
            else
            {
                n_tracklets_by_layer_endcap_[module_layers[idx] - 1] += nTrackletsCPU[i];
            }
        }
    }
cudaFreeHost(nTrackletsCPU);
cudaFreeHost(module_subdets);
cudaFreeHost(module_lowerModuleIndices);
cudaFreeHost(module_trackletRanges);
cudaFreeHost(module_layers);
}

void SDL::Event::addTrackCandidatesToEventExplicit()
{
    unsigned int nLowerModules;
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

    unsigned int* nTrackCandidatesCPU;
    cudaMallocHost(&nTrackCandidatesCPU, (nLowerModules )* sizeof(unsigned int));
    cudaMemcpy(nTrackCandidatesCPU,trackCandidatesInGPU->nTrackCandidates,(nLowerModules)*sizeof(unsigned int),cudaMemcpyDeviceToHost);

    unsigned int* module_lowerModuleIndices;
    cudaMallocHost(&module_lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
    cudaMemcpy(module_lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    int* module_trackCandidateRanges;
    cudaMallocHost(&module_trackCandidateRanges, nModules* 2*sizeof(int));
    cudaMemcpy(module_trackCandidateRanges,modulesInGPU->trackCandidateRanges,nModules*2*sizeof(int),cudaMemcpyDeviceToHost);
    short* module_layers;
    cudaMallocHost(&module_layers, nModules * sizeof(short));
    cudaMemcpy(module_layers,modulesInGPU->layers,nModules*sizeof(short),cudaMemcpyDeviceToHost);
    short* module_subdets;
    cudaMallocHost(&module_subdets, nModules* sizeof(short));
    cudaMemcpy(module_subdets,modulesInGPU->subdets,nModules*sizeof(short),cudaMemcpyDeviceToHost);

    int* module_trackCandidateModuleIndices;
    cudaMallocHost(&module_trackCandidateModuleIndices, (nLowerModules + 1) * sizeof(int));
    cudaMemcpy(module_trackCandidateModuleIndices, modulesInGPU->trackCandidateModuleIndices, sizeof(int) * (nLowerModules + 1), cudaMemcpyDeviceToHost);

    unsigned int idx;
    for(unsigned int i = 0; i<nLowerModules; i++)
    {
        idx = module_lowerModuleIndices[i];


        if(nTrackCandidatesCPU[i] == 0)
        {
            module_trackCandidateRanges[idx * 2] = -1;
            module_trackCandidateRanges[idx * 2 + 1] = -1;
        }
        else
        {
            module_trackCandidateRanges[idx * 2] = module_trackCandidateModuleIndices[i];
            module_trackCandidateRanges[idx * 2 + 1] = module_trackCandidateModuleIndices[i] + nTrackCandidatesCPU[i] - 1;

            if(module_subdets[idx] == Barrel)
            {
                n_trackCandidates_by_layer_barrel_[module_layers[idx] - 1] += nTrackCandidatesCPU[i];
            }
            else
            {
                n_trackCandidates_by_layer_endcap_[module_layers[idx] - 1] += nTrackCandidatesCPU[i];
            }
        }
    }
    cudaFreeHost(nTrackCandidatesCPU);
    cudaFreeHost(module_lowerModuleIndices);
    cudaFreeHost(module_trackCandidateRanges);
    cudaFreeHost(module_layers);
    cudaFreeHost(module_subdets);
    cudaFreeHost(module_trackCandidateModuleIndices);
}
void SDL::Event::addTrackCandidatesToEvent()
{

    unsigned int idx;
    for(unsigned int i = 0; i<*(SDL::modulesInGPU->nLowerModules); i++)
    {
        idx = SDL::modulesInGPU->lowerModuleIndices[i];


        if(trackCandidatesInGPU->nTrackCandidates[i] == 0 or SDL::modulesInGPU->trackCandidateModuleIndices[i] == -1)
        {
            modulesInGPU->trackCandidateRanges[idx * 2] = -1;
            modulesInGPU->trackCandidateRanges[idx * 2 + 1] = -1;
        }
        else
        {
            modulesInGPU->trackCandidateRanges[idx * 2] = SDL::modulesInGPU->trackCandidateModuleIndices[i];
            modulesInGPU->trackCandidateRanges[idx * 2 + 1] = SDL::modulesInGPU->trackCandidateModuleIndices[i] +  trackCandidatesInGPU->nTrackCandidates[i] - 1;

            if(modulesInGPU->subdets[idx] == Barrel)
            {
                n_trackCandidates_by_layer_barrel_[modulesInGPU->layers[idx] - 1] += trackCandidatesInGPU->nTrackCandidates[i];
            }
            else
            {
                n_trackCandidates_by_layer_endcap_[modulesInGPU->layers[idx] - 1] += trackCandidatesInGPU->nTrackCandidates[i];
            }
        }
    }
}

void SDL::Event::addQuintupletsToEvent()
{
    unsigned int idx;
    for(unsigned int i = 0; i<*(SDL::modulesInGPU->nLowerModules); i++)
    {
        idx = SDL::modulesInGPU->lowerModuleIndices[i];
        //tracklets run only on lower modules!!!!!!
        if(quintupletsInGPU->nQuintuplets[i] == 0)
        {
            modulesInGPU->quintupletRanges[idx * 2] = -1;
            modulesInGPU->quintupletRanges[idx * 2 + 1] = -1;
        }
        else
        {
            modulesInGPU->quintupletRanges[idx * 2] = SDL::modulesInGPU->quintupletModuleIndices[i];
            modulesInGPU->quintupletRanges[idx * 2 + 1] = SDL::modulesInGPU->quintupletModuleIndices[i] + quintupletsInGPU->nQuintuplets[i] - 1;

            if(modulesInGPU->subdets[idx] == Barrel)
            {
                n_quintuplets_by_layer_barrel_[modulesInGPU->layers[idx] - 1] += quintupletsInGPU->nQuintuplets[i];
            }
            else
            {
                n_quintuplets_by_layer_endcap_[modulesInGPU->layers[idx] - 1] += quintupletsInGPU->nQuintuplets[i];
            }
        }
    }
}

void SDL::Event::addQuintupletsToEventExplicit()
{
    unsigned int nLowerModules;
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

    unsigned int* nQuintupletsCPU;
    cudaMallocHost(&nQuintupletsCPU, nLowerModules * sizeof(unsigned int));
    cudaMemcpy(nQuintupletsCPU,quintupletsInGPU->nQuintuplets,nLowerModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);

    short* module_subdets;
    cudaMallocHost(&module_subdets, nModules* sizeof(short));
    cudaMemcpy(module_subdets,modulesInGPU->subdets,nModules*sizeof(short),cudaMemcpyDeviceToHost);

    unsigned int* module_lowerModuleIndices;
    cudaMallocHost(&module_lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
    cudaMemcpy(module_lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);

    int* module_quintupletRanges;
    cudaMallocHost(&module_quintupletRanges, nModules* 2*sizeof(int));
    cudaMemcpy(module_quintupletRanges,modulesInGPU->quintupletRanges,nModules*2*sizeof(int),cudaMemcpyDeviceToHost);
    short* module_layers;
    cudaMallocHost(&module_layers, nModules * sizeof(short));
    cudaMemcpy(module_layers,modulesInGPU->layers,nModules*sizeof(short),cudaMemcpyDeviceToHost);
    int* module_quintupletModuleIndices;
    cudaMallocHost(&module_quintupletModuleIndices, nLowerModules * sizeof(int));
    cudaMemcpy(module_quintupletModuleIndices, modulesInGPU->quintupletModuleIndices, nLowerModules * sizeof(int), cudaMemcpyDeviceToHost);
    unsigned int idx;
    for(unsigned int i = 0; i<nLowerModules; i++)
    {
        idx = module_lowerModuleIndices[i];
        if(nQuintupletsCPU[i] == 0 or module_quintupletModuleIndices[i] == -1)
        {
            module_quintupletRanges[idx * 2] = -1;
            module_quintupletRanges[idx * 2 + 1] = -1;
        }
       else
        {
            module_quintupletRanges[idx * 2] = module_quintupletModuleIndices[i];
            module_quintupletRanges[idx * 2 + 1] = module_quintupletModuleIndices[i] + nQuintupletsCPU[i] - 1;

            if(module_subdets[idx] == Barrel)
            {
                n_quintuplets_by_layer_barrel_[module_layers[idx] - 1] += nQuintupletsCPU[i];
            }
            else
            {
                n_quintuplets_by_layer_endcap_[module_layers[idx] - 1] += nQuintupletsCPU[i];
            }
        }
    }
    cudaFreeHost(nQuintupletsCPU);
    cudaFreeHost(module_lowerModuleIndices);
    cudaFreeHost(module_quintupletRanges);
    cudaFreeHost(module_layers);
    cudaFreeHost(module_subdets);
    cudaFreeHost(module_quintupletModuleIndices);

}

void SDL::Event::addTripletsToEvent()
{
    unsigned int idx;
    for(unsigned int i = 0; i<*(SDL::modulesInGPU->nLowerModules); i++)
    {
        idx = SDL::modulesInGPU->lowerModuleIndices[i];
        //tracklets run only on lower modules!!!!!!
        if(tripletsInGPU->nTriplets[i] == 0)
        {
            modulesInGPU->tripletRanges[idx * 2] = -1;
            modulesInGPU->tripletRanges[idx * 2 + 1] = -1;
        }
        else
        {
            modulesInGPU->tripletRanges[idx * 2] = idx * N_MAX_TRIPLETS_PER_MODULE;
            modulesInGPU->tripletRanges[idx * 2 + 1] = idx * N_MAX_TRIPLETS_PER_MODULE + tripletsInGPU->nTriplets[i] - 1;

            if(modulesInGPU->subdets[idx] == Barrel)
            {
                n_triplets_by_layer_barrel_[modulesInGPU->layers[idx] - 1] += tripletsInGPU->nTriplets[i];
            }
            else
            {
                n_triplets_by_layer_endcap_[modulesInGPU->layers[idx] - 1] += tripletsInGPU->nTriplets[i];
            }
        }
    }
}
void SDL::Event::addTripletsToEventExplicit()
{
    unsigned int nLowerModules;
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);

    unsigned int* nTripletsCPU;
    cudaMallocHost(&nTripletsCPU, nLowerModules * sizeof(unsigned int));
    cudaMemcpy(nTripletsCPU,tripletsInGPU->nTriplets,nLowerModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);

    short* module_subdets;
    cudaMallocHost(&module_subdets, nModules* sizeof(short));
    cudaMemcpy(module_subdets,modulesInGPU->subdets,nModules*sizeof(short),cudaMemcpyDeviceToHost);
    unsigned int* module_lowerModuleIndices;
    cudaMallocHost(&module_lowerModuleIndices, (nLowerModules +1)* sizeof(unsigned int));
    cudaMemcpy(module_lowerModuleIndices,modulesInGPU->lowerModuleIndices,(nLowerModules+1)*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    int* module_tripletRanges;
    cudaMallocHost(&module_tripletRanges, nModules* 2*sizeof(int));
    cudaMemcpy(module_tripletRanges,modulesInGPU->tripletRanges,nModules*2*sizeof(int),cudaMemcpyDeviceToHost);
    short* module_layers;
    cudaMallocHost(&module_layers, nModules * sizeof(short));
    cudaMemcpy(module_layers,modulesInGPU->layers,nModules*sizeof(short),cudaMemcpyDeviceToHost);
    unsigned int idx;
    for(unsigned int i = 0; i<nLowerModules; i++)
    {
        idx = module_lowerModuleIndices[i];
        //tracklets run only on lower modules!!!!!!
        if(nTripletsCPU[i] == 0)
        {
            module_tripletRanges[idx * 2] = -1;
            module_tripletRanges[idx * 2 + 1] = -1;
        }
        else
        {
            module_tripletRanges[idx * 2] = idx * N_MAX_TRIPLETS_PER_MODULE;
            module_tripletRanges[idx * 2 + 1] = idx * N_MAX_TRIPLETS_PER_MODULE + nTripletsCPU[i] - 1;

            if(module_subdets[idx] == Barrel)
            {
                n_triplets_by_layer_barrel_[module_layers[idx] - 1] += nTripletsCPU[i];
            }
            else
            {
                n_triplets_by_layer_endcap_[module_layers[idx] - 1] += nTripletsCPU[i];
            }
        }
    }
    cudaFreeHost(nTripletsCPU);
    cudaFreeHost(module_lowerModuleIndices);
    cudaFreeHost(module_tripletRanges);
    cudaFreeHost(module_layers);
    cudaFreeHost(module_subdets);
}
#ifndef NESTED_PARA
__global__ void createMiniDoubletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU)
{
    int lowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    //int lowerHitIndex = blockIdx.y * blockDim.y + threadIdx.y;
    //int upperHitIndex = blockIdx.z * blockDim.z + threadIdx.z;
    if(lowerModuleArrayIndex >= (*modulesInGPU.nLowerModules)) return; //extra precaution

    int lowerModuleIndex = modulesInGPU.lowerModuleIndices[lowerModuleArrayIndex];
    int upperModuleIndex = modulesInGPU.partnerModuleIndex(lowerModuleIndex);

    if(modulesInGPU.hitRanges[lowerModuleIndex * 2] == -1) return;
    if(modulesInGPU.hitRanges[upperModuleIndex * 2] == -1) return;
    unsigned int nLowerHits = modulesInGPU.hitRanges[lowerModuleIndex * 2 + 1] - modulesInGPU.hitRanges[lowerModuleIndex * 2] + 1;
    unsigned int nUpperHits = modulesInGPU.hitRanges[upperModuleIndex * 2 + 1] - modulesInGPU.hitRanges[upperModuleIndex * 2] + 1;

#ifdef NEWGRID_MD
    int lowerHitIndex =  (blockIdx.y * blockDim.y + threadIdx.y) / nUpperHits;
    int upperHitIndex =  (blockIdx.y * blockDim.y + threadIdx.y) % nUpperHits;
#else
    int lowerHitIndex = blockIdx.y * blockDim.y + threadIdx.y;
    int upperHitIndex = blockIdx.z * blockDim.z + threadIdx.z;
#endif

    //consider assigining a dummy computation function for these
    if(lowerHitIndex >= nLowerHits) return;
    if(upperHitIndex >= nUpperHits) return;

    unsigned int lowerHitArrayIndex = modulesInGPU.hitRanges[lowerModuleIndex * 2] + lowerHitIndex;
    unsigned int upperHitArrayIndex = modulesInGPU.hitRanges[upperModuleIndex * 2] + upperHitIndex;

    float dz, drt, dphi, dphichange, shiftedX, shiftedY, shiftedZ, noShiftedDz, noShiftedDphi, noShiftedDphiChange;

#ifdef CUT_VALUE_DEBUG
    float dzCut, drtCut, miniCut;
    bool success = runMiniDoubletDefaultAlgo(modulesInGPU, hitsInGPU, lowerModuleIndex, lowerHitArrayIndex, upperHitArrayIndex, dz,  drt, dphi, dphichange, shiftedX, shiftedY, shiftedZ, noShiftedDz, noShiftedDphi, noShiftedDphiChange, dzCut, drtCut, miniCut);
#else
    bool success = runMiniDoubletDefaultAlgo(modulesInGPU, hitsInGPU, lowerModuleIndex, lowerHitArrayIndex, upperHitArrayIndex, dz, dphi, dphichange, shiftedX, shiftedY, shiftedZ, noShiftedDz, noShiftedDphi, noShiftedDphiChange);
#endif

    if(success)
    {
        unsigned int mdModuleIndex = atomicAdd(&mdsInGPU.nMDs[lowerModuleIndex],1);
        if(mdModuleIndex >= N_MAX_MD_PER_MODULES)
        {
            #ifdef Warnings
            if(mdModuleIndex == N_MAX_MD_PER_MODULES)
                printf("Mini-doublet excess alert! Module index =  %d\n",lowerModuleIndex);
            #endif
        }
        else
        {
            unsigned int mdIndex = lowerModuleIndex * N_MAX_MD_PER_MODULES + mdModuleIndex;
#ifdef CUT_VALUE_DEBUG
            addMDToMemory(mdsInGPU,hitsInGPU, modulesInGPU, lowerHitArrayIndex, upperHitArrayIndex, lowerModuleIndex, dz,drt, dphi, dphichange, shiftedX, shiftedY, shiftedZ, noShiftedDz, noShiftedDphi, noShiftedDphiChange, dzCut, drtCut, miniCut, mdIndex);
#else
        addMDToMemory(mdsInGPU,hitsInGPU, modulesInGPU, lowerHitArrayIndex, upperHitArrayIndex, lowerModuleIndex, dz, dphi, dphichange, shiftedX, shiftedY, shiftedZ, noShiftedDz, noShiftedDphi, noShiftedDphiChange, mdIndex);
#endif

        }

    }
}
#else
__global__ void createMiniDoubletsFromLowerModule(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, unsigned int lowerModuleIndex, unsigned int upperModuleIndex, unsigned int nLowerHits, unsigned int nUpperHits)
{
    unsigned int lowerHitIndex = blockIdx.y * blockDim.y + threadIdx.y;
    unsigned int upperHitIndex = blockIdx.z * blockDim.z + threadIdx.z;

    //consider assigining a dummy computation function for these
    if(lowerHitIndex >= nLowerHits) return;
    if(upperHitIndex >= nUpperHits) return;

    unsigned int lowerHitArrayIndex = modulesInGPU.hitRanges[lowerModuleIndex * 2] + lowerHitIndex;
    unsigned int upperHitArrayIndex = modulesInGPU.hitRanges[upperModuleIndex * 2] + upperHitIndex;

    float dz, drt, dphi, dphichange, shiftedX, shiftedY, shiftedZ, noShiftedDz, noShiftedDphi, noShiftedDphiChange;

#ifdef CUT_VALUE_DEBUG
    float dzCut, drtCut, miniCut;
    bool success = runMiniDoubletDefaultAlgo(modulesInGPU, hitsInGPU, lowerModuleIndex, lowerHitArrayIndex, upperHitArrayIndex, dz,  drt, dphi, dphichange, shiftedX, shiftedY, shiftedZ, noShiftedDz, noShiftedDphi, noShiftedDphiChange, dzCut, drtCut, miniCut);
#else
    bool success = runMiniDoubletDefaultAlgo(modulesInGPU, hitsInGPU, lowerModuleIndex, lowerHitArrayIndex, upperHitArrayIndex, dz, dphi, dphichange, shiftedX, shiftedY, shiftedZ, noShiftedDz, noShiftedDphi, noShiftedDphiChange);
#endif

    if(success)
    {
        unsigned int mdModuleIndex = atomicAdd(&mdsInGPU.nMDs[lowerModuleIndex],1);

        if(mdModuleIndex >= N_MAX_MD_PER_MODULES)
        {
            #ifdef Warnings
            if(mdModuleIndex == N_MAX_MD_PER_MODULES)
                printf("Mini-doublet excess alert! Module index = %d\n",lowerModuleIndex);
            #endif
        }
        else
        {
            unsigned int mdIndex = lowerModuleIndex * N_MAX_MD_PER_MODULES + mdModuleIndex;
#ifdef CUT_VALUE_DEBUG
            addMDToMemory(mdsInGPU,hitsInGPU, modulesInGPU, lowerHitArrayIndex, upperHitArrayIndex, lowerModuleIndex, dz,drt, dphi, dphichange, shiftedX, shiftedY, shiftedZ, noShiftedDz, noShiftedDphi, noShiftedDphiChange, dzCut, drtCut, miniCut, mdIndex);
#else
            addMDToMemory(mdsInGPU,hitsInGPU, modulesInGPU, lowerHitArrayIndex, upperHitArrayIndex, lowerModuleIndex, dz, dphi, dphichange, shiftedX, shiftedY, shiftedZ, noShiftedDz, noShiftedDphi, noShiftedDphiChange, mdIndex);
#endif
        }

    }
}


__global__ void createMiniDoubletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU)
{
    int lowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    if(lowerModuleArrayIndex >= (*modulesInGPU.nLowerModules)) return; //extra precaution

    int lowerModuleIndex = modulesInGPU.lowerModuleIndices[lowerModuleArrayIndex];
    int upperModuleIndex = modulesInGPU.partnerModuleIndex(lowerModuleIndex);

    if(modulesInGPU.hitRanges[lowerModuleIndex * 2] == -1) return;
    if(modulesInGPU.hitRanges[upperModuleIndex * 2] == -1) return;

    unsigned int nLowerHits = modulesInGPU.hitRanges[lowerModuleIndex * 2 + 1] - modulesInGPU.hitRanges[lowerModuleIndex * 2] + 1;
    unsigned int nUpperHits = modulesInGPU.hitRanges[upperModuleIndex * 2 + 1] - modulesInGPU.hitRanges[upperModuleIndex * 2] + 1;

    dim3 nThreads(1,16,16);
    dim3 nBlocks(1,nLowerHits % nThreads.y == 0 ? nLowerHits/nThreads.y : nLowerHits/nThreads.y + 1, nUpperHits % nThreads.z == 0 ? nUpperHits/nThreads.z : nUpperHits/nThreads.z + 1);

    createMiniDoubletsFromLowerModule<<<nBlocks,nThreads>>>(modulesInGPU, hitsInGPU, mdsInGPU, lowerModuleIndex, upperModuleIndex, nLowerHits, nUpperHits);


}
#endif

#ifndef NESTED_PARA
__global__ void createSegmentsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU)
{
#ifdef NEWGRID_Seg
    int innerLowerModuleArrayIdx = blockIdx.z * blockDim.z + threadIdx.z;
    int outerLowerModuleArrayIdx = blockIdx.y * blockDim.y + threadIdx.y;
#else
    int xAxisIdx = blockIdx.x * blockDim.x + threadIdx.x;
    int innerMDArrayIdx = blockIdx.y * blockDim.y + threadIdx.y;
    int outerMDArrayIdx = blockIdx.z * blockDim.z + threadIdx.z;

    int innerLowerModuleArrayIdx = xAxisIdx/MAX_CONNECTED_MODULES;
    int outerLowerModuleArrayIdx = xAxisIdx % MAX_CONNECTED_MODULES; //need this index from the connected module array
#endif
    if(innerLowerModuleArrayIdx >= *modulesInGPU.nLowerModules) return;

    unsigned int innerLowerModuleIndex = modulesInGPU.lowerModuleIndices[innerLowerModuleArrayIdx];

    unsigned int nConnectedModules = modulesInGPU.nConnectedModules[innerLowerModuleIndex];

    if(outerLowerModuleArrayIdx >= nConnectedModules) return;

    unsigned int outerLowerModuleIndex = modulesInGPU.moduleMap[innerLowerModuleIndex * MAX_CONNECTED_MODULES + outerLowerModuleArrayIdx];

    unsigned int nInnerMDs = mdsInGPU.nMDs[innerLowerModuleIndex] > N_MAX_MD_PER_MODULES ? N_MAX_MD_PER_MODULES : mdsInGPU.nMDs[innerLowerModuleIndex];
    unsigned int nOuterMDs = mdsInGPU.nMDs[outerLowerModuleIndex] > N_MAX_MD_PER_MODULES ? N_MAX_MD_PER_MODULES : mdsInGPU.nMDs[outerLowerModuleIndex];

#ifdef NEWGRID_Seg
    if (nInnerMDs*nOuterMDs == 0) return;
    int innerMDArrayIdx = (blockIdx.x * blockDim.x + threadIdx.x) / nOuterMDs;
    int outerMDArrayIdx = (blockIdx.x * blockDim.x + threadIdx.x) % nOuterMDs;
#endif

    if(innerMDArrayIdx >= nInnerMDs) return;
    if(outerMDArrayIdx >= nOuterMDs) return;

    unsigned int innerMDIndex = modulesInGPU.mdRanges[innerLowerModuleIndex * 2] + innerMDArrayIdx;
    unsigned int outerMDIndex = modulesInGPU.mdRanges[outerLowerModuleIndex * 2] + outerMDArrayIdx;

    float zIn, zOut, rtIn, rtOut, dPhi, dPhiMin, dPhiMax, dPhiChange, dPhiChangeMin, dPhiChangeMax, dAlphaInnerMDSegment, dAlphaOuterMDSegment, dAlphaInnerMDOuterMD;

    unsigned int innerMiniDoubletAnchorHitIndex, outerMiniDoubletAnchorHitIndex;

    dPhiMin = 0;
    dPhiMax = 0;
    dPhiChangeMin = 0;
    dPhiChangeMax = 0;
    float zLo, zHi, rtLo, rtHi, sdCut, dAlphaInnerMDSegmentThreshold, dAlphaOuterMDSegmentThreshold, dAlphaInnerMDOuterMDThreshold;

    bool success = runSegmentDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, innerLowerModuleIndex, outerLowerModuleIndex, innerMDIndex, outerMDIndex, zIn, zOut, rtIn, rtOut, dPhi, dPhiMin, dPhiMax, dPhiChange, dPhiChangeMin, dPhiChangeMax, dAlphaInnerMDSegment, dAlphaOuterMDSegment, dAlphaInnerMDOuterMD, zLo, zHi, rtLo, rtHi, sdCut, dAlphaInnerMDSegmentThreshold, dAlphaOuterMDSegmentThreshold,
            dAlphaInnerMDOuterMDThreshold, innerMiniDoubletAnchorHitIndex, outerMiniDoubletAnchorHitIndex);

    if(success)
    {
        unsigned int segmentModuleIdx = atomicAdd(&segmentsInGPU.nSegments[innerLowerModuleIndex],1);
        if(segmentModuleIdx >= N_MAX_SEGMENTS_PER_MODULE)
        {
            #ifdef Warnings
            if(segmentModuleIdx == N_MAX_SEGMENTS_PER_MODULE)
                printf("Segment excess alert! Module index = %d\n",innerLowerModuleIndex);
            #endif
        }
        else
        {
            unsigned int segmentIdx = innerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + segmentModuleIdx;
#ifdef CUT_VALUE_DEBUG
            addSegmentToMemory(segmentsInGPU,innerMDIndex, outerMDIndex,innerLowerModuleIndex, outerLowerModuleIndex, innerMiniDoubletAnchorHitIndex, outerMiniDoubletAnchorHitIndex, dPhi, dPhiMin, dPhiMax, dPhiChange, dPhiChangeMin, dPhiChangeMax, zIn, zOut, rtIn, rtOut, dAlphaInnerMDSegment, dAlphaOuterMDSegment, dAlphaInnerMDOuterMD, zLo, zHi, rtLo, rtHi, sdCut, dAlphaInnerMDSegmentThreshold, dAlphaOuterMDSegmentThreshold,
                dAlphaInnerMDOuterMDThreshold, segmentIdx);
#else
            addSegmentToMemory(segmentsInGPU,innerMDIndex, outerMDIndex,innerLowerModuleIndex, outerLowerModuleIndex, innerMiniDoubletAnchorHitIndex, outerMiniDoubletAnchorHitIndex, dPhi, dPhiMin, dPhiMax, dPhiChange, dPhiChangeMin, dPhiChangeMax, segmentIdx);
#endif

        }
    }
}
#else

__global__ void createSegmentsFromInnerLowerModule(struct SDL::modules&modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, unsigned int innerLowerModuleIndex, unsigned int nInnerMDs)
{
    unsigned int outerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int innerMDArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;
    unsigned int outerMDArrayIndex = blockIdx.z * blockDim.z + threadIdx.z;

    unsigned int outerLowerModuleIndex = modulesInGPU.moduleMap[innerLowerModuleIndex * MAX_CONNECTED_MODULES + outerLowerModuleArrayIndex];

    unsigned int nOuterMDs = mdsInGPU.nMDs[outerLowerModuleIndex] > N_MAX_MD_PER_MODULES ? N_MAX_MD_PER_MODULES : mdsInGPU.nMDs[outerLowerModuleIndex];
    if(innerMDArrayIndex >= nInnerMDs) return;
    if(outerMDArrayIndex >= nOuterMDs) return;

    unsigned int innerMDIndex = innerLowerModuleIndex * N_MAX_MD_PER_MODULES + innerMDArrayIndex;
    unsigned int outerMDIndex = outerLowerModuleIndex * N_MAX_MD_PER_MODULES + outerMDArrayIndex;

    float zIn, zOut, rtIn, rtOut, dPhi, dPhiMin, dPhiMax, dPhiChange, dPhiChangeMin, dPhiChangeMax, dAlphaInnerMDSegment, dAlphaOuterMDSegment, dAlphaInnerMDOuterMD;

    unsigned int innerMiniDoubletAnchorHitIndex, outerMiniDoubletAnchorHitIndex;

    dPhiMin = 0;
    dPhiMax = 0;
    dPhiChangeMin = 0;
    dPhiChangeMax = 0;
    float zLo, zHi, rtLo, rtHi, sdCut, dAlphaInnerMDSegmentThreshold, dAlphaOuterMDSegmentThreshold, dAlphaInnerMDOuterMDThreshold;

    bool success = runSegmentDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, innerLowerModuleIndex, outerLowerModuleIndex, innerMDIndex, outerMDIndex, zIn, zOut, rtIn, rtOut, dPhi, dPhiMin, dPhiMax, dPhiChange, dPhiChangeMin, dPhiChangeMax, dAlphaInnerMDSegment, dAlphaOuterMDSegment, dAlphaInnerMDOuterMD, zLo, zHi, rtLo, rtHi, sdCut, dAlphaInnerMDSegmentThreshold, dAlphaOuterMDSegmentThreshold,
            dAlphaInnerMDOuterMDThreshold, innerMiniDoubletAnchorHitIndex, outerMiniDoubletAnchorHitIndex);


    if(success)
    {
        unsigned int segmentModuleIdx = atomicAdd(&segmentsInGPU.nSegments[innerLowerModuleIndex],1);
        if(segmentModuleIdx >= N_MAX_SEGMENTS_PER_MODULE)
        {
            #ifdef Warnings
            if(segmentModuleIdx == N_MAX_SEGMENTS_PER_MODULE)
                printf("Segment excess alert! Module index = %d\n",innerLowerModuleIndex);
            #endif
        }
        else
        {
            unsigned int segmentIdx = innerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + segmentModuleIdx;
#ifdef CUT_VALUE_DEBUG
            addSegmentToMemory(segmentsInGPU,innerMDIndex, outerMDIndex,innerLowerModuleIndex, outerLowerModuleIndex, innerMiniDoubletAnchorHitIndex, outerMiniDoubletAnchorHitIndex, dPhi, dPhiMin, dPhiMax, dPhiChange, dPhiChangeMin, dPhiChangeMax, zIn, zOut, rtIn, rtOut, dAlphaInnerMDSegment, dAlphaOuterMDSegment, dAlphaInnerMDOuterMD, zLo, zHi, rtLo, rtHi, sdCut, dAlphaInnerMDSegmentThreshold, dAlphaOuterMDSegmentThreshold,
                dAlphaInnerMDOuterMDThreshold, segmentIdx);
#else
            addSegmentToMemory(segmentsInGPU,innerMDIndex, outerMDIndex,innerLowerModuleIndex, outerLowerModuleIndex, innerMiniDoubletAnchorHitIndex, outerMiniDoubletAnchorHitIndex, dPhi, dPhiMin, dPhiMax, dPhiChange, dPhiChangeMin, dPhiChangeMax, segmentIdx);
#endif

        }

    }

}

__global__ void createSegmentsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU)
{
    int innerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    if(innerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;
    unsigned int innerLowerModuleIndex = modulesInGPU.lowerModuleIndices[innerLowerModuleArrayIndex];
    unsigned int nConnectedModules = modulesInGPU.nConnectedModules[innerLowerModuleIndex];
    unsigned int nInnerMDs = mdsInGPU.nMDs[innerLowerModuleIndex] > N_MAX_MD_PER_MODULES ? N_MAX_MD_PER_MODULES : mdsInGPU.nMDs[innerLowerModuleIndex];

    if(nConnectedModules == 0) return;

    if(nInnerMDs == 0) return;
    dim3 nThreads(1,16,16);
    dim3 nBlocks((nConnectedModules % nThreads.x == 0 ? nConnectedModules/nThreads.x : nConnectedModules/nThreads.x + 1), (nInnerMDs % nThreads.y == 0 ? nInnerMDs/nThreads.y : nInnerMDs/nThreads.y + 1), (N_MAX_MD_PER_MODULES % nThreads.z == 0 ? N_MAX_MD_PER_MODULES/nThreads.z : N_MAX_MD_PER_MODULES/nThreads.z + 1));

    createSegmentsFromInnerLowerModule<<<nBlocks,nThreads>>>(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, innerLowerModuleIndex,nInnerMDs);

}
#endif

#ifndef NESTED_PARA
#ifdef NEWGRID_Tracklet
__global__ void createTrackletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::tracklets& trackletsInGPU, unsigned int *index_gpu)
{
  //int innerInnerLowerModuleArrayIndex = blockIdx.z * blockDim.z + threadIdx.z;
  int innerInnerLowerModuleArrayIndex = index_gpu[blockIdx.z * blockDim.z + threadIdx.z];
  if(innerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;
  unsigned int innerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[innerInnerLowerModuleArrayIndex];
  unsigned int nInnerSegments = segmentsInGPU.nSegments[innerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[innerInnerLowerModuleIndex];

  if(nInnerSegments == 0) return;

  int outerInnerLowerModuleArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;
  int innerSegmentArrayIndex = (blockIdx.x * blockDim.x + threadIdx.x) % nInnerSegments;
  int outerSegmentArrayIndex = (blockIdx.x * blockDim.x + threadIdx.x) / nInnerSegments;

  if(innerSegmentArrayIndex >= nInnerSegments) return;

  //outer inner lower module array indices should be obtained from the partner module of the inner segment's outer lower module
  unsigned int innerSegmentIndex = innerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + innerSegmentArrayIndex;

  unsigned int innerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[innerSegmentIndex];

  //number of possible outer segment inner MD lower modules
  unsigned int nOuterInnerLowerModules = modulesInGPU.nConnectedModules[innerOuterLowerModuleIndex];
  if(outerInnerLowerModuleArrayIndex >= nOuterInnerLowerModules) return;

  unsigned int outerInnerLowerModuleIndex = modulesInGPU.moduleMap[innerOuterLowerModuleIndex * MAX_CONNECTED_MODULES + outerInnerLowerModuleArrayIndex];

  unsigned int nOuterSegments = segmentsInGPU.nSegments[outerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[outerInnerLowerModuleIndex];
  if(outerSegmentArrayIndex >= nOuterSegments) return;

  unsigned int outerSegmentIndex = outerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + outerSegmentArrayIndex;

  //for completeness - outerOuterLowerModuleIndex
  unsigned int outerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[outerSegmentIndex];

  //with both segment indices obtained, run the tracklet algorithm
  float zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta;

    float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;
    bool success = runTrackletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, innerInnerLowerModuleIndex, innerOuterLowerModuleIndex, outerInnerLowerModuleIndex, outerOuterLowerModuleIndex, innerSegmentIndex, outerSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, N_MAX_SEGMENTS_PER_MODULE); //might want to send the other two module indices and the anchor hits also to save memory accesses


  if(success)
    {
      unsigned int trackletModuleIndex = atomicAdd(&trackletsInGPU.nTracklets[innerInnerLowerModuleArrayIndex],1);
      if(trackletModuleIndex >= N_MAX_TRACKLETS_PER_MODULE)
      {
          #ifdef Warnings
          if(trackletModuleIndex == N_MAX_TRACKLETS_PER_MODULE)
              printf("Tracklet excess alert! Module index = %d\n",innerInnerLowerModuleIndex);
          #endif
      }
      else
      {
          unsigned int trackletIndex = innerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + trackletModuleIndex;
#ifdef CUT_VALUE_DEBUG
          addTrackletToMemory(trackletsInGPU,innerSegmentIndex,outerSegmentIndex,innerInnerLowerModuleIndex,innerOuterLowerModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, trackletIndex);

#else
          addTrackletToMemory(trackletsInGPU,innerSegmentIndex,outerSegmentIndex,innerInnerLowerModuleIndex,innerOuterLowerModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,trackletIndex);

#endif

      }
    }
}
#endif
#else
__global__ void createTrackletsFromInnerInnerLowerModule(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::tracklets& trackletsInGPU, unsigned int innerInnerLowerModuleIndex, unsigned int nInnerSegments, unsigned int innerInnerLowerModuleArrayIndex)
{
    int outerInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    int innerSegmentArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;
    int outerSegmentArrayIndex = blockIdx.z * blockDim.z + threadIdx.z;

    if(innerSegmentArrayIndex >= nInnerSegments) return;
        //outer inner lower module array indices should be obtained from the partner module of the inner segment's outer lower module
    unsigned int innerSegmentIndex = innerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + innerSegmentArrayIndex;


    unsigned int innerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[innerSegmentIndex];

    //number of possible outer segment inner MD lower modules
    unsigned int nOuterInnerLowerModules = modulesInGPU.nConnectedModules[innerOuterLowerModuleIndex];
    if(outerInnerLowerModuleArrayIndex >= nOuterInnerLowerModules) return;

    unsigned int outerInnerLowerModuleIndex = modulesInGPU.moduleMap[innerOuterLowerModuleIndex * MAX_CONNECTED_MODULES + outerInnerLowerModuleArrayIndex];

    unsigned int nOuterSegments = segmentsInGPU.nSegments[outerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[outerInnerLowerModuleIndex];
    if(outerSegmentArrayIndex >= nOuterSegments) return;

    unsigned int outerSegmentIndex = outerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + outerSegmentArrayIndex;

    //for completeness - outerOuterLowerModuleIndex
    unsigned int outerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[outerSegmentIndex];

    //with both segment indices obtained, run the tracklet algorithm

    float zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta;

    float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;
    bool success = runTrackletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, innerInnerLowerModuleIndex, innerOuterLowerModuleIndex, outerInnerLowerModuleIndex, outerOuterLowerModuleIndex, innerSegmentIndex, outerSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, N_MAX_SEGMENTS_PER_MODULE); //might want to send the other two module indices and the anchor hits also to save memory accesses

   if(success)
   {
        unsigned int trackletModuleIndex = atomicAdd(&trackletsInGPU.nTracklets[innerInnerLowerModuleArrayIndex],1);
        if(trackletModuleIndex >= N_MAX_TRACKLETS_PER_MODULE)
        {
            #ifdef Warnings
            if(trackletModuleIndex == N_MAX_TRACKLETS_PER_MODULE)
                printf("Tracklet excess alert! Module index = %d\n",innerInnerLowerModuleIndex);
            #endif
        }
        else
        {
            unsigned int trackletIndex = innerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + trackletModuleIndex;
#ifdef CUT_VALUE_DEBUG
            addTrackletToMemory(trackletsInGPU,innerSegmentIndex,outerSegmentIndex,innerInnerLowerModuleIndex,innerOuterLowerModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, trackletIndex);

#else
            addTrackletToMemory(trackletsInGPU,innerSegmentIndex,outerSegmentIndex,innerInnerLowerModuleIndex,innerOuterLowerModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,trackletIndex);

#endif
        }
   }



}




__global__ void createTrackletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::tracklets& trackletsInGPU)
{
  int innerInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
  if(innerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;
  unsigned int innerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[innerInnerLowerModuleArrayIndex];
  unsigned int nInnerSegments = segmentsInGPU.nSegments[innerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[innerInnerLowerModuleIndex];
  if(nInnerSegments == 0) return;

  dim3 nThreads(1,16,16);
  dim3 nBlocks(MAX_CONNECTED_MODULES % nThreads.x  == 0 ? MAX_CONNECTED_MODULES / nThreads.x : MAX_CONNECTED_MODULES / nThreads.x + 1 ,nInnerSegments % nThreads.y == 0 ? nInnerSegments/nThreads.y : nInnerSegments/nThreads.y + 1,N_MAX_SEGMENTS_PER_MODULE % nThreads.z == 0 ? N_MAX_SEGMENTS_PER_MODULE/nThreads.z : N_MAX_SEGMENTS_PER_MODULE/nThreads.z + 1);

  createTrackletsFromInnerInnerLowerModule<<<nBlocks,nThreads>>>(modulesInGPU,hitsInGPU,mdsInGPU,segmentsInGPU,trackletsInGPU,innerInnerLowerModuleIndex,nInnerSegments,innerInnerLowerModuleArrayIndex);

}
#endif


#ifdef NEWGRID_Tracklet
__global__ void createTrackletsFromTriplets(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::tracklets& trackletsInGPU,unsigned int *threadIdx_gpu, unsigned int *threadIdx_gpu_offset)
{

  int innerInnerLowerModuleArrayIndex = threadIdx_gpu[blockIdx.y * blockDim.y + threadIdx.y];
  if(innerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;
  unsigned int nTriplets = tripletsInGPU.nTriplets[innerInnerLowerModuleArrayIndex] > N_MAX_TRIPLETS_PER_MODULE ? N_MAX_TRIPLETS_PER_MODULE : tripletsInGPU.nTriplets[innerInnerLowerModuleArrayIndex];

  if(nTriplets == 0) return;
  int innerTripletArrayIndex = threadIdx_gpu_offset[blockIdx.y * blockDim.y + threadIdx.y];
  int outerTripletArrayIndex = (blockIdx.x * blockDim.x + threadIdx.x);

//////////////////////////////////////////////////////////
  if(innerTripletArrayIndex >= nTriplets) return;

  //outer inner lower module array indices should be obtained from the partner module of the inner Triplet's outer lower module
  unsigned int innerTripletIndex = innerInnerLowerModuleArrayIndex * N_MAX_TRIPLETS_PER_MODULE + innerTripletArrayIndex;
  unsigned int outerInnerInnerLowerModuleIndex = modulesInGPU.reverseLookupLowerModuleIndices[tripletsInGPU.lowerModuleIndices[3 * innerTripletIndex + 1]];//same as innerOuterInnerLowerModuleIndex
        if(outerTripletArrayIndex < fminf(tripletsInGPU.nTriplets[outerInnerInnerLowerModuleIndex],N_MAX_TRIPLETS_PER_MODULE))
        {
            unsigned int outerTripletIndex = outerInnerInnerLowerModuleIndex * N_MAX_TRIPLETS_PER_MODULE + outerTripletArrayIndex;
            unsigned int innerOuterSegmentIndex = tripletsInGPU.segmentIndices[2 * innerTripletIndex + 1];
            unsigned int outerInnerSegmentIndex = tripletsInGPU.segmentIndices[2 * outerTripletIndex];

            if(innerOuterSegmentIndex == outerInnerSegmentIndex)
            {
              unsigned int innerSegmentIndex = tripletsInGPU.segmentIndices[2 * innerTripletIndex];
              unsigned int outerSegmentIndex = tripletsInGPU.segmentIndices[2 * outerTripletIndex + 1];
              unsigned int innerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[innerSegmentIndex];
              unsigned int outerInnerLowerModuleIndex = segmentsInGPU.innerLowerModuleIndices[outerSegmentIndex];
              unsigned int outerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[outerSegmentIndex];
              float zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta;
              unsigned int innerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[innerInnerLowerModuleArrayIndex];

              float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;
              bool success = runTrackletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, innerInnerLowerModuleIndex, innerOuterLowerModuleIndex, outerInnerLowerModuleIndex, outerOuterLowerModuleIndex, innerSegmentIndex, outerSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, N_MAX_SEGMENTS_PER_MODULE); //might want to send the other two module indices and the anchor hits also to save memory accesses

              if(success)
              {
                   unsigned int trackletModuleIndex = atomicAdd(&trackletsInGPU.nTracklets[innerInnerLowerModuleArrayIndex],1);
                   if(trackletModuleIndex >= N_MAX_TRACKLETS_PER_MODULE)
                   {
                       #ifdef Warnings
                       if(trackletModuleIndex == N_MAX_TRACKLETS_PER_MODULE)
                           printf("Tracklet excess alert! Module index = %d\n",innerInnerLowerModuleIndex);
                       #endif
                   }
                   else
                   {
                       unsigned int trackletIndex = innerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + trackletModuleIndex;
                        #ifdef CUT_VALUE_DEBUG
                       addTrackletToMemory(trackletsInGPU,innerSegmentIndex,outerSegmentIndex,innerInnerLowerModuleIndex,innerOuterLowerModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, trackletIndex);
                        #else
                       addTrackletToMemory(trackletsInGPU,innerSegmentIndex,outerSegmentIndex,innerInnerLowerModuleIndex,innerOuterLowerModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,trackletIndex);
                        #endif
                   }
              }
            }
        }
}
#else
__global__ void createTrackletsFromTriplets(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::tracklets& trackletsInGPU/*,unsigned int *index_gpu*/)
{
  int innerInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
  if(innerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;
  unsigned int nTriplets = tripletsInGPU.nTriplets[innerInnerLowerModuleArrayIndex] > N_MAX_TRIPLETS_PER_MODULE ? N_MAX_TRIPLETS_PER_MODULE : tripletsInGPU.nTriplets[innerInnerLowerModuleArrayIndex];

  if(nTriplets == 0) return;
    dim3 nThreads(16,16,1);
    dim3 nBlocks(nTriplets % nThreads.x == 0 ? nTriplets / nThreads.x : nTriplets / nThreads.x + 1, N_MAX_TRIPLETS_PER_MODULE % nThreads.y == 0 ? N_MAX_TRIPLETS_PER_MODULE / nThreads.y : N_MAX_TRIPLETS_PER_MODULE / nThreads.y + 1, 1);
    createTrackletsFromTripletsP2<<<nBlocks,nThreads>>>(modulesInGPU,hitsInGPU,mdsInGPU,segmentsInGPU,tripletsInGPU,trackletsInGPU,innerInnerLowerModuleArrayIndex,nTriplets);

}
__global__ void createTrackletsFromTripletsP2(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::tracklets& trackletsInGPU/*,unsigned int *index_gpu*/,unsigned int innerInnerLowerModuleArrayIndex, unsigned int nTriplets)
{
  int innerTripletArrayIndex = (blockIdx.x * blockDim.x + threadIdx.x);// % nTriplets;
  int outerTripletArrayIndex = (blockIdx.y * blockDim.y + threadIdx.y);// / nTriplets;
  if(innerTripletArrayIndex >= nTriplets) return;

  //outer inner lower module array indices should be obtained from the partner module of the inner Triplet's outer lower module
  unsigned int innerTripletIndex = innerInnerLowerModuleArrayIndex * N_MAX_TRIPLETS_PER_MODULE + innerTripletArrayIndex;
  unsigned int outerInnerInnerLowerModuleIndex = modulesInGPU.reverseLookupLowerModuleIndices[tripletsInGPU.lowerModuleIndices[3 * innerTripletIndex + 1]];//same as innerOuterInnerLowerModuleIndex
        if(outerTripletArrayIndex < fminf(tripletsInGPU.nTriplets[outerInnerInnerLowerModuleIndex],N_MAX_TRIPLETS_PER_MODULE))
        {
            unsigned int outerTripletIndex = outerInnerInnerLowerModuleIndex * N_MAX_TRIPLETS_PER_MODULE + outerTripletArrayIndex;
            unsigned int innerOuterSegmentIndex = tripletsInGPU.segmentIndices[2 * innerTripletIndex + 1];
            unsigned int outerInnerSegmentIndex = tripletsInGPU.segmentIndices[2 * outerTripletIndex];

            if(innerOuterSegmentIndex == outerInnerSegmentIndex)
            {
              unsigned int innerSegmentIndex = tripletsInGPU.segmentIndices[2 * innerTripletIndex];
              unsigned int outerSegmentIndex = tripletsInGPU.segmentIndices[2 * outerTripletIndex + 1];
              unsigned int innerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[innerSegmentIndex];
              unsigned int outerInnerLowerModuleIndex = segmentsInGPU.innerLowerModuleIndices[outerSegmentIndex];
              unsigned int outerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[outerSegmentIndex];
              float zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta;
              unsigned int innerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[innerInnerLowerModuleArrayIndex];

              float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;
              bool success = runTrackletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, innerInnerLowerModuleIndex, innerOuterLowerModuleIndex, outerInnerLowerModuleIndex, outerOuterLowerModuleIndex, innerSegmentIndex, outerSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, N_MAX_SEGMENTS_PER_MODULE); //might want to send the other two module indices and the anchor hits also to save memory accesses

              if(success)
              {
                   unsigned int trackletModuleIndex = atomicAdd(&trackletsInGPU.nTracklets[innerInnerLowerModuleArrayIndex],1);
                   if(trackletModuleIndex >= N_MAX_TRACKLETS_PER_MODULE)
                   {
                       #ifdef Warnings
                       if(trackletModuleIndex == N_MAX_TRACKLETS_PER_MODULE)
                           printf("Tracklet excess alert! Module index = %d\n",innerInnerLowerModuleIndex);
                       #endif
                   }
                   else
                   {
                       unsigned int trackletIndex = innerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + trackletModuleIndex;
                        #ifdef CUT_VALUE_DEBUG
                       addTrackletToMemory(trackletsInGPU,innerSegmentIndex,outerSegmentIndex,innerInnerLowerModuleIndex,innerOuterLowerModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, trackletIndex);
                        #else
                       addTrackletToMemory(trackletsInGPU,innerSegmentIndex,outerSegmentIndex,innerInnerLowerModuleIndex,innerOuterLowerModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,trackletIndex);
                        #endif
                   }
              }
            }
        }
}
#endif
#ifndef NESTED_PARA
__global__ void createPixelTrackletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::pixelTracklets& pixelTrackletsInGPU, unsigned int* threadIdx_gpu, unsigned int *threadIdx_gpu_offset)
{
  int outerInnerLowerModuleArrayIndex = threadIdx_gpu[blockIdx.y * blockDim.y + threadIdx.y];
  if(outerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;

  unsigned int outerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[outerInnerLowerModuleArrayIndex];
  unsigned int pixelModuleIndex = *modulesInGPU.nModules - 1; //last dude
  unsigned int pixelLowerModuleArrayIndex = modulesInGPU.reverseLookupLowerModuleIndices[pixelModuleIndex]; //should be the same as nLowerModules
  unsigned int nInnerSegments = segmentsInGPU.nSegments[pixelModuleIndex] > N_MAX_PIXEL_SEGMENTS_PER_MODULE ? N_MAX_PIXEL_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[pixelModuleIndex];
  unsigned int nOuterSegments = segmentsInGPU.nSegments[outerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[outerInnerLowerModuleIndex];
  if(nOuterSegments == 0) return;
  if(nInnerSegments == 0) return;
  if(modulesInGPU.moduleType[outerInnerLowerModuleIndex] == SDL::TwoS) return; //REMOVES 2S-2S

  int innerSegmentArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
  int outerSegmentArrayIndex = threadIdx_gpu_offset[blockIdx.y * blockDim.y + threadIdx.y];
  if(innerSegmentArrayIndex >= nInnerSegments) return;
  if(outerSegmentArrayIndex >= nOuterSegments) return;
  unsigned int innerSegmentIndex = pixelModuleIndex * N_MAX_SEGMENTS_PER_MODULE + innerSegmentArrayIndex;
  unsigned int outerSegmentIndex = outerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + outerSegmentArrayIndex;
  unsigned int outerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[outerSegmentIndex];
  if(modulesInGPU.moduleType[outerOuterLowerModuleIndex] == SDL::TwoS) return; //REMOVES PS-2S
  float zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta;

  float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;
  bool success = runPixelTrackletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, pixelModuleIndex, pixelModuleIndex, outerInnerLowerModuleIndex, outerOuterLowerModuleIndex, innerSegmentIndex, outerSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, N_MAX_SEGMENTS_PER_MODULE); //might want to send the other two module indices and the anchor hits also to save memory accesses
  if(success)
    {
      unsigned int trackletModuleIndex = atomicAdd(pixelTrackletsInGPU.nPixelTracklets, 1);
      if(trackletModuleIndex >= N_MAX_PIXEL_TRACKLETS_PER_MODULE)
        {
            #ifdef Warnings
	  if(trackletModuleIndex == N_MAX_PIXEL_TRACKLETS_PER_MODULE)
	    printf("Pixel Tracklet excess alert! Module index = %d\n",pixelModuleIndex);
            #endif
        }
      else
        {
	  unsigned int trackletIndex = trackletModuleIndex;
#ifdef CUT_VALUE_DEBUG
	  addPixelTrackletToMemory(pixelTrackletsInGPU,innerSegmentIndex,outerSegmentIndex,pixelModuleIndex,pixelModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, trackletIndex);
#else
      float eta = segmentsInGPU.eta[innerSegmentIndex];
      float phi = segmentsInGPU.phi[innerSegmentIndex];
      float pt = segmentsInGPU.ptIn[innerSegmentIndex];
	  addPixelTrackletToMemory(pixelTrackletsInGPU,innerSegmentIndex,outerSegmentIndex,pixelModuleIndex,pixelModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,trackletIndex,pt,eta,phi,0,0);
#endif
        }
    }
}

__device__ bool inline checkHits(unsigned int hit1, unsigned int hit2){

        if(hit1 == hit2){return true;}
        else {return false;}
        //float  x1 = hitsInGPU.xs[hit1];
        //float  y1 = hitsInGPU.ys[hit1];
        //float  z1 = hitsInGPU.zs[hit1];
        //float  x2 = hitsInGPU.xs[hit2];
        //float  y2 = hitsInGPU.ys[hit2];
        //float  z2 = hitsInGPU.zs[hit2];
        //float  dx = x1-x2;
        //float  dy = y1-y2;
        //float  dz = z1-z2;
        //float dR2 = dx*dx + dy*dy + dz*dz; 
        //if (dR2 < 0.0000000001){return true;}
        //else{ return false;}
}
__global__ void createPixelTrackletsInGPUFromMap(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::pixelTracklets& pixelTrackletsInGPU, unsigned int* connectedPixelSize, unsigned int* connectedPixelIndex,unsigned int nInnerSegs,unsigned int* seg_pix_gpu, unsigned int* seg_pix_gpu_offset)
{
  //newgrid with map
  int segmentArrayIndex = seg_pix_gpu_offset[blockIdx.x * blockDim.x + threadIdx.x];// segment loop; this segent
  int pixelArrayIndex = seg_pix_gpu[blockIdx.x * blockDim.x + threadIdx.x];// pixel loop; this pixel
  if(pixelArrayIndex >= nInnerSegs) return;// don't exceed # of pLS
  if( segmentArrayIndex >= connectedPixelSize[pixelArrayIndex]) return; // don't exceed # connected segment modules for this pixel

  unsigned int outerInnerLowerModuleArrayIndex;// This will be the index of the module that connects to this pixel.
    unsigned int temp = connectedPixelIndex[pixelArrayIndex]+segmentArrayIndex; //gets module index for segment
    outerInnerLowerModuleArrayIndex = modulesInGPU.connectedPixels[temp]; //gets module index for segment
  if(outerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;
  unsigned int outerInnerLowerModuleIndex = /*modulesInGPU.lowerModuleIndices[*/outerInnerLowerModuleArrayIndex;//];

  unsigned int pixelModuleIndex = *modulesInGPU.nModules - 1; //last dude
  unsigned int pixelLowerModuleArrayIndex = modulesInGPU.reverseLookupLowerModuleIndices[pixelModuleIndex]; //should be the same as nLowerModules
  unsigned int nOuterSegments = segmentsInGPU.nSegments[outerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[outerInnerLowerModuleIndex];
  if(nOuterSegments == 0) return;
  if(modulesInGPU.moduleType[outerInnerLowerModuleIndex] == SDL::TwoS) return; //REMOVES 2S-2S

//  int outerSegmentArrayIndex = blockIdx.z * blockDim.z + threadIdx.z;
  int outerSegmentArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;
  if(outerSegmentArrayIndex >= nOuterSegments) return;
  unsigned int innerSegmentIndex = pixelModuleIndex * N_MAX_SEGMENTS_PER_MODULE + pixelArrayIndex;
  unsigned int outerSegmentIndex = outerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + outerSegmentArrayIndex;
  unsigned int outerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[outerSegmentIndex];
  if(modulesInGPU.moduleType[outerOuterLowerModuleIndex] == SDL::TwoS) return; //REMOVES PS-2S
  float zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta;

  float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;
  bool success = runPixelTrackletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, pixelModuleIndex, pixelModuleIndex, outerInnerLowerModuleIndex, outerOuterLowerModuleIndex, innerSegmentIndex, outerSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, N_MAX_SEGMENTS_PER_MODULE); //might want to send the other two module indices and the anchor hits also to save memory accesses
  if(success)
    {
//        printf("layer %d\n",modulesInGPU.layers[outerInnerLowerModuleIndex]);
        short layer2_adjustment;
        if(modulesInGPU.layers[outerInnerLowerModuleIndex] == 1){layer2_adjustment = 1;} //get upper segment to be in second layer
        else if( modulesInGPU.layers[outerInnerLowerModuleIndex] == 2){layer2_adjustment = 0;} // get lower segment to be in second layer
        else{return;} // ignore anything else
        float phi = hitsInGPU.phis[mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*outerSegmentIndex+layer2_adjustment]]]; 
        float eta = hitsInGPU.etas[mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*outerSegmentIndex+layer2_adjustment]]]; 
      float eta_pix = segmentsInGPU.eta[pixelArrayIndex];
      float phi_pix = segmentsInGPU.phi[pixelArrayIndex];
      //printf("diff %e %e %e %e\n",eta,eta1,phi,phi1);
      float pt = segmentsInGPU.ptIn[pixelArrayIndex];
    //int dup = -1;
//    for (unsigned int jx=0; jx<*pixelTrackletsInGPU.nPixelTracklets; jx++){
//        float eta1 = pixelTrackletsInGPU.eta[jx];
//        float phi1 = pixelTrackletsInGPU.phi[jx];
//        //float pt1 =  pixelTrackletsInGPU.pt[jx];
//        float dEta = abs(eta-eta1);
//        float dPhi = abs(phi-phi1);
//        if(dPhi > M_PI){dPhi = dPhi - 2*M_PI;}
//        //if( dEta> 0.03){continue;}
//        //if( dPhi > 0.03){continue;}
//        float dR2 = dEta*dEta + dPhi*dPhi; 
//        if(dR2 < 0.001){return;} // 0.0001(05) gives dup<1(2)% eff ~ 91(92)%
//        unsigned int hit1_1 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*innerSegmentIndex]];// inner seg (pixel) inner md inner hit
//        unsigned int hit1_2 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*innerSegmentIndex+1]];// inner seg (pixel) outer md inner hit
//        unsigned int hit1_3 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*innerSegmentIndex]+1];// inner seg inner md outer hit
//        unsigned int hit1_4 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*innerSegmentIndex+1]+1];// inner seg outer md outer hit
//        unsigned int hit1_5 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*outerSegmentIndex]];// outer seg inner md inner hit
//        unsigned int hit1_6 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*outerSegmentIndex+1]];// outer seg outer md inner hit
//        unsigned int hit1_7 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*outerSegmentIndex]+1];// outer seg inner md outer hit
//        unsigned int hit1_8 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*outerSegmentIndex+1]+1];// outer seg outer md outer hit
//
//        unsigned int hit2_1 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx]]]; // inner seg (pixel) inner md inner hit
//        unsigned int hit2_2 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx]+1]];// inner seg outer md inner hit
//        unsigned int hit2_3 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx]]+1]; // inner seg (pixel) inner md outer hit 
//        unsigned int hit2_4 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx]+1]+1];// inner seg outer md outer hit
//        unsigned int hit2_5 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx+1]]];// outer seg inner md inner hit
//        unsigned int hit2_6 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx+1]+1]];// outer seg outer md innher hit 
//        unsigned int hit2_7 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx+1]]+1];// outer seg inner md outer hit
//        unsigned int hit2_8 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx+1]+1]+1];// outer seg outer md outer hit
//        //check pixel hits against each other
//        bool matched_11, matched_12, matched_13, matched_14;
//        matched_11 = checkHits(hit1_1,hit2_1);
//        matched_12 = checkHits(hit1_1,hit2_2);
//        matched_13 = checkHits(hit1_1,hit2_3);
//        matched_14 = checkHits(hit1_1,hit2_4);
//        bool matched_21, matched_22, matched_23, matched_24;
//        matched_21 = checkHits(hit1_2,hit2_1);
//        matched_22 = checkHits(hit1_2,hit2_2);
//        matched_23 = checkHits(hit1_2,hit2_3);
//        matched_24 = checkHits(hit1_2,hit2_4);
//        bool matched_31, matched_32, matched_33, matched_34;
//        matched_31 = checkHits(hit1_3,hit2_1);
//        matched_32 = checkHits(hit1_3,hit2_2);
//        matched_33 = checkHits(hit1_3,hit2_3);
//        matched_34 = checkHits(hit1_3,hit2_4);
//        bool matched_41, matched_42, matched_43, matched_44;
//        matched_41 = checkHits(hit1_4,hit2_1);
//        matched_42 = checkHits(hit1_4,hit2_2);
//        matched_43 = checkHits(hit1_4,hit2_3);
//        matched_44 = checkHits(hit1_4,hit2_4);
//        short matched_1 = matched_11 || matched_12 || matched_13 || matched_14;
//        short matched_2 = matched_21 || matched_22 || matched_23 || matched_24;
//        short matched_3 = matched_31 || matched_32 || matched_33 || matched_34;
//        short matched_4 = matched_41 || matched_42 || matched_43 || matched_44;
//        if (matched_1+matched_2+matched_3+matched_4 <= 2){
//        continue;}
//        bool matched_51, matched_52, matched_53, matched_54;
//        matched_51 = checkHits(hit1_5,hit2_5);
//        matched_52 = checkHits(hit1_5,hit2_6);
//        matched_53 = checkHits(hit1_5,hit2_7);
//        matched_54 = checkHits(hit1_5,hit2_8);
//        bool matched_61, matched_62, matched_63, matched_64;
//        matched_61 = checkHits(hit1_6,hit2_5);
//        matched_62 = checkHits(hit1_6,hit2_6);
//        matched_63 = checkHits(hit1_6,hit2_7);
//        matched_64 = checkHits(hit1_6,hit2_8);
//        bool matched_71, matched_72, matched_73, matched_74;
//        matched_71 = checkHits(hit1_7,hit2_5);
//        matched_72 = checkHits(hit1_7,hit2_6);
//        matched_73 = checkHits(hit1_7,hit2_7);
//        matched_74 = checkHits(hit1_7,hit2_8);
//        bool matched_81, matched_82, matched_83, matched_84;
//        matched_81 = checkHits(hit1_8,hit2_5);
//        matched_82 = checkHits(hit1_8,hit2_6);
//        matched_83 = checkHits(hit1_8,hit2_7);
//        matched_84 = checkHits(hit1_8,hit2_8);
//        short matched_5 = matched_51 || matched_52 || matched_53 || matched_54;
//        short matched_6 = matched_61 || matched_62 || matched_63 || matched_64;
//        short matched_7 = matched_71 || matched_72 || matched_73 || matched_74;
//        short matched_8 = matched_81 || matched_82 || matched_83 || matched_84;
//        if (matched_1+matched_2+matched_3+matched_4+matched_5+matched_6+matched_7+matched_8 < 7){
//        continue;} 
//        
//        return;
//    }
      unsigned int trackletModuleIndex = atomicAdd(pixelTrackletsInGPU.nPixelTracklets, 1);
      if(trackletModuleIndex >= N_MAX_PIXEL_TRACKLETS_PER_MODULE)
        {
            #ifdef Warnings
	  if(trackletModuleIndex == N_MAX_PIXEL_TRACKLETS_PER_MODULE)
	    printf("Pixel Tracklet excess alert! Module index = %d\n",pixelModuleIndex);
            #endif
        }
      else
        {
	  unsigned int trackletIndex = trackletModuleIndex;
#ifdef CUT_VALUE_DEBUG
	  addPixelTrackletToMemory(pixelTrackletsInGPU,innerSegmentIndex,outerSegmentIndex,pixelModuleIndex,pixelModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, trackletIndex);
#else
	    addPixelTrackletToMemory(pixelTrackletsInGPU,innerSegmentIndex,outerSegmentIndex,pixelModuleIndex,pixelModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,trackletIndex,pt,eta,phi,eta_pix,phi_pix);
#endif
        }
    }
}
__device__ int duplicateCounter_TC =0;
__global__ void removeDupTrackCandidates(struct SDL::trackCandidates& trackCandidatesInGPU, struct SDL::modules& modulesInGPU)
{
    int dup_count=0;
    for(unsigned int lowmod1=blockIdx.x*blockDim.x+threadIdx.x; lowmod1<=*modulesInGPU.nLowerModules;lowmod1+=blockDim.x*gridDim.x){
      for(unsigned int ix1=blockIdx.y*blockDim.y+threadIdx.y; ix1<trackCandidatesInGPU.nTrackCandidates[lowmod1]; ix1+=blockDim.y*gridDim.y){
        bool isDup = false;
        unsigned int ix = modulesInGPU.trackCandidateModuleIndices[lowmod1] + ix1;
        if(trackCandidatesInGPU.isDup[ix]){continue;}
        float eta1 = trackCandidatesInGPU.eta[ix];
        float phi1 = trackCandidatesInGPU.phi[ix];
        for(unsigned int lowmod=0; lowmod<=*modulesInGPU.nLowerModules;lowmod++){
          for(unsigned int jx1=0; jx1<trackCandidatesInGPU.nTrackCandidates[lowmod]; jx1++){
            unsigned int jx = modulesInGPU.trackCandidateModuleIndices[lowmod] + jx1;
            if(ix>=jx){continue;}
            if(trackCandidatesInGPU.isDup[jx]){continue;}
            //float pt2  = trackCandidatesInGPU.pt[jx];
            float eta2 = trackCandidatesInGPU.eta[jx];
            float phi2 = trackCandidatesInGPU.phi[jx];
            float dEta = abs(eta1-eta2);
            float dPhi = abs(phi1-phi2);
            if(dPhi > M_PI){dPhi = dPhi - 2*M_PI;}
            if (abs(eta1-eta2) > 0.08){continue;}
            if (abs(phi1-phi2) > 0.08){continue;}
            float dR2 = dEta*dEta + dPhi*dPhi; 
            if(dR2 < .005){
              isDup=true;break;
            }
          }
          if(isDup){break;}
        }
        if(isDup){rmTrackCandidateToMemory(trackCandidatesInGPU,ix);dup_count++;}
      }
  }
//  atomicAdd(&duplicateCounter_TC,dup_count);
//  printf("dup count: %d %d\n",dup_count,duplicateCounter_TC);
}
__device__ bool checkDupTrackCandidates(struct SDL::trackCandidates& trackCandidatesInGPU, float pt1, float eta1, float phi1)
{
 //   int dup_count=0;
    for (unsigned int jx=0; jx<*trackCandidatesInGPU.nTrackCandidates; jx++){
    //for (unsigned int jx=blockIdx.y*blockDim.y+threadIdx.y; jx<*pixelTrackletsInGPU.nPixelTracklets; jx+=blockDim.y*gridDim.y){
        //if(ix>=jx){continue;}
        //if(trackCandidatesInGPU.isDup[jx]){continue;}
        //float pt2  = trackCandidatesInGPU.pt[jx];
        float eta2 = trackCandidatesInGPU.eta[jx];
        float phi2 = trackCandidatesInGPU.phi[jx];
        float dEta = abs(eta1-eta2);
        float dPhi = abs(phi1-phi2);
        if(dPhi > M_PI){dPhi = dPhi - 2*M_PI;}
        //if (abs(eta1-eta2) > 0.03){continue;}
        //if (abs(phi1-phi2) > 0.03){continue;}
        float dR2 = dEta*dEta + dPhi*dPhi; 
        if(dR2 < 0.1){
          return true;//isDup=true;break;
        }
    }
    return false;
    //if(isDup){rmPixelTrackletToMemory(pixelTrackletsInGPU,ix);dup_count++;}
    //if(isDup){addPixelTrackletToMemory(pixelTrackletsInGPU,0,0,0,0,0,0,0,0,0,0,0,0,0,ix);}
//atomicAdd(&duplicateCounter_pT2,dup_count);
//printf("dup count: %d %d\n",dup_count,duplicateCounter_pT2);
}
__device__ int duplicateCounter_pT2 =0;
__global__ void removeDupPixelTrackletsInGPUFromMap(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::pixelTracklets& pixelTrackletsInGPU)
{
    int dup_count=0;
    //for (unsigned int ix=0; ix<*pixelTrackletsInGPU.nPixelTracklets; ix++){
    for (unsigned int ix=blockIdx.x*blockDim.x+threadIdx.x; ix<*pixelTrackletsInGPU.nPixelTracklets; ix+=blockDim.x*gridDim.x){
      bool isDup = false;
      if(pixelTrackletsInGPU.isDup[ix]){continue;}
//      float pt1 = pixelTrackletsInGPU.pt[ix];
      float eta1_pix = pixelTrackletsInGPU.eta_pix[ix]; 
      float phi1_pix = pixelTrackletsInGPU.phi_pix[ix]; 
      float eta1 = pixelTrackletsInGPU.eta[ix];
      float phi1 = pixelTrackletsInGPU.phi[ix];
      for (unsigned int jx=ix+1; jx<*pixelTrackletsInGPU.nPixelTracklets-1; jx++){
        if(pixelTrackletsInGPU.isDup[jx]){continue;}
        float eta2_pix = pixelTrackletsInGPU.eta_pix[jx]; 
        float phi2_pix = pixelTrackletsInGPU.phi_pix[jx]; 
        float dEta_pix = abs(eta1_pix-eta2_pix);
        float dPhi_pix = abs(phi1_pix-phi2_pix);
        if(dPhi_pix > M_PI){dPhi_pix = dPhi_pix - 2*M_PI;}
        if (dEta_pix > 0.03){continue;}
        if (dPhi_pix > 0.03){continue;}
        float dR2_pix = dEta_pix*dEta_pix + dPhi_pix*dPhi_pix; 
        if(dR2_pix < 0.001){
          isDup=true;break;
        }

        float eta2 = pixelTrackletsInGPU.eta[jx];
        float phi2 = pixelTrackletsInGPU.phi[jx];
        float dEta = abs(eta1-eta2);
        float dPhi = abs(phi1-phi2);
        if(dPhi > M_PI){dPhi = dPhi - 2*M_PI;}
        if (dEta > 0.03){continue;}
        if (dPhi > 0.03){continue;}
        float dR2 = dEta*dEta + dPhi*dPhi; 
        if(dR2 < 0.001){
          isDup=true;break;
        }
//        unsigned int hit1_1 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*ix]]];// inner seg (pixel) inner md inner hit
//        unsigned int hit1_2 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*ix]+1]];// inner seg (pixel) outer md inner hit
//        unsigned int hit1_3 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*ix]]+1];// inner seg inner md outer hit
//        unsigned int hit1_4 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*ix]+1]+1];// inner seg outer md outer hit
//        unsigned int hit1_5 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*ix+1]]];// outer seg inner md inner hit
//        unsigned int hit1_6 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*ix+1]+1]];// outer seg outer md inner hit
//        unsigned int hit1_7 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*ix+1]]+1];// outer seg inner md outer hit
//        unsigned int hit1_8 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*ix+1]+1]+1];// outer seg outer md outer hit
//
//        unsigned int hit2_1 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx]]]; // inner seg (pixel) inner md inner hit
//        unsigned int hit2_2 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx]+1]];// inner seg outer md inner hit
//        unsigned int hit2_3 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx]]+1]; // inner seg (pixel) inner md outer hit 
//        unsigned int hit2_4 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx]+1]+1];// inner seg outer md outer hit
//        unsigned int hit2_5 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx+1]]];// outer seg inner md inner hit
//        unsigned int hit2_6 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx+1]+1]];// outer seg outer md innher hit 
//        unsigned int hit2_7 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx+1]]+1];// outer seg inner md outer hit
//        unsigned int hit2_8 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*pixelTrackletsInGPU.segmentIndices[2*jx+1]+1]+1];// outer seg outer md outer hit
//        //check pixel hits against each other
//        bool matched_11, matched_12, matched_13, matched_14;
//        matched_11 = checkHits(hit1_1,hit2_1);
//        matched_12 = checkHits(hit1_1,hit2_2);
//        matched_13 = checkHits(hit1_1,hit2_3);
//        matched_14 = checkHits(hit1_1,hit2_4);
//        bool matched_21, matched_22, matched_23, matched_24;
//        matched_21 = checkHits(hit1_2,hit2_1);
//        matched_22 = checkHits(hit1_2,hit2_2);
//        matched_23 = checkHits(hit1_2,hit2_3);
//        matched_24 = checkHits(hit1_2,hit2_4);
//        bool matched_31, matched_32, matched_33, matched_34;
//        matched_31 = checkHits(hit1_3,hit2_1);
//        matched_32 = checkHits(hit1_3,hit2_2);
//        matched_33 = checkHits(hit1_3,hit2_3);
//        matched_34 = checkHits(hit1_3,hit2_4);
//        bool matched_41, matched_42, matched_43, matched_44;
//        matched_41 = checkHits(hit1_4,hit2_1);
//        matched_42 = checkHits(hit1_4,hit2_2);
//        matched_43 = checkHits(hit1_4,hit2_3);
//        matched_44 = checkHits(hit1_4,hit2_4);
//        short matched_1 = matched_11 || matched_12 || matched_13 || matched_14;
//        short matched_2 = matched_21 || matched_22 || matched_23 || matched_24;
//        short matched_3 = matched_31 || matched_32 || matched_33 || matched_34;
//        short matched_4 = matched_41 || matched_42 || matched_43 || matched_44;
//        //if (matched_1+matched_2+matched_3+matched_4 <= 2){
//        //continue;}
//        bool matched_51, matched_52, matched_53, matched_54;
//        matched_51 = checkHits(hit1_5,hit2_5);
//        matched_52 = checkHits(hit1_5,hit2_6);
//        matched_53 = checkHits(hit1_5,hit2_7);
//        matched_54 = checkHits(hit1_5,hit2_8);
//        bool matched_61, matched_62, matched_63, matched_64;
//        matched_61 = checkHits(hit1_6,hit2_5);
//        matched_62 = checkHits(hit1_6,hit2_6);
//        matched_63 = checkHits(hit1_6,hit2_7);
//        matched_64 = checkHits(hit1_6,hit2_8);
//        bool matched_71, matched_72, matched_73, matched_74;
//        matched_71 = checkHits(hit1_7,hit2_5);
//        matched_72 = checkHits(hit1_7,hit2_6);
//        matched_73 = checkHits(hit1_7,hit2_7);
//        matched_74 = checkHits(hit1_7,hit2_8);
//        bool matched_81, matched_82, matched_83, matched_84;
//        matched_81 = checkHits(hit1_8,hit2_5);
//        matched_82 = checkHits(hit1_8,hit2_6);
//        matched_83 = checkHits(hit1_8,hit2_7);
//        matched_84 = checkHits(hit1_8,hit2_8);
//        short matched_5 = matched_51 || matched_52 || matched_53 || matched_54;
//        short matched_6 = matched_61 || matched_62 || matched_63 || matched_64;
//        short matched_7 = matched_71 || matched_72 || matched_73 || matched_74;
//        short matched_8 = matched_81 || matched_82 || matched_83 || matched_84;
//        if (matched_1+matched_2+matched_3+matched_4+matched_5+matched_6+matched_7+matched_8 >= 6){
//          isDup=true;break;
//        }
    }
    if(isDup){rmPixelTrackletToMemory(pixelTrackletsInGPU,ix);dup_count++;}
    //if(isDup){addPixelTrackletToMemory(pixelTrackletsInGPU,0,0,0,0,0,0,0,0,0,0,0,0,0,ix);}
  } 
//atomicAdd(&duplicateCounter_pT2,dup_count);
//printf("dup count: %d %d\n",dup_count,duplicateCounter_pT2);
}

#else
__global__ void createPixelTrackletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::pixelTracklets& pixelTrackletsInGPU)
{
    int outerInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x; // loop for modules for segments lower hit
    if(outerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return; // don't exceed number of modules

    unsigned int outerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[outerInnerLowerModuleArrayIndex]; // correspond to module number index
    unsigned int pixelModuleIndex = *modulesInGPU.nModules - 1; // pixel module index
    unsigned int pixelLowerModuleArrayIndex = modulesInGPU.reverseLookupLowerModuleIndices[pixelModuleIndex]; //should be the same as nLowerModules
    unsigned int nInnerSegments = segmentsInGPU.nSegments[pixelModuleIndex] > N_MAX_PIXEL_SEGMENTS_PER_MODULE ? N_MAX_PIXEL_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[pixelModuleIndex]; // number of pLS
    unsigned int nOuterSegments = segmentsInGPU.nSegments[outerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[outerInnerLowerModuleIndex]; // number of segments from module corresponding to each module.
    if(nOuterSegments == 0) return;
    if(nInnerSegments == 0) return;
    if(modulesInGPU.moduleType[outerInnerLowerModuleIndex] == SDL::TwoS) return; //REMOVES 2S-2S

    dim3 nThreads(16,16,1);
    dim3 nBlocks(nInnerSegments % nThreads.x == 0 ? nInnerSegments / nThreads.x : nInnerSegments / nThreads.x + 1, nOuterSegments % nThreads.y == 0 ? nOuterSegments / nThreads.y : nOuterSegments / nThreads.y + 1, 1);

    createPixelTrackletsFromOuterInnerLowerModule<<<nBlocks,nThreads>>>(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, pixelTrackletsInGPU, outerInnerLowerModuleIndex, nInnerSegments, nOuterSegments, pixelModuleIndex, pixelLowerModuleArrayIndex);

}
__global__ void createPixelTrackletsFromOuterInnerLowerModule(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::pixelTracklets& pixelTrackletsInGPU, unsigned int outerInnerLowerModuleIndex, unsigned int nInnerSegments, unsigned int nOuterSegments, unsigned int pixelModuleIndex, unsigned int pixelLowerModuleArrayIndex)
{
    int innerSegmentArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;// looping over pixels
    int outerSegmentArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;//looping over segments
    if(innerSegmentArrayIndex >= nInnerSegments) return; // not over # of pLS
    if(outerSegmentArrayIndex >= nOuterSegments) return; // not over # of segments for this module
    unsigned int innerSegmentIndex = pixelModuleIndex * N_MAX_SEGMENTS_PER_MODULE + innerSegmentArrayIndex; // get this pixel index Just innerSegmentArrayIndex'th value (1-pLS)
    unsigned int outerSegmentIndex = outerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + outerSegmentArrayIndex; // get this segment Index for this this module
    unsigned int outerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[outerSegmentIndex]; // get corresponding outer module index for this segment
    if(modulesInGPU.moduleType[outerOuterLowerModuleIndex] == SDL::TwoS) return; //REMOVES PS-2S
    float zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta;
    float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;
    bool success = runPixelTrackletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, pixelModuleIndex, pixelModuleIndex, outerInnerLowerModuleIndex, outerOuterLowerModuleIndex, innerSegmentIndex, outerSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, N_MAX_SEGMENTS_PER_MODULE); //might want to send the other two module indices and the anchor hits also to save memory accesses

    if(success)
    {
        unsigned int trackletModuleIndex = atomicAdd(pixelTrackletsInGPU.nPixelTracklets, 1);
        if(trackletModuleIndex >= N_MAX_PIXEL_TRACKLETS_PER_MODULE)
        {
            #ifdef Warnings
            if(trackletModuleIndex == N_MAX_PIXEL_TRACKLETS_PER_MODULE)
                printf("Pixel Tracklet excess alert! Module index = %d\n",pixelModuleIndex);
            #endif
        }
        else
        {
            unsigned int trackletIndex = trackletModuleIndex;
#ifdef CUT_VALUE_DEBUG
                addPixelTrackletToMemory(pixelTrackletsInGPU,innerSegmentIndex,outerSegmentIndex,pixelModuleIndex,pixelModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, trackletIndex);

#else
      float eta = segmentsInGPU.eta[innerSegmentIndex];
      float phi = segmentsInGPU.eta[innerSegmentIndex];
      float pt = segmentsInGPU.eta[innerSegmentIndex];
            addPixelTrackletToMemory(pixelTrackletsInGPU,innerSegmentIndex,outerSegmentIndex,pixelModuleIndex,pixelModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,trackletIndex,pt,eta,phi,0,0);
#endif
        }
    }
}
#endif

__global__ void createTrackletsWithAGapFromInnerInnerLowerModule(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::tracklets& trackletsInGPU, unsigned int innerInnerLowerModuleIndex, unsigned int nInnerSegments, unsigned int innerInnerLowerModuleArrayIndex)
{
    //Proposal 1 : Inner kernel takes care of both loops
    int xAxisIndex = blockIdx.x * blockDim.x + threadIdx.x;
    int innerSegmentArrayIndex =  blockIdx.y * blockDim.y + threadIdx.y;
    int outerSegmentArrayIndex = blockIdx.z * blockDim.z + threadIdx.z;

    if(innerSegmentArrayIndex >= nInnerSegments) return;

    int middleLowerModuleArrayIndex = xAxisIndex / MAX_CONNECTED_MODULES;
    int outerInnerLowerModuleArrayIndex = xAxisIndex % MAX_CONNECTED_MODULES;

    unsigned int innerSegmentIndex = innerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + innerSegmentArrayIndex;
    unsigned int innerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[innerSegmentIndex];

    //first check for middle modules
    unsigned int nMiddleLowerModules = modulesInGPU.nConnectedModules[innerOuterLowerModuleIndex];
    if(middleLowerModuleArrayIndex >= nMiddleLowerModules) return;

    unsigned int middleLowerModuleIndex = modulesInGPU.moduleMap[innerOuterLowerModuleIndex * MAX_CONNECTED_MODULES + middleLowerModuleArrayIndex];

    //second check for outerInnerLowerMoules
    unsigned int nOuterInnerLowerModules = modulesInGPU.nConnectedModules[middleLowerModuleIndex];
    if(outerInnerLowerModuleArrayIndex >= nOuterInnerLowerModules) return;

    unsigned int outerInnerLowerModuleIndex = modulesInGPU.moduleMap[middleLowerModuleIndex * MAX_CONNECTED_MODULES + outerInnerLowerModuleArrayIndex];

    unsigned int nOuterSegments = segmentsInGPU.nSegments[outerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[outerInnerLowerModuleIndex];
    if(outerSegmentArrayIndex >= nOuterSegments) return;

    unsigned int outerSegmentIndex = outerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + outerSegmentArrayIndex;

    //for completeness - outerOuterLowerModuleIndex
    unsigned int outerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[outerSegmentIndex];

    //with both segment indices obtained, run the tracklet algorithm

   float zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut, pt_beta;
    float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;
    bool success = runTrackletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, innerInnerLowerModuleIndex, innerOuterLowerModuleIndex, outerInnerLowerModuleIndex, outerOuterLowerModuleIndex, innerSegmentIndex, outerSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, N_MAX_SEGMENTS_PER_MODULE); //might want to send the other two module indices and the anchor hits also to save memory accesses
   if(success)
   {
        unsigned int trackletModuleIndex = atomicAdd(&trackletsInGPU.nTracklets[innerInnerLowerModuleArrayIndex],1);
        if(trackletModuleIndex >= N_MAX_TRACKLETS_PER_MODULE)
        {
            #ifdef Warnings
            if(trackletModuleIndex == N_MAX_TRACKLETS_PER_MODULE)
                 printf("T4x excess alert! Module index = %d\n",innerInnerLowerModuleIndex);
            #endif
        }
        else
        {

            unsigned int trackletIndex = innerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + trackletModuleIndex;
#ifdef CUT_VALUE_DEBUG
            addTrackletToMemory(trackletsInGPU,innerSegmentIndex,outerSegmentIndex,innerInnerLowerModuleIndex,innerOuterLowerModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, trackletIndex);

#else
            addTrackletToMemory(trackletsInGPU,innerSegmentIndex,outerSegmentIndex,innerInnerLowerModuleIndex,innerOuterLowerModuleIndex,outerInnerLowerModuleIndex,outerOuterLowerModuleIndex,zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta,trackletIndex);
#endif

        }
   }
}

__global__ void createTrackletsWithAGapInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::tracklets& trackletsInGPU)
{
    //outer kernel for proposal 1
    int innerInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    if(innerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;
    unsigned int innerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[innerInnerLowerModuleArrayIndex];
    unsigned int nInnerSegments = segmentsInGPU.nSegments[innerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[innerInnerLowerModuleIndex];
    if(nInnerSegments == 0) return;

    dim3 nThreads(1,16,16);
    dim3 nBlocks((MAX_CONNECTED_MODULES * MAX_CONNECTED_MODULES) % nThreads.x  == 0 ? (MAX_CONNECTED_MODULES * MAX_CONNECTED_MODULES) / nThreads.x : (MAX_CONNECTED_MODULES * MAX_CONNECTED_MODULES) / nThreads.x + 1 ,nInnerSegments % nThreads.y == 0 ? nInnerSegments/nThreads.y : nInnerSegments/nThreads.y + 1,N_MAX_SEGMENTS_PER_MODULE % nThreads.z == 0 ? N_MAX_SEGMENTS_PER_MODULE/nThreads.z : N_MAX_SEGMENTS_PER_MODULE/nThreads.z + 1);

    createTrackletsWithAGapFromInnerInnerLowerModule<<<nBlocks,nThreads>>>(modulesInGPU,hitsInGPU,mdsInGPU,segmentsInGPU,trackletsInGPU,innerInnerLowerModuleIndex,nInnerSegments,innerInnerLowerModuleArrayIndex);

}

#ifndef NESTED_PARA
#ifdef NEWGRID_Trips
__global__ void createTripletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, unsigned int *index_gpu)
{
  int innerInnerLowerModuleArrayIndex = index_gpu[blockIdx.z * blockDim.z + threadIdx.z];
  if(innerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;

  unsigned int innerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[innerInnerLowerModuleArrayIndex];
  unsigned int nConnectedModules = modulesInGPU.nConnectedModules[innerInnerLowerModuleIndex];
  if(nConnectedModules == 0) return;

  unsigned int nInnerSegments = segmentsInGPU.nSegments[innerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[innerInnerLowerModuleIndex];

  int innerSegmentArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;
  int outerSegmentArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;

  if(innerSegmentArrayIndex >= nInnerSegments) return;

  unsigned int innerSegmentIndex = innerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + innerSegmentArrayIndex;

  //middle lower module - outer lower module of inner segment
  unsigned int middleLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[innerSegmentIndex];

  unsigned int nOuterSegments = segmentsInGPU.nSegments[middleLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[middleLowerModuleIndex];
  if(outerSegmentArrayIndex >= nOuterSegments) return;

  unsigned int outerSegmentIndex = middleLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + outerSegmentArrayIndex;
  unsigned int outerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[outerSegmentIndex];

  float zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut, pt_beta;
  float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;

    bool success = runTripletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, innerInnerLowerModuleIndex, middleLowerModuleIndex, outerOuterLowerModuleIndex, innerSegmentIndex, outerSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ);

  if(success)
    {
      unsigned int tripletModuleIndex = atomicAdd(&tripletsInGPU.nTriplets[innerInnerLowerModuleArrayIndex], 1);
      if(tripletModuleIndex >= N_MAX_TRIPLETS_PER_MODULE)
      {
          #ifdef Warnings
          if(tripletModuleIndex == N_MAX_TRIPLETS_PER_MODULE)
              printf("Triplet excess alert! Module index = %d\n",innerInnerLowerModuleIndex);
          #endif
      }
      unsigned int tripletIndex = innerInnerLowerModuleArrayIndex * N_MAX_TRIPLETS_PER_MODULE + tripletModuleIndex;
#ifdef CUT_VALUE_DEBUG

        addTripletToMemory(tripletsInGPU, innerSegmentIndex, outerSegmentIndex, innerInnerLowerModuleIndex, middleLowerModuleIndex, outerOuterLowerModuleIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut,pt_beta, zLo,zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, tripletIndex);

#else
      addTripletToMemory(tripletsInGPU, innerSegmentIndex, outerSegmentIndex, innerInnerLowerModuleIndex, middleLowerModuleIndex, outerOuterLowerModuleIndex, betaIn, betaOut, pt_beta, tripletIndex);
#endif
    }
}
#endif
#else
__global__ void createTripletsFromInnerInnerLowerModule(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, unsigned int innerInnerLowerModuleIndex, unsigned int nInnerSegments, unsigned int nConnectedModules, unsigned int innerInnerLowerModuleArrayIndex)
{
    int innerSegmentArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    int outerSegmentArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;

    if(innerSegmentArrayIndex >= nInnerSegments) return;

    unsigned int innerSegmentIndex = innerInnerLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + innerSegmentArrayIndex;

    //middle lower module - outer lower module of inner segment
    unsigned int middleLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[innerSegmentIndex];

    unsigned int nOuterSegments = segmentsInGPU.nSegments[middleLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[middleLowerModuleIndex];
    if(outerSegmentArrayIndex >= nOuterSegments) return;
    unsigned int outerSegmentIndex = middleLowerModuleIndex * N_MAX_SEGMENTS_PER_MODULE + outerSegmentArrayIndex;
    unsigned int outerOuterLowerModuleIndex = segmentsInGPU.outerLowerModuleIndices[outerSegmentIndex];

    float zOut,rtOut,deltaPhiPos,deltaPhi,betaIn,betaOut,pt_beta;
  float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;

    bool success = runTripletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, innerInnerLowerModuleIndex, middleLowerModuleIndex, outerOuterLowerModuleIndex, innerSegmentIndex, outerSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ);

    if(success)
    {
        unsigned int tripletModuleIndex = atomicAdd(&tripletsInGPU.nTriplets[innerInnerLowerModuleArrayIndex], 1);
        if(tripletModuleIndex >= N_MAX_TRIPLETS_PER_MODULE)
        {
            #ifdef Warnings
            if(tripletModuleIndex == N_MAX_TRIPLETS_PER_MODULE)
                printf("Triplet excess alert! Module index = %d\n",innerInnerLowerModuleIndex);
            #endif
        }
        else
        {
            unsigned int tripletIndex = innerInnerLowerModuleArrayIndex * N_MAX_TRIPLETS_PER_MODULE + tripletModuleIndex;
#ifdef CUT_VALUE_DEBUG

            addTripletToMemory(tripletsInGPU, innerSegmentIndex, outerSegmentIndex, innerInnerLowerModuleIndex, middleLowerModuleIndex, outerOuterLowerModuleIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo,zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ, tripletIndex);

#else
        addTripletToMemory(tripletsInGPU, innerSegmentIndex, outerSegmentIndex, innerInnerLowerModuleIndex, middleLowerModuleIndex, outerOuterLowerModuleIndex, betaIn, betaOut, pt_beta, tripletIndex);
#endif

        }
    }
}

__global__ void createTripletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU)
{
    int innerInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    if(innerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;
    unsigned int innerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[innerInnerLowerModuleArrayIndex];
    unsigned int nInnerSegments = segmentsInGPU.nSegments[innerInnerLowerModuleIndex] > N_MAX_SEGMENTS_PER_MODULE ? N_MAX_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[innerInnerLowerModuleIndex] ;
    if(nInnerSegments == 0) return;

    unsigned int nConnectedModules = modulesInGPU.nConnectedModules[innerInnerLowerModuleIndex];
    if(nConnectedModules == 0) return;

    dim3 nThreads(16,16,1);
    dim3 nBlocks(nInnerSegments % nThreads.x == 0 ? nInnerSegments / nThreads.x : nInnerSegments / nThreads.x + 1, N_MAX_SEGMENTS_PER_MODULE % nThreads.y == 0 ? N_MAX_SEGMENTS_PER_MODULE / nThreads.y : N_MAX_SEGMENTS_PER_MODULE / nThreads.y + 1);

    createTripletsFromInnerInnerLowerModule<<<nBlocks,nThreads>>>(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, tripletsInGPU, innerInnerLowerModuleIndex, nInnerSegments, nConnectedModules, innerInnerLowerModuleArrayIndex);
}
#endif

__global__ void addT5asTrackCandidateInGPU(struct SDL::modules& modulesInGPU,struct SDL::quintuplets& quintupletsInGPU,struct SDL::trackCandidates& trackCandidatesInGPU)
{

  int innerInnerInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    if(innerInnerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules or modulesInGPU.quintupletModuleIndices[innerInnerInnerLowerModuleArrayIndex] == -1) return; 
  unsigned int nQuints = quintupletsInGPU.nQuintuplets[innerInnerInnerLowerModuleArrayIndex];
  if (nQuints > N_MAX_QUINTUPLETS_PER_MODULE) {nQuints = N_MAX_QUINTUPLETS_PER_MODULE;}
  int innerObjectArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;
  if(innerObjectArrayIndex >= nQuints) return;
  int quintupletIndex = modulesInGPU.quintupletModuleIndices[innerInnerInnerLowerModuleArrayIndex] + innerObjectArrayIndex;
  if(quintupletsInGPU.isDup[quintupletIndex]){return;} 
  float pt = quintupletsInGPU.pt[quintupletIndex];
  float eta = quintupletsInGPU.eta[quintupletIndex];
  float phi = quintupletsInGPU.phi[quintupletIndex];
//  if(checkDupTrackCandidates(trackCandidatesInGPU,pt,eta,phi)){return;} 

 
  unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[innerInnerInnerLowerModuleArrayIndex],1);
  atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT5[innerInnerInnerLowerModuleArrayIndex],1);
  unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] + trackCandidateModuleIdx;
//  printf("T5 %e %e %e\n",pt,eta,phi);
  addTrackCandidateToMemory(trackCandidatesInGPU, 4/*track candidate type T5=4*/, quintupletIndex, quintupletIndex, trackCandidateIdx,pt,eta,phi);
}

__global__ void addpT2asTrackCandidateInGPU(struct SDL::modules& modulesInGPU,struct SDL::pixelTracklets& pixelTrackletsInGPU,struct SDL::trackCandidates& trackCandidatesInGPU)
{
  int pixelTrackletArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
  unsigned int pixelLowerModuleArrayIndex = *modulesInGPU.nLowerModules;
  unsigned int nPixelTracklets = *pixelTrackletsInGPU.nPixelTracklets; 
  if(pixelTrackletArrayIndex >= nPixelTracklets) return;
  int pixelTrackletIndex = pixelTrackletArrayIndex;
  if(pixelTrackletsInGPU.isDup[pixelTrackletIndex]){return;} 
  float pt  = pixelTrackletsInGPU.pt[pixelTrackletIndex];
  float eta = pixelTrackletsInGPU.eta[pixelTrackletIndex];
  float phi = pixelTrackletsInGPU.phi[pixelTrackletIndex];
//  if(checkDupTrackCandidates(trackCandidatesInGPU,pt,eta,phi)){return;} 
  unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[pixelLowerModuleArrayIndex],1);
  atomicAdd(trackCandidatesInGPU.nTrackCandidatespT2,1);
  unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[pixelLowerModuleArrayIndex] + trackCandidateModuleIdx;
//  printf("pT2 %e %e %e\n",pt,eta,phi);
  addTrackCandidateToMemory(trackCandidatesInGPU, 3/*track candidate type pT2=3*/, pixelTrackletIndex, pixelTrackletIndex, trackCandidateIdx,pt,eta,phi);
}

__global__ void addpT3asTrackCandidateInGPU(struct SDL::modules& modulesInGPU, struct SDL::pixelTriplets& pixelTripletsInGPU, struct SDL::trackCandidates& trackCandidatesInGPU)
{
  int pixelTripletArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
  unsigned int pixelLowerModuleArrayIndex = *modulesInGPU.nLowerModules;
  unsigned int nPixelTriplets = *pixelTripletsInGPU.nPixelTriplets; 
  if(pixelTripletArrayIndex >= nPixelTriplets) return;
  int pixelTripletIndex = pixelTripletArrayIndex;
  unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[pixelLowerModuleArrayIndex],1);
  atomicAdd(trackCandidatesInGPU.nTrackCandidatespT3,1);
  unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[pixelLowerModuleArrayIndex] + trackCandidateModuleIdx;
  addTrackCandidateToMemory(trackCandidatesInGPU, 5/*track candidate type pT3=5*/, pixelTripletIndex, pixelTripletIndex, trackCandidateIdx,0,0,0);

}


#ifndef NESTED_PARA
__global__ void createPixelTrackCandidatesInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::pixelTracklets& pixelTrackletsInGPU, struct SDL::tracklets& trackletsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::trackCandidates& trackCandidatesInGPU, unsigned int* threadIdx_gpu, unsigned int* threadIdx_gpu_offset)
{
  unsigned int outerInnerInnerLowerModuleArrayIndex = threadIdx_gpu[blockIdx.y * blockDim.y + threadIdx.y];
  if(outerInnerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;
  //FIXME:Cheapo module map - We care about pT4s and pTCs Only if the outerInnerInnerLowerModule is "connected" to the pixel module

  int outerInnerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[outerInnerInnerLowerModuleArrayIndex];
  if(modulesInGPU.moduleType[outerInnerInnerLowerModuleIndex] == SDL::TwoS) return;

  unsigned int pixelLowerModuleArrayIndex = *modulesInGPU.nLowerModules;

  unsigned int nPixelTracklets = *(pixelTrackletsInGPU.nPixelTracklets);
  //capping
  if(nPixelTracklets > N_MAX_PIXEL_TRACKLETS_PER_MODULE)
    nPixelTracklets = N_MAX_PIXEL_TRACKLETS_PER_MODULE;

  unsigned int nOuterLayerTracklets = trackletsInGPU.nTracklets[outerInnerInnerLowerModuleArrayIndex];
  if(nOuterLayerTracklets > N_MAX_TRACKLETS_PER_MODULE)
    {
      nOuterLayerTracklets = N_MAX_TRACKLETS_PER_MODULE;
    }
  unsigned int nOuterLayerTriplets = tripletsInGPU.nTriplets[outerInnerInnerLowerModuleArrayIndex];
  if(nOuterLayerTriplets > N_MAX_TRIPLETS_PER_MODULE)
    {
      nOuterLayerTriplets = N_MAX_TRIPLETS_PER_MODULE;
    }

  unsigned int nThreadsForNestedKernel = max(nOuterLayerTracklets,nOuterLayerTriplets);
  if(nThreadsForNestedKernel == 0) return;

  int pixelTrackletArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;

  int outerObjectArrayIndex = threadIdx_gpu_offset[blockIdx.y * blockDim.y+ threadIdx.y];
  if(pixelTrackletArrayIndex >= nPixelTracklets) return;

  int pixelTrackletIndex = pixelTrackletArrayIndex;
  int outerObjectIndex = 0;
  short trackCandidateType;
  bool success;

  //pT4-T4
  if(outerObjectArrayIndex < nOuterLayerTracklets)
    {
      outerObjectIndex = outerInnerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + outerObjectArrayIndex;

        //part 2 of cheapo module map : only considering tracklets with PS-PS inner segment
        if(modulesInGPU.moduleType[trackletsInGPU.lowerModuleIndices[4 * outerObjectIndex + 1]] == SDL::PS)
        {
	        success = runTrackCandidateDefaultAlgoTwoTracklets(pixelTrackletsInGPU, trackletsInGPU, tripletsInGPU, pixelTrackletIndex, outerObjectIndex, trackCandidateType);
	    if(success)
        {
	        unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[pixelLowerModuleArrayIndex],1);
	        atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT4T4[pixelLowerModuleArrayIndex],1);
	        if(trackCandidateModuleIdx >= N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE)
            {
                #ifdef Warnings
    		  if(innerInnerInnerLowerModuleArrayIndex == *modulesInGPU.nLowerModules && trackCandidateModuleIdx == N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE)
                {

		            printf("Track Candidate excess alert! lower Module array index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                }
                    #endif
            }
	        else
            {
		    if(modulesInGPU.trackCandidateModuleIndices[pixelLowerModuleArrayIndex] == -1)
            {
                #ifdef Warnings
		        printf("Track candidates: no memory for pixel lower module index at %d\n",innerInnerInnerLowerModuleArrayIndex);
                #endif

            }
		  else
		    {
		      unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[pixelLowerModuleArrayIndex] + trackCandidateModuleIdx;
		      addTrackCandidateToMemory(trackCandidatesInGPU, 5/*trackCandidateType*/, pixelTrackletIndex, outerObjectIndex, trackCandidateIdx,0,0,0);
                    }

                }
            }
        }
    }

  //pT4-T3
  if(outerObjectArrayIndex < nOuterLayerTriplets)
    {
      outerObjectIndex = outerInnerInnerLowerModuleArrayIndex * N_MAX_TRIPLETS_PER_MODULE + outerObjectArrayIndex;

      //part 2 of cheapo module map : only considering tracklets with PS-PS inner segment
      if(modulesInGPU.moduleType[tripletsInGPU.lowerModuleIndices[3 * outerObjectIndex + 1]] == SDL::PS)
        {
	  success = runTrackCandidateDefaultAlgoTrackletToTriplet(pixelTrackletsInGPU, trackletsInGPU, tripletsInGPU, pixelTrackletIndex, outerObjectIndex, trackCandidateType);
	  if(success)
            {
	      unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[pixelLowerModuleArrayIndex],1);
	      atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT4T4[pixelLowerModuleArrayIndex],1);
	      if(trackCandidateModuleIdx >= N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE)
                {
                    #ifdef Warnings
		  if(innerInnerInnerLowerModuleArrayIndex == *modulesInGPU.nLowerModules && trackCandidateModuleIdx == N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE)
                    {

		      printf("Track Candidate excess alert! lower Module array index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                    }
                    #endif
                }
	      else
                {
		  if(modulesInGPU.trackCandidateModuleIndices[pixelLowerModuleArrayIndex] == -1)
                    {
                       #ifdef Warnings
		      printf("Track candidates: no memory for pixel lower module index at %d\n",innerInnerInnerLowerModuleArrayIndex);
                       #endif

                    }
		  else
		    {
		      unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[pixelLowerModuleArrayIndex] + trackCandidateModuleIdx;
		      addTrackCandidateToMemory(trackCandidatesInGPU, 6/*trackCandidateType*/, pixelTrackletIndex, outerObjectIndex, trackCandidateIdx,0,0,0);
                    }

                }
            }
        }

    }
}

#else
__global__ void createPixelTrackCandidatesInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::pixelTracklets& pixelTrackletsInGPU, struct SDL::tracklets& trackletsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::trackCandidates& trackCandidatesInGPU)
{
    unsigned int outerInnerInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    if(outerInnerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;

    int outerInnerInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[outerInnerInnerLowerModuleArrayIndex];
    if(modulesInGPU.moduleType[outerInnerInnerLowerModuleIndex] == SDL::TwoS) return;

    unsigned int pixelLowerModuleArrayIndex = *modulesInGPU.nLowerModules;

    unsigned int nPixelTracklets = *(pixelTrackletsInGPU.nPixelTracklets);
    //capping
    if(nPixelTracklets > N_MAX_PIXEL_TRACKLETS_PER_MODULE)
        nPixelTracklets = N_MAX_PIXEL_TRACKLETS_PER_MODULE;

    unsigned int nOuterLayerTracklets = trackletsInGPU.nTracklets[outerInnerInnerLowerModuleArrayIndex];
    if(nOuterLayerTracklets > N_MAX_TRACKLETS_PER_MODULE)
    {
        nOuterLayerTracklets = N_MAX_TRACKLETS_PER_MODULE;
    }
    unsigned int nOuterLayerTriplets = tripletsInGPU.nTriplets[outerInnerInnerLowerModuleArrayIndex];
    if(nOuterLayerTriplets > N_MAX_TRIPLETS_PER_MODULE)
    {
        nOuterLayerTriplets = N_MAX_TRIPLETS_PER_MODULE;
    }

    unsigned int nThreadsForNestedKernel = max(nOuterLayerTracklets,nOuterLayerTriplets);
    if(nThreadsForNestedKernel == 0) return;

    dim3 nThreads(16,16,1);
    dim3 nBlocks( nPixelTracklets % nThreads.x == 0 ? nPixelTracklets/nThreads.x : nPixelTracklets/nThreads.x + 1, nThreadsForNestedKernel % nThreads.y == 0 ? nThreadsForNestedKernel/nThreads.y : nThreadsForNestedKernel/nThreads.y + 1, 1);

    createPixelTrackCandidatesFromOuterInnerInnerLowerModule<<<nBlocks,nThreads>>>(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, trackletsInGPU, pixelTrackletsInGPU, tripletsInGPU, trackCandidatesInGPU, pixelLowerModuleArrayIndex, outerInnerInnerLowerModuleArrayIndex, nPixelTracklets, nOuterLayerTracklets, nOuterLayerTriplets);
}


__global__ void createPixelTrackCandidatesFromOuterInnerInnerLowerModule(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::tracklets& trackletsInGPU, struct SDL::pixelTracklets& pixelTrackletsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::trackCandidates& trackCandidatesInGPU, unsigned int pixelLowerModuleArrayIndex, unsigned int outerInnerInnerLowerModuleArrayIndex, unsigned int nPixelTracklets, unsigned int nOuterLayerTracklets, unsigned int nOuterLayerTriplets)
{
    int pixelTrackletArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    int outerObjectArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;

    if(pixelTrackletArrayIndex >= nPixelTracklets) return;

    int pixelTrackletIndex = pixelTrackletArrayIndex;
    int outerObjectIndex = 0;
    short trackCandidateType;
    bool success;

    //pT4-T4
    if(outerObjectArrayIndex < nOuterLayerTracklets)
    {
        outerObjectIndex = outerInnerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + outerObjectArrayIndex;

        //part 2 of cheapo module map : only considering tracklets with PS-PS inner segment
       if(modulesInGPU.moduleType[trackletsInGPU.lowerModuleIndices[4 * outerObjectIndex + 1]] == SDL::PS)
        {
            success = runTrackCandidateDefaultAlgoTwoTracklets(pixelTrackletsInGPU, trackletsInGPU, tripletsInGPU, pixelTrackletIndex, outerObjectIndex, trackCandidateType);
            if(success)
            {
                unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[pixelLowerModuleArrayIndex],1);
                atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT4T4[pixelLowerModuleArrayIndex],1);
                if(trackCandidateModuleIdx >= N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE)
                {
                    #ifdef Warnings
                    if(innerInnerInnerLowerModuleArrayIndex == *modulesInGPU.nLowerModules && trackCandidateModuleIdx == N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE)
                    {

                        printf("Track Candidate excess alert! lower Module array index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                    }
                    #endif
                }
                else
                {
                    if(modulesInGPU.trackCandidateModuleIndices[pixelLowerModuleArrayIndex] == -1)
                    {
                       #ifdef Warnings
                       printf("Track candidates: no memory for pixel lower module index at %d\n",innerInnerInnerLowerModuleArrayIndex);
                       #endif

                    }
                    else
                   {
                        unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[pixelLowerModuleArrayIndex] + trackCandidateModuleIdx;
                        addTrackCandidateToMemory(trackCandidatesInGPU, 5/*pT2-T4 trackCandidateType*/, pixelTrackletIndex, outerObjectIndex, trackCandidateIdx);
                    }

                }
            }
        }
    }

    //pT4-T3
    if(outerObjectArrayIndex < nOuterLayerTriplets)
    {
        outerObjectIndex = outerInnerInnerLowerModuleArrayIndex * N_MAX_TRIPLETS_PER_MODULE + outerObjectArrayIndex;

        //part 2 of cheapo module map : only considering tracklets with PS-PS inner segment
        if(modulesInGPU.moduleType[tripletsInGPU.lowerModuleIndices[3 * outerObjectIndex + 1]] == SDL::PS)
        {
            success = runTrackCandidateDefaultAlgoTrackletToTriplet(pixelTrackletsInGPU, trackletsInGPU, tripletsInGPU, pixelTrackletIndex, outerObjectIndex, trackCandidateType);
            if(success)
            {
                unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[pixelLowerModuleArrayIndex],1);
                atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT4T4[pixelLowerModuleArrayIndex],1);
                if(trackCandidateModuleIdx >= N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE)
                {
                    #ifdef Warnings
                    if(innerInnerInnerLowerModuleArrayIndex == *modulesInGPU.nLowerModules && trackCandidateModuleIdx == N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE)
                    {

                        printf("Track Candidate excess alert! lower Module array index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                    }
                    #endif
                }
                else
                {
                    if(modulesInGPU.trackCandidateModuleIndices[pixelLowerModuleArrayIndex] == -1)
                    {
                       #ifdef Warnings
                       printf("Track candidates: no memory for pixel lower module index at %d\n",innerInnerInnerLowerModuleArrayIndex);
                       #endif

                    }
                    else
                   {
                        unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[pixelLowerModuleArrayIndex] + trackCandidateModuleIdx;
                        addTrackCandidateToMemory(trackCandidatesInGPU, 6/* pT2-T3 trackCandidateType*/, pixelTrackletIndex, outerObjectIndex, trackCandidateIdx);
                    }

                }
            }
        }

    }
}
#endif

#ifndef NESTED_PARA
__global__ void createTrackCandidatesInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::tracklets& trackletsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::trackCandidates& trackCandidatesInGPU, unsigned int* threadIdx_gpu, unsigned int *threadIdx_gpu_offset)
{
  //inner tracklet/triplet inner segment inner MD lower module
  int innerInnerInnerLowerModuleArrayIndex = threadIdx_gpu[blockIdx.y * blockDim.y + threadIdx.y];
  //hack to include pixel detector
  if(innerInnerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;

  unsigned int nTracklets = trackletsInGPU.nTracklets[innerInnerInnerLowerModuleArrayIndex];
  if(nTracklets > N_MAX_TRACKLETS_PER_MODULE)
    {
      nTracklets = N_MAX_TRACKLETS_PER_MODULE;
    }

  unsigned int nTriplets = tripletsInGPU.nTriplets[innerInnerInnerLowerModuleArrayIndex]; // should be zero for the pixels
  if(nTriplets > N_MAX_TRIPLETS_PER_MODULE)
    {
      nTriplets = N_MAX_TRIPLETS_PER_MODULE;
    }

  unsigned int temp = max(nTracklets,nTriplets);
  unsigned int MAX_OBJECTS = max(N_MAX_TRACKLETS_PER_MODULE, N_MAX_TRIPLETS_PER_MODULE);

  if(temp == 0) return;

  int innerObjectArrayIndex = threadIdx_gpu_offset[blockIdx.y * blockDim.y + threadIdx.y];
  int outerObjectArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;

  int innerObjectIndex = 0;
  int outerObjectIndex = 0;
  short trackCandidateType;
  bool success;

  //step 1 tracklet-tracklet
  if(innerObjectArrayIndex < nTracklets)
    {
      innerObjectIndex = innerInnerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + innerObjectArrayIndex;
      unsigned int outerInnerInnerLowerModuleIndex = modulesInGPU.reverseLookupLowerModuleIndices[trackletsInGPU.lowerModuleIndices[4 * innerObjectIndex + 2]];/*same as innerOuterInnerLowerModuleIndex*/

      if(outerObjectArrayIndex < fminf(trackletsInGPU.nTracklets[outerInnerInnerLowerModuleIndex],N_MAX_TRACKLETS_PER_MODULE))
        {

	  outerObjectIndex = outerInnerInnerLowerModuleIndex * N_MAX_TRACKLETS_PER_MODULE + outerObjectArrayIndex;

	  success = runTrackCandidateDefaultAlgoTwoTracklets(trackletsInGPU, tripletsInGPU, innerObjectIndex, outerObjectIndex,trackCandidateType);

	  if(success)
            {
	      unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[innerInnerInnerLowerModuleArrayIndex],1);
	      atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT4T4[innerInnerInnerLowerModuleArrayIndex],1);
	      if(trackCandidateModuleIdx >= N_MAX_TRACK_CANDIDATES_PER_MODULE)
                {
                    #ifdef Warnings
		  if(trackCandidateModuleIdx == N_MAX_TRACK_CANDIDATES_PER_MODULE)
                    {
		      printf("Track Candidate excess alert! lower Module array index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                    }
                    #endif
                }
	      else
                {
		  if(modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] == -1)
                    {
                       #ifdef Warnings
		      printf("Track candidates: no memory for module at module index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                       #endif

                    }
		  else
		    {
		      unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] + trackCandidateModuleIdx;
		      addTrackCandidateToMemory(trackCandidatesInGPU, trackCandidateType, innerObjectIndex, outerObjectIndex, trackCandidateIdx,0,0,0);
                    }

                }
            }

        }
    }

  //step 2 tracklet-triplet
  if(innerObjectArrayIndex < nTracklets)
    {
      innerObjectIndex = innerInnerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + innerObjectArrayIndex;
      unsigned int outerInnerInnerLowerModuleIndex = modulesInGPU.reverseLookupLowerModuleIndices[trackletsInGPU.lowerModuleIndices[4 * innerObjectIndex + 2]];//same as innerOuterInnerLowerModuleIndex
      if(outerObjectArrayIndex < fminf(tripletsInGPU.nTriplets[outerInnerInnerLowerModuleIndex],N_MAX_TRIPLETS_PER_MODULE))
        {
	  outerObjectIndex = outerInnerInnerLowerModuleIndex * N_MAX_TRIPLETS_PER_MODULE + outerObjectArrayIndex;
	  success = runTrackCandidateDefaultAlgoTrackletToTriplet(trackletsInGPU, tripletsInGPU, innerObjectIndex, outerObjectIndex,trackCandidateType);
	  if(success)
            {
	      unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[innerInnerInnerLowerModuleArrayIndex],1);
	      atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT4T3[innerInnerInnerLowerModuleArrayIndex],1);
	      if(trackCandidateModuleIdx >= N_MAX_TRACK_CANDIDATES_PER_MODULE)
                {
                    #ifdef Warnings
		  if(trackCandidateModuleIdx == N_MAX_TRACK_CANDIDATES_PER_MODULE)
                    {
		      printf("Track Candidate excess alert! lower Module array index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                    }
                    #endif
                }
	      else
                {

		  if(modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] == -1)
                    {
                        #ifdef Warnings
		      printf("Track candidates: no memory for module at module index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                        #endif
                    }
		  else
                    {
		      unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] + trackCandidateModuleIdx;

		      addTrackCandidateToMemory(trackCandidatesInGPU, trackCandidateType, innerObjectIndex, outerObjectIndex, trackCandidateIdx,0,0,0);
                    }
                }
            }

        }
    }
  //step 3 triplet-tracklet
  if(innerObjectArrayIndex < nTriplets)
    {
      innerObjectIndex = innerInnerInnerLowerModuleArrayIndex * N_MAX_TRIPLETS_PER_MODULE + innerObjectArrayIndex;
      unsigned int outerInnerInnerLowerModuleIndex = modulesInGPU.reverseLookupLowerModuleIndices[tripletsInGPU.lowerModuleIndices[3 * innerObjectIndex + 1]];//same as innerOuterInnerLowerModuleIndex

      if(outerObjectArrayIndex < fminf(trackletsInGPU.nTracklets[outerInnerInnerLowerModuleIndex],N_MAX_TRACKLETS_PER_MODULE))
        {
	  outerObjectIndex = outerInnerInnerLowerModuleIndex * N_MAX_TRACKLETS_PER_MODULE + outerObjectArrayIndex;
	  success = runTrackCandidateDefaultAlgoTripletToTracklet(trackletsInGPU, tripletsInGPU, innerObjectIndex, outerObjectIndex,trackCandidateType);
	  if(success)
            {
	      unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[innerInnerInnerLowerModuleArrayIndex],1);
	      atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT3T4[innerInnerInnerLowerModuleArrayIndex],1);
	      if(trackCandidateModuleIdx >= N_MAX_TRACK_CANDIDATES_PER_MODULE)
                {
                   #ifdef Warnings
		  if(trackCandidateModuleIdx == N_MAX_TRACK_CANDIDATES_PER_MODULE)
		    printf("Track Candidate excess alert! Module index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                   #endif
                }
	      else
                {
		  if(modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] == -1)
                    {
                        #ifdef Warnings
		      printf("Track candidates: no memory for module at module index = %d, outer T4 module index = %d\n",innerInnerInnerLowerModuleArrayIndex, outerInnerInnerLowerModuleIndex);
                        #endif
                    }
		  else
                    {
		      unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] + trackCandidateModuleIdx;
		      addTrackCandidateToMemory(trackCandidatesInGPU, trackCandidateType, innerObjectIndex, outerObjectIndex, trackCandidateIdx,0,0,0);

                    }
                }
            }

        }
    }
}

#else
__global__ void createTrackCandidatesInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::tracklets& trackletsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::trackCandidates& trackCandidatesInGPU)
{
    //inner tracklet/triplet inner segment inner MD lower module
    int innerInnerInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    //hack to include pixel detector
    if(innerInnerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;

    unsigned int nTracklets = trackletsInGPU.nTracklets[innerInnerInnerLowerModuleArrayIndex];
    if(nTracklets > N_MAX_TRACKLETS_PER_MODULE)
    {
        nTracklets = N_MAX_TRACKLETS_PER_MODULE;
    }

    unsigned int nTriplets = tripletsInGPU.nTriplets[innerInnerInnerLowerModuleArrayIndex]; // should be zero for the pixels
    if(nTriplets > N_MAX_TRIPLETS_PER_MODULE)
    {
        nTriplets = N_MAX_TRIPLETS_PER_MODULE;
    }

    unsigned int temp = max(nTracklets,nTriplets);
    unsigned int MAX_OBJECTS = max(N_MAX_TRACKLETS_PER_MODULE, N_MAX_TRIPLETS_PER_MODULE);

    if(temp == 0) return;

    //triplets and tracklets are stored directly using lower module array index
    dim3 nThreads(16,16,1);
    dim3 nBlocks(temp % nThreads.x == 0 ? temp / nThreads.x : temp / nThreads.x + 1, MAX_OBJECTS % nThreads.y == 0 ? MAX_OBJECTS / nThreads.y : MAX_OBJECTS / nThreads.y + 1, 1);

    createTrackCandidatesFromInnerInnerInnerLowerModule<<<nBlocks, nThreads>>>(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, trackletsInGPU, tripletsInGPU, trackCandidatesInGPU,innerInnerInnerLowerModuleArrayIndex,nTracklets,nTriplets);
}

__global__ void createTrackCandidatesFromInnerInnerInnerLowerModule(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::tracklets& trackletsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::trackCandidates& trackCandidatesInGPU, unsigned int innerInnerInnerLowerModuleArrayIndex, unsigned int nInnerTracklets, unsigned int nInnerTriplets)
{
    int innerObjectArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
    int outerObjectArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;

    int innerObjectIndex = 0;
    int outerObjectIndex = 0;
    short trackCandidateType;
    bool success;
    //step 1 tracklet-tracklet
    if(innerObjectArrayIndex < nInnerTracklets)
    {
        innerObjectIndex = innerInnerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + innerObjectArrayIndex;
        unsigned int outerInnerInnerLowerModuleIndex = modulesInGPU.reverseLookupLowerModuleIndices[trackletsInGPU.lowerModuleIndices[4 * innerObjectIndex + 2]];/*same as innerOuterInnerLowerModuleIndex*/

        if(outerObjectArrayIndex < fminf(trackletsInGPU.nTracklets[outerInnerInnerLowerModuleIndex],N_MAX_TRACKLETS_PER_MODULE))
        {

            outerObjectIndex = outerInnerInnerLowerModuleIndex * N_MAX_TRACKLETS_PER_MODULE + outerObjectArrayIndex;

            success = runTrackCandidateDefaultAlgoTwoTracklets(trackletsInGPU, tripletsInGPU, innerObjectIndex, outerObjectIndex,trackCandidateType);

            if(success)
            {
                unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[innerInnerInnerLowerModuleArrayIndex],1);
                atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT4T4[innerInnerInnerLowerModuleArrayIndex],1);
                if(trackCandidateModuleIdx >= N_MAX_TRACK_CANDIDATES_PER_MODULE)
                {
                    #ifdef Warnings
                    if(trackCandidateModuleIdx == N_MAX_TRACK_CANDIDATES_PER_MODULE)
                    {
                        printf("Track Candidate excess alert! lower Module array index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                    }
                    #endif
                }
                else
                {
                    if(modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] == -1)
                    {
                       #ifdef Warnings
                       printf("Track candidates: no memory for module at module index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                       #endif

                    }
                    else
                   {
                        unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] + trackCandidateModuleIdx;
                        addTrackCandidateToMemory(trackCandidatesInGPU, trackCandidateType, innerObjectIndex, outerObjectIndex, trackCandidateIdx);
                    }

                }
            }

        }
    }
    //step 2 tracklet-triplet
    if(innerObjectArrayIndex < nInnerTracklets)
    {
        innerObjectIndex = innerInnerInnerLowerModuleArrayIndex * N_MAX_TRACKLETS_PER_MODULE + innerObjectArrayIndex;
        unsigned int outerInnerInnerLowerModuleIndex = modulesInGPU.reverseLookupLowerModuleIndices[trackletsInGPU.lowerModuleIndices[4 * innerObjectIndex + 2]];//same as innerOuterInnerLowerModuleIndex
        if(outerObjectArrayIndex < fminf(tripletsInGPU.nTriplets[outerInnerInnerLowerModuleIndex],N_MAX_TRIPLETS_PER_MODULE))
        {
            outerObjectIndex = outerInnerInnerLowerModuleIndex * N_MAX_TRIPLETS_PER_MODULE + outerObjectArrayIndex;
            success = runTrackCandidateDefaultAlgoTrackletToTriplet(trackletsInGPU, tripletsInGPU, innerObjectIndex, outerObjectIndex,trackCandidateType);
            if(success)
            {
                unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[innerInnerInnerLowerModuleArrayIndex],1);
                atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT4T3[innerInnerInnerLowerModuleArrayIndex],1);
                if(trackCandidateModuleIdx >= N_MAX_TRACK_CANDIDATES_PER_MODULE)
                {
                    #ifdef Warnings
                    if(trackCandidateModuleIdx == N_MAX_TRACK_CANDIDATES_PER_MODULE)
                    {
                        printf("Track Candidate excess alert! lower Module array index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                    }
                    #endif
                }
                else
                {

                    if(modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] == -1)
                    {
                        #ifdef Warnings
                        printf("Track candidates: no memory for module at module index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                        #endif
                    }
                    else
                    {
                        unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] + trackCandidateModuleIdx;

                        addTrackCandidateToMemory(trackCandidatesInGPU, trackCandidateType, innerObjectIndex, outerObjectIndex, trackCandidateIdx);
                    }
                }
            }

        }
    }

    //step 3 triplet-tracklet
    if(innerObjectArrayIndex < nInnerTriplets)
    {
        innerObjectIndex = innerInnerInnerLowerModuleArrayIndex * N_MAX_TRIPLETS_PER_MODULE + innerObjectArrayIndex;
        unsigned int outerInnerInnerLowerModuleIndex = modulesInGPU.reverseLookupLowerModuleIndices[tripletsInGPU.lowerModuleIndices[3 * innerObjectIndex + 1]];//same as innerOuterInnerLowerModuleIndex

        if(outerObjectArrayIndex < fminf(trackletsInGPU.nTracklets[outerInnerInnerLowerModuleIndex],N_MAX_TRACKLETS_PER_MODULE))
        {
            outerObjectIndex = outerInnerInnerLowerModuleIndex * N_MAX_TRACKLETS_PER_MODULE + outerObjectArrayIndex;
            success = runTrackCandidateDefaultAlgoTripletToTracklet(trackletsInGPU, tripletsInGPU, innerObjectIndex, outerObjectIndex,trackCandidateType);
            if(success)
            {
                unsigned int trackCandidateModuleIdx = atomicAdd(&trackCandidatesInGPU.nTrackCandidates[innerInnerInnerLowerModuleArrayIndex],1);
                atomicAdd(&trackCandidatesInGPU.nTrackCandidatesT3T4[innerInnerInnerLowerModuleArrayIndex],1);
	        if(trackCandidateModuleIdx >= N_MAX_TRACK_CANDIDATES_PER_MODULE)
                {
                   #ifdef Warnings
                   if(trackCandidateModuleIdx == N_MAX_TRACK_CANDIDATES_PER_MODULE)
                       printf("Track Candidate excess alert! Module index = %d\n",innerInnerInnerLowerModuleArrayIndex);
                   #endif
                }
                else
                {
                    if(modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] == -1)
                    {
                        #ifdef Warnings
                        printf("Track candidates: no memory for module at module index = %d, outer T4 module index = %d\n",innerInnerInnerLowerModuleArrayIndex, outerInnerInnerLowerModuleIndex);
                        #endif
                    }
                    else
                    {
                        unsigned int trackCandidateIdx = modulesInGPU.trackCandidateModuleIndices[innerInnerInnerLowerModuleArrayIndex] + trackCandidateModuleIdx;
                        addTrackCandidateToMemory(trackCandidatesInGPU, trackCandidateType, innerObjectIndex, outerObjectIndex, trackCandidateIdx);

                    }
                }
            }

        }
    }
}
#endif


//#ifndef NESTED_PARA
//#else

__global__ void createPixelTripletsFromOuterInnerLowerModule(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::pixelTriplets& pixelTripletsInGPU, unsigned int outerTripletInnerLowerModuleArrayIndex, unsigned int nPixelSegments, unsigned int nOuterTriplets, unsigned int pixelModuleIndex)
{
   int pixelSegmentArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
   int outerTripletArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;

   if(pixelSegmentArrayIndex >= nPixelSegments) return;
   if(outerTripletArrayIndex >= nOuterTriplets) return;

   unsigned int pixelSegmentIndex = pixelModuleIndex * N_MAX_SEGMENTS_PER_MODULE + pixelSegmentArrayIndex;
   unsigned int outerTripletIndex = outerTripletInnerLowerModuleArrayIndex * N_MAX_TRIPLETS_PER_MODULE + outerTripletArrayIndex;

   if(modulesInGPU.moduleType[tripletsInGPU.lowerModuleIndices[3 * outerTripletIndex + 1]] == SDL::TwoS) return; //REMOVES PS-2S

   float pixelRadius, pixelRadiusError, tripletRadius;
   bool success = runPixelTripletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, tripletsInGPU, pixelSegmentIndex, outerTripletIndex, pixelRadius, pixelRadiusError, tripletRadius);

   if(success)
   {
       unsigned int pixelTripletIndex = atomicAdd(pixelTripletsInGPU.nPixelTriplets, 1);
       if(pixelTripletIndex >= N_MAX_PIXEL_TRIPLETS)
       {
            #ifdef Warnings
            if(pixelTripletIndex == N_MAX_PIXEL_TRIPLETS)
            {
               printf("Pixel Triplet excess alert!\n"); 
            }
            #endif
       }
       else
       {
#ifdef CUT_VALUE_DEBUG
           addPixelTripletToMemory(pixelTripletsInGPU, pixelSegmentIndex, outerTripletIndex, pixelRadius, pixelRadiusError, tripletRadius, pixelTripletIndex);
#else
           addPixelTripletToMemory(pixelTripletsInGPU, pixelSegmentIndex, outerTripletIndex, pixelRadius,tripletRadius, pixelTripletIndex);
#endif
       }
   }
}

__global__ void createPixelTripletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::pixelTriplets& pixelTripletsInGPU)
{
    int outerTripletInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;

    //lower modules 2 and 3 are taken from the triplet!
    if(outerTripletInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules) return;

    unsigned int nOuterTriplets = tripletsInGPU.nTriplets[outerTripletInnerLowerModuleArrayIndex] > N_MAX_TRIPLETS_PER_MODULE ? N_MAX_TRIPLETS_PER_MODULE : tripletsInGPU.nTriplets[outerTripletInnerLowerModuleArrayIndex];

    unsigned int pixelModuleIndex = *modulesInGPU.nModules - 1;
    unsigned int nPixelSegments = segmentsInGPU.nSegments[pixelModuleIndex] > N_MAX_PIXEL_SEGMENTS_PER_MODULE ? N_MAX_PIXEL_SEGMENTS_PER_MODULE : segmentsInGPU.nSegments[pixelModuleIndex];
    
    //El-cheapo map applied on the inner segment
    unsigned int outerTripletInnerLowerModuleIndex = modulesInGPU.lowerModuleIndices[outerTripletInnerLowerModuleArrayIndex];
    if(modulesInGPU.moduleType[outerTripletInnerLowerModuleIndex]== SDL::TwoS) return; //REMOVES 2S-2S

    if(nOuterTriplets == 0) return;
    dim3 nThreads(16,16,1);
    dim3 nBlocks(nPixelSegments % nThreads.x == 0 ? nPixelSegments / nThreads.x : nPixelSegments / nThreads.x + 1, nOuterTriplets % nThreads.y == 0 ? nOuterTriplets / nThreads.y : nOuterTriplets / nThreads.y + 1, 1);

    createPixelTripletsFromOuterInnerLowerModule<<<nBlocks, nThreads>>>(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, tripletsInGPU, pixelTripletsInGPU, outerTripletInnerLowerModuleArrayIndex, nPixelSegments, nOuterTriplets, pixelModuleIndex);
}

//#endif

__device__ int duplicateCounter;
__global__ void removeDupQuintupletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::quintuplets& quintupletsInGPU, unsigned int* threadIdx_gpu, unsigned int* threadIdx_gpu_offset)
{
      int dup_count=0;
      for(unsigned int lowmod1=blockIdx.x*blockDim.x+threadIdx.x; lowmod1<*modulesInGPU.nLowerModules;lowmod1+=blockDim.x*gridDim.x){
      for(unsigned int ix1=blockIdx.y*blockDim.y+threadIdx.y; ix1<quintupletsInGPU.nQuintuplets[lowmod1]; ix1+=blockDim.y*gridDim.y){
        unsigned int ix = modulesInGPU.quintupletModuleIndices[lowmod1] + ix1;
        if(quintupletsInGPU.isDup[ix]==1){continue;}
        float pt1  = quintupletsInGPU.pt[ix];
        float eta1 = quintupletsInGPU.eta[ix];
        float phi1 = quintupletsInGPU.phi[ix];
        bool isDup = false;
        for(unsigned int lowmod=0; lowmod<*modulesInGPU.nLowerModules;lowmod++){
      for(unsigned int jx1=0; jx1<quintupletsInGPU.nQuintuplets[lowmod]; jx1++){
        unsigned int jx = modulesInGPU.quintupletModuleIndices[lowmod] + jx1;
        if(ix>=jx){continue;}
        //if(ix==jx){continue;}
        //for(unsigned int jx=0; jx<quintupletsInGPU.nQuintuplets[lowmod]+modulesInGPU.quintupletModuleIndices[lowmod]; jx++){
        if(quintupletsInGPU.isDup[jx]==1){continue;}
        float pt2  = quintupletsInGPU.pt[jx];
        float eta2 = quintupletsInGPU.eta[jx];
        float phi2 = quintupletsInGPU.phi[jx];
        float dEta = abs(eta1-eta2);
        float dPhi = abs(phi1-phi2);
        if(dPhi > M_PI){dPhi = dPhi - 2*M_PI;}
        if (dEta > 0.5){continue;}
        if (dPhi > 0.5){continue;}
        float dR2 = dEta*dEta + dPhi*dPhi;
        if(dR2 < 0.001){
          isDup=true;break;
        }
        unsigned int hit1_0 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*ix]]]]; // inner triplet inner segment inner md inner hit
        unsigned int hit1_1 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*ix]]]+1]; // inner triplet inner segment inner md outer hit
        unsigned int hit1_2 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*ix]]+1]]; // inner triplet inner segment outer md inner hit
        unsigned int hit1_3 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*ix]]+1]+1]; // inner triplet inner segment outer md outer hit
        unsigned int hit1_4 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*ix]+1]+1]]; // inner triplet outer segment outer md inner hit
        unsigned int hit1_5 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*ix]+1]+1]+1]; // inner triplet outer segment outer md outer hit
        unsigned int hit1_6 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*ix+1]+1]]]; // outer triplet outersegment inner md inner hit 
        unsigned int hit1_7 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*ix+1]+1]]+1]; // outer triplet outersegment inner md outer hit
        unsigned int hit1_8 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*ix+1]+1]+1]]; // outer triplet outersegment outer md inner hit
        unsigned int hit1_9 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*ix+1]+1]+1]+1]; // outer triplet outersegment outer md outer hit

        unsigned int hit2_0 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]]]]; // inner triplet inner segment inner md inner hit
        unsigned int hit2_1 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]]]+1]; // inner triplet inner segment inner md outer hit
        unsigned int hit2_2 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]]+1]]; // inner triplet inner segment outer md inner hit
        unsigned int hit2_3 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]]+1]+1]; // inner triplet inner segment outer md outer hit
        unsigned int hit2_4 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]+1]+1]]; // inner triplet outer segment outer md inner hit
        unsigned int hit2_5 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]+1]+1]+1]; // inner triplet outer segment outer md outer hit
        unsigned int hit2_6 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx+1]+1]]]; // outer triplet outersegment inner md inner hit 
        unsigned int hit2_7 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx+1]+1]]+1]; // outer triplet outersegment inner md outer hit
        unsigned int hit2_8 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx+1]+1]+1]]; // outer triplet outersegment outer md inner hit
        unsigned int hit2_9 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx+1]+1]+1]+1]; // outer triplet outersegment outer md outer hit

        short matched_0 = checkHits(hit1_0,hit2_0) ||checkHits(hit1_0,hit2_2); 
        short matched_1 = checkHits(hit1_1,hit2_1) ||checkHits(hit1_1,hit2_3);
        short matched_2 = checkHits(hit1_2,hit2_0) ||checkHits(hit1_2,hit2_2) ||checkHits(hit1_2,hit2_4);
        short matched_3 = checkHits(hit1_3,hit2_1) ||checkHits(hit1_3,hit2_3) ||checkHits(hit1_3,hit2_5);
        short matched_4 = checkHits(hit1_4,hit2_2) ||checkHits(hit1_4,hit2_4) ||checkHits(hit1_4,hit2_6);
        short matched_5 = checkHits(hit1_5,hit2_3) ||checkHits(hit1_5,hit2_5) ||checkHits(hit1_5,hit2_7);
        short matched_6 = checkHits(hit1_6,hit2_4) ||checkHits(hit1_6,hit2_6) ||checkHits(hit1_6,hit2_8);
        short matched_7 = checkHits(hit1_7,hit2_5) ||checkHits(hit1_7,hit2_7) ||checkHits(hit1_7,hit2_9);
        short matched_8 = checkHits(hit1_8,hit2_6) ||checkHits(hit1_8,hit2_8);
        short matched_9 = checkHits(hit1_9,hit2_7) ||checkHits(hit1_9,hit2_9);

        if(matched_0+matched_1+matched_2+matched_3+matched_4+matched_5+matched_6+matched_7+matched_8+matched_9>7){
                isDup=true;//dup_count++;
//                printf("hits1 %u %u %u %u %u %u %u %u %u %u\n",hit1_0,hit1_1,hit1_2,hit1_3,hit1_4,hit1_5,hit1_6,hit1_7,hit1_8,hit1_9);
//                printf("hits2 %u %u %u %u %u %u %u %u %u %u\n",hit2_0,hit2_1,hit2_2,hit2_3,hit2_4,hit2_5,hit2_6,hit2_7,hit2_8,hit2_9);
//                printf("id %u %d\n",ix,dup_count);
                break;
          }
      }
      if(isDup){break;}
      }
                //if(isDup){dup_count++;addQuintupletToMemory(quintupletsInGPU, 0, 0, 0, 0, 0, 0,0, 0, 0, ix,1,pt1,eta1,phi1);}
                if(isDup){dup_count++;rmQuintupletToMemory(quintupletsInGPU,ix);}
    }}
//atomicAdd(&duplicateCounter,dup_count);
//printf("dup count: %d %d\n",dup_count,duplicateCounter);

}
#ifndef NESTED_PARA
__global__ void createQuintupletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::quintuplets& quintupletsInGPU, unsigned int* threadIdx_gpu, unsigned int* threadIdx_gpu_offset)
{
    int lowerModuleArray1 = threadIdx_gpu[blockIdx.y * blockDim.y + threadIdx.y];

    //this if statement never gets executed!
    if(lowerModuleArray1  >= *modulesInGPU.nLowerModules) return;

    unsigned int nInnerTriplets = tripletsInGPU.nTriplets[lowerModuleArray1];

    //unsigned int innerTripletArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;
    unsigned int innerTripletArrayIndex = threadIdx_gpu_offset[blockIdx.y * blockDim.y + threadIdx.y];
    unsigned int outerTripletArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;

    if(innerTripletArrayIndex >= nInnerTriplets) return;

    unsigned int innerTripletIndex = lowerModuleArray1 * N_MAX_TRIPLETS_PER_MODULE + innerTripletArrayIndex;
    unsigned int lowerModule1 = modulesInGPU.lowerModuleIndices[lowerModuleArray1];
    //these are actual module indices!! not lower module indices!
    unsigned int lowerModule2 = tripletsInGPU.lowerModuleIndices[3 * innerTripletIndex + 1];
    unsigned int lowerModule3 = tripletsInGPU.lowerModuleIndices[3 * innerTripletIndex + 2];
    unsigned int lowerModuleArray3 = modulesInGPU.reverseLookupLowerModuleIndices[lowerModule3];
    unsigned int nOuterTriplets = min(tripletsInGPU.nTriplets[lowerModuleArray3], N_MAX_TRIPLETS_PER_MODULE);

    if(outerTripletArrayIndex >= nOuterTriplets) return;
    unsigned int outerTripletIndex = lowerModuleArray3 * N_MAX_TRIPLETS_PER_MODULE + outerTripletArrayIndex;
    //these are actual module indices!!
    unsigned int lowerModule4 = tripletsInGPU.lowerModuleIndices[3 * outerTripletIndex + 1];
    unsigned int lowerModule5 = tripletsInGPU.lowerModuleIndices[3 * outerTripletIndex + 2];

    float innerRadius, innerRadiusMin, innerRadiusMin2S, innerRadiusMax, innerRadiusMax2S, outerRadius, outerRadiusMin, outerRadiusMin2S, outerRadiusMax, outerRadiusMax2S, bridgeRadius, bridgeRadiusMin, bridgeRadiusMin2S, bridgeRadiusMax, bridgeRadiusMax2S; //required for making distributions
    bool success = runQuintupletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, tripletsInGPU, lowerModule1, lowerModule2, lowerModule3, lowerModule4, lowerModule5, innerTripletIndex, outerTripletIndex, innerRadius, innerRadiusMin, innerRadiusMax, outerRadius, outerRadiusMin, outerRadiusMax, bridgeRadius, bridgeRadiusMin, bridgeRadiusMax, innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S,
            outerRadiusMax2S);

   if(success)
   {
//      for(unsigned int lowmod=0; lowmod<*modulesInGPU.nLowerModules;lowmod++){
//      for(unsigned int jx1=0; jx1<quintupletsInGPU.nQuintuplets[lowmod]; jx1++){
//        unsigned int jx = modulesInGPU.quintupletModuleIndices[lowmod] + jx1;
//      //for(unsigned int jx=0; jx<quintupletsInGPU.nQuintuplets[lowmod]+modulesInGPU.quintupletModuleIndices[lowmod]; jx++){
//        //printf("jx: %u \n",jx);
//        unsigned int hit1_0 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*innerTripletIndex]]]; // inner triplet inner segment inner md inner hit
//        unsigned int hit1_1 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*innerTripletIndex]]+1]; // inner triplet inner segment inner md outer hit
//        unsigned int hit1_2 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*innerTripletIndex]+1]]; // inner triplet inner segment outer md inner hit
//        unsigned int hit1_3 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*innerTripletIndex]+1]+1]; // inner triplet inner segment outer md outer hit
//        unsigned int hit1_4 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*innerTripletIndex+1]+1]]; // inner triplet outer segment outer md inner hit
//        unsigned int hit1_5 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*innerTripletIndex+1]+1]+1]; // inner triplet outer segment outer md outer hit
//        unsigned int hit1_6 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*outerTripletIndex+1]]]; // outer triplet outersegment inner md inner hit 
//        unsigned int hit1_7 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*outerTripletIndex+1]]+1]; // outer triplet outersegment inner md outer hit
//        unsigned int hit1_8 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*outerTripletIndex+1]+1]]; // outer triplet outersegment outer md inner hit
//        unsigned int hit1_9 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*outerTripletIndex+1]+1]+1]; // outer triplet outersegment outer md outer hit
//
//        unsigned int hit2_0 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]]]]; // inner triplet inner segment inner md inner hit
//        unsigned int hit2_1 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]]]+1]; // inner triplet inner segment inner md outer hit
//        unsigned int hit2_2 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]]+1]]; // inner triplet inner segment outer md inner hit
//        unsigned int hit2_3 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]]+1]+1]; // inner triplet inner segment outer md outer hit
//        unsigned int hit2_4 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]+1]+1]]; // inner triplet outer segment outer md inner hit
//        unsigned int hit2_5 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx]+1]+1]+1]; // inner triplet outer segment outer md outer hit
//        unsigned int hit2_6 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx+1]+1]]]; // outer triplet outersegment inner md inner hit 
//        unsigned int hit2_7 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx+1]+1]]+1]; // outer triplet outersegment inner md outer hit
//        unsigned int hit2_8 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx+1]+1]+1]]; // outer triplet outersegment outer md inner hit
//        unsigned int hit2_9 = mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*quintupletsInGPU.tripletIndices[2*jx+1]+1]+1]+1]; // outer triplet outersegment outer md outer hit
//
//        //short matched_0 = checkHits(hit1_0,hit2_0) ||checkHits(hit1_0,hit2_1) ||checkHits(hit1_0,hit2_2) ||checkHits(hit1_0,hit2_3) ||checkHits(hit1_0,hit2_4) ||checkHits(hit1_0,hit2_5) ||checkHits(hit1_0,hit2_6) ||checkHits(hit1_0,hit2_7) ||checkHits(hit1_0,hit2_8) ||checkHits(hit1_0,hit2_9);
//        //short matched_1 = checkHits(hit1_1,hit2_0) ||checkHits(hit1_1,hit2_1) ||checkHits(hit1_1,hit2_2) ||checkHits(hit1_1,hit2_3) ||checkHits(hit1_1,hit2_4) ||checkHits(hit1_1,hit2_5) ||checkHits(hit1_1,hit2_6) ||checkHits(hit1_1,hit2_7) ||checkHits(hit1_1,hit2_8) ||checkHits(hit1_1,hit2_9);
//        //short matched_2 = checkHits(hit1_2,hit2_0) ||checkHits(hit1_2,hit2_1) ||checkHits(hit1_2,hit2_2) ||checkHits(hit1_2,hit2_3) ||checkHits(hit1_2,hit2_4) ||checkHits(hit1_2,hit2_5) ||checkHits(hit1_2,hit2_6) ||checkHits(hit1_2,hit2_7) ||checkHits(hit1_2,hit2_8) ||checkHits(hit1_2,hit2_9);
//        //short matched_3 = checkHits(hit1_3,hit2_0) ||checkHits(hit1_3,hit2_1) ||checkHits(hit1_3,hit2_2) ||checkHits(hit1_3,hit2_3) ||checkHits(hit1_3,hit2_4) ||checkHits(hit1_3,hit2_5) ||checkHits(hit1_3,hit2_6) ||checkHits(hit1_3,hit2_7) ||checkHits(hit1_3,hit2_8) ||checkHits(hit1_3,hit2_9);
//        //short matched_4 = checkHits(hit1_4,hit2_0) ||checkHits(hit1_4,hit2_1) ||checkHits(hit1_4,hit2_2) ||checkHits(hit1_4,hit2_3) ||checkHits(hit1_4,hit2_4) ||checkHits(hit1_4,hit2_5) ||checkHits(hit1_4,hit2_6) ||checkHits(hit1_4,hit2_7) ||checkHits(hit1_4,hit2_8) ||checkHits(hit1_4,hit2_9);
//        //short matched_5 = checkHits(hit1_5,hit2_0) ||checkHits(hit1_5,hit2_1) ||checkHits(hit1_5,hit2_2) ||checkHits(hit1_5,hit2_3) ||checkHits(hit1_5,hit2_4) ||checkHits(hit1_5,hit2_5) ||checkHits(hit1_5,hit2_6) ||checkHits(hit1_5,hit2_7) ||checkHits(hit1_5,hit2_8) ||checkHits(hit1_5,hit2_9);
//        //short matched_6 = checkHits(hit1_6,hit2_0) ||checkHits(hit1_6,hit2_1) ||checkHits(hit1_6,hit2_2) ||checkHits(hit1_6,hit2_3) ||checkHits(hit1_6,hit2_4) ||checkHits(hit1_6,hit2_5) ||checkHits(hit1_6,hit2_6) ||checkHits(hit1_6,hit2_7) ||checkHits(hit1_6,hit2_8) ||checkHits(hit1_6,hit2_9);
//        //short matched_7 = checkHits(hit1_7,hit2_0) ||checkHits(hit1_7,hit2_1) ||checkHits(hit1_7,hit2_2) ||checkHits(hit1_7,hit2_3) ||checkHits(hit1_7,hit2_4) ||checkHits(hit1_7,hit2_5) ||checkHits(hit1_7,hit2_6) ||checkHits(hit1_7,hit2_7) ||checkHits(hit1_7,hit2_8) ||checkHits(hit1_7,hit2_9);
//        //short matched_8 = checkHits(hit1_8,hit2_0) ||checkHits(hit1_8,hit2_1) ||checkHits(hit1_8,hit2_2) ||checkHits(hit1_8,hit2_3) ||checkHits(hit1_8,hit2_4) ||checkHits(hit1_8,hit2_5) ||checkHits(hit1_8,hit2_6) ||checkHits(hit1_8,hit2_7) ||checkHits(hit1_8,hit2_8) ||checkHits(hit1_8,hit2_9);
//        //short matched_9 = checkHits(hit1_9,hit2_0) ||checkHits(hit1_9,hit2_1) ||checkHits(hit1_9,hit2_2) ||checkHits(hit1_9,hit2_3) ||checkHits(hit1_9,hit2_4) ||checkHits(hit1_9,hit2_5) ||checkHits(hit1_9,hit2_6) ||checkHits(hit1_9,hit2_7) ||checkHits(hit1_9,hit2_8) ||checkHits(hit1_9,hit2_9);
//        short matched_0 = checkHits(hit1_0,hit2_0) ||checkHits(hit1_0,hit2_2); 
//        short matched_1 = checkHits(hit1_1,hit2_1) ||checkHits(hit1_1,hit2_3);
//        short matched_2 = checkHits(hit1_2,hit2_0) ||checkHits(hit1_2,hit2_2) ||checkHits(hit1_2,hit2_4);
//        short matched_3 = checkHits(hit1_3,hit2_1) ||checkHits(hit1_3,hit2_3) ||checkHits(hit1_3,hit2_5);
//        short matched_4 = checkHits(hit1_4,hit2_2) ||checkHits(hit1_4,hit2_4) ||checkHits(hit1_4,hit2_6);
//        short matched_5 = checkHits(hit1_5,hit2_3) ||checkHits(hit1_5,hit2_5) ||checkHits(hit1_5,hit2_7);
//        short matched_6 = checkHits(hit1_6,hit2_4) ||checkHits(hit1_6,hit2_6) ||checkHits(hit1_6,hit2_8);
//        short matched_7 = checkHits(hit1_7,hit2_5) ||checkHits(hit1_7,hit2_7) ||checkHits(hit1_7,hit2_9);
//        short matched_8 = checkHits(hit1_8,hit2_6) ||checkHits(hit1_8,hit2_8);
//        short matched_9 = checkHits(hit1_9,hit2_7) ||checkHits(hit1_9,hit2_9);
//
//        if(matched_0+matched_1+matched_2+matched_3+matched_4+matched_5+matched_6+matched_7+matched_8+matched_9<8){continue;}
//        return;
//      }}
        short layer2_adjustment;
        if(modulesInGPU.layers[lowerModule1] == 1){layer2_adjustment = 1;} //get upper segment to be in second layer
        else if( modulesInGPU.layers[lowerModule1] == 2){layer2_adjustment = 0;} // get lower segment to be in second layer
        else{return;} // ignore anything else
       unsigned int quintupletModuleIndex = atomicAdd(&quintupletsInGPU.nQuintuplets[lowerModuleArray1], 1);
       if(quintupletModuleIndex >= N_MAX_QUINTUPLETS_PER_MODULE)
       {
#ifdef Warnings
           if(quintupletModuleIndex ==  N_MAX_QUINTUPLETS_PER_MODULE)
               printf("Quintuplet excess alert! Module index = %d\n", lowerModuleArray1);
#endif
       }
       else
       {
           //this if statement should never get executed!
           if(modulesInGPU.quintupletModuleIndices[lowerModuleArray1] == -1)
           {
                printf("Quintuplets : no memory for module at module index = %d\n", lowerModuleArray1);
           }
           else
           {
                unsigned int quintupletIndex = modulesInGPU.quintupletModuleIndices[lowerModuleArray1] +  quintupletModuleIndex;
#ifdef CUT_VALUE_DEBUG
                addQuintupletToMemory(quintupletsInGPU, innerTripletIndex, outerTripletIndex, lowerModule1, lowerModule2, lowerModule3, lowerModule4, lowerModule5, innerRadius, innerRadiusMin, innerRadiusMax, outerRadius, outerRadiusMin, outerRadiusMax, bridgeRadius, bridgeRadiusMin, bridgeRadiusMax, innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S, outerRadiusMax2S, quintupletIndex);
#else
        float phi = hitsInGPU.phis[mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*innerTripletIndex+layer2_adjustment]]]]; 
        float eta = hitsInGPU.etas[mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*innerTripletIndex+layer2_adjustment]]]]; 
        //float phi = hitsInGPU.phis[mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*innerTripletIndex]]]]; // inner triplet inner segment inner md inner hit
        //float eta = hitsInGPU.etas[mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*outerTripletIndex+1]+1]+1]]; // outer triplet outersegment outer md outer hit
        float pt = 0;  
        //printf("T5 %e %e %e\n",pt,eta,phi);
                addQuintupletToMemory(quintupletsInGPU, innerTripletIndex, outerTripletIndex, lowerModule1, lowerModule2, lowerModule3, lowerModule4, lowerModule5, innerRadius, outerRadius, quintupletIndex,0,pt,eta,phi);
#endif
            }
        }
    }
}

#else
__global__ void createQuintupletsFromInnerInnerLowerModule(SDL::modules& modulesInGPU, SDL::hits& hitsInGPU, SDL::miniDoublets& mdsInGPU, SDL::segments& segmentsInGPU, SDL::triplets& tripletsInGPU, SDL::quintuplets& quintupletsInGPU, unsigned int lowerModuleArray1, unsigned int nInnerTriplets)
{
   int innerTripletArrayIndex = blockIdx.x * blockDim.x + threadIdx.x;
   int outerTripletArrayIndex = blockIdx.y * blockDim.y + threadIdx.y;

   if(innerTripletArrayIndex >= nInnerTriplets) return;

   unsigned int innerTripletIndex = lowerModuleArray1 * N_MAX_TRIPLETS_PER_MODULE + innerTripletArrayIndex;
   unsigned int lowerModule1 = modulesInGPU.lowerModuleIndices[lowerModuleArray1];
   //these are actual module indices!!! not lower module indices
   unsigned int lowerModule2 = tripletsInGPU.lowerModuleIndices[3 * innerTripletIndex + 1];
   unsigned int lowerModule3 = tripletsInGPU.lowerModuleIndices[3 * innerTripletIndex + 2];
   unsigned int lowerModuleArray3 = modulesInGPU.reverseLookupLowerModuleIndices[lowerModule3];

   unsigned int nOuterTriplets = min(tripletsInGPU.nTriplets[lowerModuleArray3], N_MAX_TRIPLETS_PER_MODULE);

   if(outerTripletArrayIndex >= nOuterTriplets) return;

   unsigned int outerTripletIndex = lowerModuleArray3 * N_MAX_TRIPLETS_PER_MODULE + outerTripletArrayIndex;
    //these are actual module indices!!
    unsigned int lowerModule4 = tripletsInGPU.lowerModuleIndices[3 * outerTripletIndex + 1];
    unsigned int lowerModule5 = tripletsInGPU.lowerModuleIndices[3 * outerTripletIndex + 2];

    float innerRadius, innerRadiusMin, innerRadiusMin2S, innerRadiusMax, innerRadiusMax2S, outerRadius, outerRadiusMin, outerRadiusMin2S, outerRadiusMax, outerRadiusMax2S, bridgeRadius, bridgeRadiusMin, bridgeRadiusMin2S, bridgeRadiusMax, bridgeRadiusMax2S; //required for making distributions
    bool success = runQuintupletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, tripletsInGPU, lowerModule1, lowerModule2, lowerModule3, lowerModule4, lowerModule5, innerTripletIndex, outerTripletIndex, innerRadius, innerRadiusMin, innerRadiusMax, outerRadius, outerRadiusMin, outerRadiusMax, bridgeRadius, bridgeRadiusMin, bridgeRadiusMax, innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S,
            outerRadiusMax2S);

   if(success)
   {
       unsigned int quintupletModuleIndex = atomicAdd(&quintupletsInGPU.nQuintuplets[lowerModuleArray1], 1);
       if(quintupletModuleIndex >= N_MAX_QUINTUPLETS_PER_MODULE)
       {
#ifdef Warnings
           if(quintupletModuleIndex ==  N_MAX_QUINTUPLETS_PER_MODULE)
               printf("Quintuplet excess alert! Module index = %d\n", lowerModuleArray1);
#endif
       }
       else
       {
           if(modulesInGPU.quintupletModuleIndices[lowerModuleArray1] == -1)
           {
                printf("Quintuplets : no memory for module at module index = %d\n", lowerModuleArray1);
           }
           else
           {
                unsigned int quintupletIndex = modulesInGPU.quintupletModuleIndices[lowerModuleArray1] +  quintupletModuleIndex;
#ifdef CUT_VALUE_DEBUG
                addQuintupletToMemory(quintupletsInGPU, innerTripletIndex, outerTripletIndex, lowerModule1, lowerModule2, lowerModule3, lowerModule4, lowerModule5, innerRadius, innerRadiusMin, innerRadiusMax, outerRadius, outerRadiusMin, outerRadiusMax, bridgeRadius, bridgeRadiusMin, bridgeRadiusMax, innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S, outerRadiusMax2S, quintupletIndex);
#else
        float phi = hitsInGPU.phis[mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*innerTripletIndex]]]]; // inner triplet inner segment inner md inner hit
        float eta = hitsInGPU.etas[mdsInGPU.hitIndices[2*segmentsInGPU.mdIndices[2*tripletsInGPU.segmentIndices[2*outerTripletIndex+1]+1]+1]]; // outer triplet outersegment outer md outer hit
        float pt = 0;
                addQuintupletToMemory(quintupletsInGPU, innerTripletIndex, outerTripletIndex, lowerModule1, lowerModule2, lowerModule3, lowerModule4, lowerModule5, innerRadius, outerRadius, quintupletIndex,0,pt,eta,phi);
#endif

            }
        }
    }
}

__global__ void createQuintupletsInGPU(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, struct SDL::quintuplets& quintupletsInGPU)
{
    int innerInnerInnerLowerModuleArrayIndex = blockIdx.x * blockDim.x + threadIdx.x; //inner triplet inner segment inner MD

    //no quintuplets can be formed for these folks - no need to run inner kernels for them!

    if(innerInnerInnerLowerModuleArrayIndex >= *modulesInGPU.nLowerModules or modulesInGPU.quintupletModuleIndices[innerInnerInnerLowerModuleArrayIndex] == -1) return;

    unsigned int nInnerTriplets = min(tripletsInGPU.nTriplets[innerInnerInnerLowerModuleArrayIndex], N_MAX_TRIPLETS_PER_MODULE);
    if(nInnerTriplets == 0) return;

    dim3 nThreads(16,16,1);
    dim3 nBlocks(nInnerTriplets % nThreads.x == 0 ? nInnerTriplets / nThreads.x : nInnerTriplets / nThreads.x + 1, N_MAX_TRIPLETS_PER_MODULE % nThreads.y == 0 ? N_MAX_TRIPLETS_PER_MODULE / nThreads.y : N_MAX_TRIPLETS_PER_MODULE / nThreads.y + 1);

    createQuintupletsFromInnerInnerLowerModule<<<nBlocks,nThreads>>>(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, tripletsInGPU, quintupletsInGPU, innerInnerInnerLowerModuleArrayIndex, nInnerTriplets);

}

#endif

unsigned int SDL::Event::getNumberOfHits()
{
    unsigned int hits = 0;
    for(auto &it:n_hits_by_layer_barrel_)
    {
        hits += it;
    }
    for(auto& it:n_hits_by_layer_endcap_)
    {
        hits += it;
    }

    return hits;
}

unsigned int SDL::Event::getNumberOfHitsByLayer(unsigned int layer)
{
    if(layer == 6)
        return n_hits_by_layer_barrel_[layer];
    else
        return n_hits_by_layer_barrel_[layer] + n_hits_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfHitsByLayerBarrel(unsigned int layer)
{
    return n_hits_by_layer_barrel_[layer];
}

unsigned int SDL::Event::getNumberOfHitsByLayerEndcap(unsigned int layer)
{
    return n_hits_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfMiniDoublets()
{
     unsigned int miniDoublets = 0;
    for(auto &it:n_minidoublets_by_layer_barrel_)
    {
        miniDoublets += it;
    }
    for(auto &it:n_minidoublets_by_layer_endcap_)
    {
        miniDoublets += it;
    }

    return miniDoublets;

}

unsigned int SDL::Event::getNumberOfMiniDoubletsByLayer(unsigned int layer)
{
     if(layer == 6)
        return n_minidoublets_by_layer_barrel_[layer];
    else
        return n_minidoublets_by_layer_barrel_[layer] + n_minidoublets_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfMiniDoubletsByLayerBarrel(unsigned int layer)
{
    return n_minidoublets_by_layer_barrel_[layer];
}

unsigned int SDL::Event::getNumberOfMiniDoubletsByLayerEndcap(unsigned int layer)
{
    return n_minidoublets_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfSegments()
{
    unsigned int segments = 0;
    for(auto &it:n_segments_by_layer_barrel_)
    {
        segments += it;
    }
    for(auto &it:n_segments_by_layer_endcap_)
    {
        segments += it;
    }

    return segments;

}

unsigned int SDL::Event::getNumberOfSegmentsByLayer(unsigned int layer)
{
     if(layer == 6)
        return n_segments_by_layer_barrel_[layer];
    else
        return n_segments_by_layer_barrel_[layer] + n_segments_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfSegmentsByLayerBarrel(unsigned int layer)
{
    return n_segments_by_layer_barrel_[layer];
}

unsigned int SDL::Event::getNumberOfSegmentsByLayerEndcap(unsigned int layer)
{
    return n_segments_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfPixelTracklets()
{
#ifdef Explicit_Tracklet
    unsigned int nLowerModules;// = *(SDL::modulesInGPU->nLowerModules);
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
    unsigned int nTrackletsInPixelModule;
    cudaMemcpy(&nTrackletsInPixelModule,pixelTrackletsInGPU->nPixelTracklets,sizeof(unsigned int),cudaMemcpyDeviceToHost);
    return nTrackletsInPixelModule;
#else
    return *(pixelTrackletsInGPU->nPixelTracklets);
#endif

}

unsigned int SDL::Event::getNumberOfTracklets()
{
    unsigned int tracklets = 0;
    for(auto &it:n_tracklets_by_layer_barrel_)
    {
        tracklets += it;
    }
    for(auto &it:n_tracklets_by_layer_endcap_)
    {
        tracklets += it;
    }

    return tracklets;

}

unsigned int SDL::Event::getNumberOfTrackletsByLayer(unsigned int layer)
{
    if(layer == 6)
        return n_tracklets_by_layer_barrel_[layer];
    else
        return n_tracklets_by_layer_barrel_[layer] + n_tracklets_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfTrackletsByLayerBarrel(unsigned int layer)
{
    return n_tracklets_by_layer_barrel_[layer];
}

unsigned int SDL::Event::getNumberOfTrackletsByLayerEndcap(unsigned int layer)
{
    return n_tracklets_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfTriplets()
{
    unsigned int triplets = 0;
    for(auto &it:n_triplets_by_layer_barrel_)
    {
        triplets += it;
    }
    for(auto &it:n_triplets_by_layer_endcap_)
    {
        triplets += it;
    }

    return triplets;

}


unsigned int SDL::Event::getNumberOfTripletsByLayer(unsigned int layer)
{
    if(layer == 6)
        return n_triplets_by_layer_barrel_[layer];
    else
        return n_triplets_by_layer_barrel_[layer] + n_triplets_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfTripletsByLayerBarrel(unsigned int layer)
{
    return n_triplets_by_layer_barrel_[layer];
}

unsigned int SDL::Event::getNumberOfTripletsByLayerEndcap(unsigned int layer)
{
    return n_triplets_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfPixelTriplets()
{
#ifdef Explicit_PT3
    unsigned int nPixelTriplets;
    cudaMemcpy(&nPixelTriplets, pixelTripletsInGPU->nPixelTriplets, sizeof(unsigned int), cudaMemcpyDeviceToHost);
    return nPixelTriplets;
#else
    return *(pixelTripletsInGPU->nPixelTriplets); 
#endif
}

unsigned int SDL::Event::getNumberOfQuintuplets()
{
    unsigned int quintuplets = 0;
    for(auto &it:n_quintuplets_by_layer_barrel_)
    {
        quintuplets += it;
    }
    for(auto &it:n_quintuplets_by_layer_endcap_)
    {
        quintuplets += it;
    }

    return quintuplets;

}

unsigned int SDL::Event::getNumberOfQuintupletsByLayer(unsigned int layer)
{
    if(layer == 6)
        return n_quintuplets_by_layer_barrel_[layer];
    else
        return n_quintuplets_by_layer_barrel_[layer] + n_quintuplets_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfQuintupletsByLayerBarrel(unsigned int layer)
{
    return n_quintuplets_by_layer_barrel_[layer];
}

unsigned int SDL::Event::getNumberOfQuintupletsByLayerEndcap(unsigned int layer)
{
    return n_quintuplets_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfTrackCandidates()
{
    unsigned int trackCandidates = 0;
    for(auto &it:n_trackCandidates_by_layer_barrel_)
    {
        trackCandidates += it;
    }
    for(auto &it:n_trackCandidates_by_layer_endcap_)
    {
        trackCandidates += it;
    }

    //hack - add pixel track candidate multiplicity
    trackCandidates += getNumberOfPixelTrackCandidates();

    return trackCandidates;

}

unsigned int SDL::Event::getNumberOfPixelTrackCandidates()
{
#ifdef Explicit_Track
    unsigned int nLowerModules;// = *(SDL::modulesInGPU->nLowerModules);
    cudaMemcpy(&nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
    unsigned int nTrackCandidatesInPixelModule;
    cudaMemcpy(&nTrackCandidatesInPixelModule,&trackCandidatesInGPU->nTrackCandidates[nLowerModules],sizeof(unsigned int),cudaMemcpyDeviceToHost);
    return nTrackCandidatesInPixelModule;
#else
    return trackCandidatesInGPU->nTrackCandidates[*(modulesInGPU->nLowerModules)];
#endif

}
unsigned int SDL::Event::getNumberOfTrackCandidatesByLayer(unsigned int layer)
{
    if(layer == 6)
        return n_trackCandidates_by_layer_barrel_[layer];
    else
        return n_trackCandidates_by_layer_barrel_[layer] + n_tracklets_by_layer_endcap_[layer];
}

unsigned int SDL::Event::getNumberOfTrackCandidatesByLayerBarrel(unsigned int layer)
{
    return n_trackCandidates_by_layer_barrel_[layer];
}

unsigned int SDL::Event::getNumberOfTrackCandidatesByLayerEndcap(unsigned int layer)
{
    return n_trackCandidates_by_layer_endcap_[layer];
}

#ifdef Explicit_Hit
SDL::hits* SDL::Event::getHits() //std::shared_ptr should take care of garbage collection
{
    if(hitsInCPU == nullptr)
    {
        hitsInCPU = new SDL::hits;
        hitsInCPU->nHits = new unsigned int;
        unsigned int nHits;
        cudaMemcpy(&nHits, hitsInGPU->nHits, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        *(hitsInCPU->nHits) = nHits;
        hitsInCPU->idxs = new unsigned int[nHits];
        hitsInCPU->xs = new float[nHits];
        hitsInCPU->ys = new float[nHits];
        hitsInCPU->zs = new float[nHits];
        hitsInCPU->moduleIndices = new unsigned int[nHits];
        cudaMemcpy(hitsInCPU->idxs, hitsInGPU->idxs,sizeof(unsigned int) * nHits, cudaMemcpyDeviceToHost);
        cudaMemcpy(hitsInCPU->xs, hitsInGPU->xs, sizeof(float) * nHits, cudaMemcpyDeviceToHost);
        cudaMemcpy(hitsInCPU->ys, hitsInGPU->ys, sizeof(float) * nHits, cudaMemcpyDeviceToHost);
        cudaMemcpy(hitsInCPU->zs, hitsInGPU->zs, sizeof(float) * nHits, cudaMemcpyDeviceToHost);
        cudaMemcpy(hitsInCPU->moduleIndices, hitsInGPU->moduleIndices, sizeof(unsigned int) * nHits, cudaMemcpyDeviceToHost);
    }
    return hitsInCPU;
}
#else
SDL::hits* SDL::Event::getHits() //std::shared_ptr should take care of garbage collection
{
    return hitsInGPU;
}
#endif


#ifdef Explicit_MD
SDL::miniDoublets* SDL::Event::getMiniDoublets()
{
    if(mdsInCPU == nullptr)
    {
        mdsInCPU = new SDL::miniDoublets;
        unsigned int nMemoryLocations = (N_MAX_MD_PER_MODULES * (nModules - 1) + N_MAX_PIXEL_MD_PER_MODULES);
        mdsInCPU->hitIndices = new unsigned int[2 * nMemoryLocations];
        mdsInCPU->nMDs = new unsigned int[nModules];
        cudaMemcpy(mdsInCPU->hitIndices, mdsInGPU->hitIndices, 2 * nMemoryLocations * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(mdsInCPU->nMDs, mdsInGPU->nMDs, nModules * sizeof(unsigned int), cudaMemcpyDeviceToHost);
    }
    return mdsInCPU;
}
#else
SDL::miniDoublets* SDL::Event::getMiniDoublets()
{
    return mdsInGPU;
}
#endif


#ifdef Explicit_Seg
SDL::segments* SDL::Event::getSegments()
{
    if(segmentsInCPU == nullptr)
    {
        segmentsInCPU = new SDL::segments;
        unsigned int nMemoryLocations = (N_MAX_SEGMENTS_PER_MODULE) * (nModules - 1) + N_MAX_PIXEL_SEGMENTS_PER_MODULE;
        segmentsInCPU->mdIndices = new unsigned int[2 * nMemoryLocations];
        segmentsInCPU->nSegments = new unsigned int[nModules];
        segmentsInCPU->innerMiniDoubletAnchorHitIndices = new unsigned int[nMemoryLocations];
        segmentsInCPU->outerMiniDoubletAnchorHitIndices = new unsigned int[nMemoryLocations];
        segmentsInCPU->ptIn = new float[N_MAX_PIXEL_SEGMENTS_PER_MODULE];
        segmentsInCPU->eta = new float[N_MAX_PIXEL_SEGMENTS_PER_MODULE];
        segmentsInCPU->phi = new float[N_MAX_PIXEL_SEGMENTS_PER_MODULE];
        cudaMemcpy(segmentsInCPU->mdIndices, segmentsInGPU->mdIndices, 2 * nMemoryLocations * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(segmentsInCPU->nSegments, segmentsInGPU->nSegments, nModules * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(segmentsInCPU->innerMiniDoubletAnchorHitIndices, segmentsInGPU->innerMiniDoubletAnchorHitIndices, nMemoryLocations * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(segmentsInCPU->outerMiniDoubletAnchorHitIndices, segmentsInGPU->outerMiniDoubletAnchorHitIndices, nMemoryLocations * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(segmentsInCPU->ptIn, segmentsInGPU->ptIn, N_MAX_PIXEL_SEGMENTS_PER_MODULE * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(segmentsInCPU->eta, segmentsInGPU->eta, N_MAX_PIXEL_SEGMENTS_PER_MODULE * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(segmentsInCPU->phi, segmentsInGPU->phi, N_MAX_PIXEL_SEGMENTS_PER_MODULE * sizeof(float), cudaMemcpyDeviceToHost);


    }
    return segmentsInCPU;
}
#else
SDL::segments* SDL::Event::getSegments()
{
    return segmentsInGPU;
}
#endif

#ifdef Explicit_Tracklet
SDL::tracklets* SDL::Event::getTracklets()
{
#ifdef FINAL_T3T4
    if(trackletsInCPU == nullptr)
    {
        unsigned int nLowerModules;
        trackletsInCPU = new SDL::tracklets;
        cudaMemcpy(&nLowerModules, modulesInGPU->nLowerModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        unsigned int nMemoryLocations = (N_MAX_TRACKLETS_PER_MODULE) * nLowerModules;
        trackletsInCPU->segmentIndices = new unsigned int[2 * nMemoryLocations];
        trackletsInCPU->nTracklets = new unsigned int[nLowerModules];
        trackletsInCPU->betaIn = new float[nMemoryLocations];
        trackletsInCPU->betaOut = new float[nMemoryLocations];
        trackletsInCPU->pt_beta = new float[nMemoryLocations];
        cudaMemcpy(trackletsInCPU->segmentIndices, trackletsInGPU->segmentIndices, 2 * nMemoryLocations * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(trackletsInCPU->betaIn, trackletsInGPU->betaIn, nMemoryLocations * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(trackletsInCPU->betaOut, trackletsInGPU->betaOut, nMemoryLocations * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(trackletsInCPU->pt_beta, trackletsInGPU->pt_beta, nMemoryLocations * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(trackletsInCPU->nTracklets, trackletsInGPU->nTracklets, (nLowerModules)* sizeof(unsigned int), cudaMemcpyDeviceToHost);
    }
#endif
    return trackletsInCPU;
}

SDL::pixelTracklets* SDL::Event::getPixelTracklets()
{
    if(pixelTrackletsInCPU == nullptr)
    {
        pixelTrackletsInCPU = new SDL::pixelTracklets;
        pixelTrackletsInCPU->segmentIndices = new unsigned int[2 * N_MAX_PIXEL_TRACKLETS_PER_MODULE];
        pixelTrackletsInCPU->nPixelTracklets = new unsigned int;
        pixelTrackletsInCPU->betaIn = new float[N_MAX_PIXEL_TRACKLETS_PER_MODULE];
        pixelTrackletsInCPU->betaOut = new float[N_MAX_PIXEL_TRACKLETS_PER_MODULE];
        pixelTrackletsInCPU->pt_beta = new float[N_MAX_PIXEL_TRACKLETS_PER_MODULE];

        cudaMemcpy(pixelTrackletsInCPU->segmentIndices, pixelTrackletsInGPU->segmentIndices, 2 * N_MAX_PIXEL_TRACKLETS_PER_MODULE * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(pixelTrackletsInCPU->nPixelTracklets, pixelTrackletsInGPU->nPixelTracklets, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(pixelTrackletsInCPU->betaIn, pixelTrackletsInGPU->betaIn, N_MAX_PIXEL_TRACKLETS_PER_MODULE * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(pixelTrackletsInCPU->betaOut, pixelTrackletsInGPU->betaOut, N_MAX_PIXEL_TRACKLETS_PER_MODULE * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(pixelTrackletsInCPU->pt_beta, pixelTrackletsInGPU->pt_beta, N_MAX_PIXEL_TRACKLETS_PER_MODULE * sizeof(float), cudaMemcpyDeviceToHost);
    }
    return pixelTrackletsInCPU;
}

#else
SDL::tracklets* SDL::Event::getTracklets()
{
    return trackletsInGPU;
}

SDL::pixelTracklets* SDL::Event::getPixelTracklets()
{
    return pixelTrackletsInGPU;
}
#endif

#ifdef Explicit_Trips
SDL::triplets* SDL::Event::getTriplets()
{
    if(tripletsInCPU == nullptr)
    {
        unsigned int nLowerModules;
        tripletsInCPU = new SDL::triplets;
        cudaMemcpy(&nLowerModules, modulesInGPU->nLowerModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        unsigned int nMemoryLocations = (N_MAX_TRIPLETS_PER_MODULE) * (nLowerModules);
        tripletsInCPU->segmentIndices = new unsigned[2 * nMemoryLocations];
        tripletsInCPU->nTriplets = new unsigned int[nLowerModules];
        tripletsInCPU->betaIn = new float[nMemoryLocations];
        tripletsInCPU->betaOut = new float[nMemoryLocations];
        tripletsInCPU->pt_beta = new float[nMemoryLocations];
        cudaMemcpy(tripletsInCPU->segmentIndices, tripletsInGPU->segmentIndices, 2 * nMemoryLocations * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(tripletsInCPU->betaIn, tripletsInGPU->betaIn, nMemoryLocations * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(tripletsInCPU->betaOut, tripletsInGPU->betaOut, nMemoryLocations * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(tripletsInCPU->pt_beta, tripletsInGPU->pt_beta, nMemoryLocations * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(tripletsInCPU->nTriplets, tripletsInGPU->nTriplets, nLowerModules * sizeof(unsigned int), cudaMemcpyDeviceToHost);
    }
    return tripletsInCPU;
}
#else
SDL::triplets* SDL::Event::getTriplets()
{
    return tripletsInGPU;
}
#endif

#ifdef Explicit_T5
SDL::quintuplets* SDL::Event::getQuintuplets()
{
    if(quintupletsInCPU == nullptr)
    {
        quintupletsInCPU = new SDL::quintuplets;
        unsigned int nLowerModules;
        cudaMemcpy(&nLowerModules, modulesInGPU->nLowerModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        unsigned int nEligibleT5Modules;
        cudaMemcpy(&nEligibleT5Modules, modulesInGPU->nEligibleT5Modules, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        unsigned int nMemoryLocations = nEligibleT5Modules * N_MAX_QUINTUPLETS_PER_MODULE;

        quintupletsInCPU->nQuintuplets = new unsigned int[nLowerModules];
        quintupletsInCPU->tripletIndices = new unsigned int[2 * nMemoryLocations];
        quintupletsInCPU->lowerModuleIndices = new unsigned int[5 * nMemoryLocations];
        quintupletsInCPU->innerRadius = new float[nMemoryLocations];
        quintupletsInCPU->outerRadius = new float[nMemoryLocations];
        cudaMemcpy(quintupletsInCPU->nQuintuplets, quintupletsInGPU->nQuintuplets,  nLowerModules * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(quintupletsInCPU->tripletIndices, quintupletsInGPU->tripletIndices, 2 * nMemoryLocations * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(quintupletsInCPU->lowerModuleIndices, quintupletsInGPU->lowerModuleIndices, 5 * nMemoryLocations * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(quintupletsInCPU->innerRadius, quintupletsInGPU->innerRadius, nMemoryLocations * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(quintupletsInCPU->outerRadius, quintupletsInGPU->outerRadius, nMemoryLocations * sizeof(float), cudaMemcpyDeviceToHost);
    }

    return quintupletsInCPU;
}
#else
SDL::quintuplets* SDL::Event::getQuintuplets()
{
    return quintupletsInGPU;
}
#endif

#ifdef Explicit_PT3
SDL::pixelTriplets* SDL::Event::getPixelTriplets()
{
    if(pixelTripletsInCPU == nullptr)
    {
        pixelTripletsInCPU = new SDL::pixelTriplets;
        
        pixelTripletsInCPU->nPixelTriplets = new unsigned int;
        cudaMemcpy(pixelTripletsInCPU->nPixelTriplets, pixelTripletsInGPU->nPixelTriplets, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        unsigned int nPixelTriplets = *(pixelTripletsInCPU->nPixelTriplets);
        pixelTripletsInCPU->tripletIndices = new unsigned int[nPixelTriplets];
        pixelTripletsInCPU->pixelSegmentIndices = new unsigned int[nPixelTriplets];
        pixelTripletsInCPU->pixelRadius = new float[nPixelTriplets];
        pixelTripletsInCPU->pixelRadiusError = new float[nPixelTriplets];
        pixelTripletsInCPU->tripletRadius = new float[nPixelTriplets];

        cudaMemcpy(pixelTripletsInCPU->tripletIndices, pixelTripletsInGPU->tripletIndices, nPixelTriplets * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(pixelTripletsInCPU->pixelSegmentIndices, pixelTripletsInGPU->pixelSegmentIndices, nPixelTriplets * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(pixelTripletsInCPU->pixelRadius, pixelTripletsInGPU->pixelRadius, nPixelTriplets * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(pixelTripletsInCPU->tripletRadius, pixelTripletsInGPU->tripletRadius, nPixelTriplets * sizeof(float), cudaMemcpyDeviceToHost);
    }
    return pixelTripletsInCPU;
}
#else
SDL::pixelTriplets* SDL::Event::getPixelTriplets()
{
    return pixelTripletsInGPU;
}
#endif


#ifdef Explicit_Track
SDL::trackCandidates* SDL::Event::getTrackCandidates()
{
    if(trackCandidatesInCPU == nullptr)
    {
        trackCandidatesInCPU = new SDL::trackCandidates;
        unsigned int nLowerModules;
        cudaMemcpy(&nLowerModules, modulesInGPU->nLowerModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        unsigned int nEligibleModules;
        cudaMemcpy(&nEligibleModules, modulesInGPU->nEligibleModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        unsigned int nMemoryLocations = (N_MAX_TRACK_CANDIDATES_PER_MODULE) * (nEligibleModules -1) + (N_MAX_PIXEL_TRACK_CANDIDATES_PER_MODULE);

        trackCandidatesInCPU->objectIndices = new unsigned int[2 * nMemoryLocations];
        trackCandidatesInCPU->trackCandidateType = new short[nMemoryLocations];
        trackCandidatesInCPU->nTrackCandidates = new unsigned int[nLowerModules+1];
        cudaMemcpy(trackCandidatesInCPU->objectIndices, trackCandidatesInGPU->objectIndices, 2 * nMemoryLocations * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(trackCandidatesInCPU->trackCandidateType, trackCandidatesInGPU->trackCandidateType, nMemoryLocations * sizeof(short), cudaMemcpyDeviceToHost);
        cudaMemcpy(trackCandidatesInCPU->nTrackCandidates, trackCandidatesInGPU->nTrackCandidates, (nLowerModules + 1) * sizeof(unsigned int), cudaMemcpyDeviceToHost);
    }
    return trackCandidatesInCPU;
}
#else
SDL::trackCandidates* SDL::Event::getTrackCandidates()
{
    return trackCandidatesInGPU;
}
#endif
#ifdef Explicit_Module
SDL::modules* SDL::Event::getFullModules()
{
    if(modulesInCPUFull == nullptr)
    {
        modulesInCPUFull = new SDL::modules;
        unsigned int nLowerModules;
        cudaMemcpy(&nLowerModules, modulesInGPU->nLowerModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);

    modulesInCPUFull->detIds = new unsigned int[nModules];
    modulesInCPUFull->moduleMap = new unsigned int[40*nModules];
    modulesInCPUFull->nConnectedModules = new unsigned int[nModules];
    modulesInCPUFull->drdzs = new float[nModules];
    modulesInCPUFull->slopes = new float[nModules];
    modulesInCPUFull->nModules = new unsigned int[1];
    modulesInCPUFull->nLowerModules = new unsigned int[1];
    modulesInCPUFull->layers = new short[nModules];
    modulesInCPUFull->rings = new short[nModules];
    modulesInCPUFull->modules = new short[nModules];
    modulesInCPUFull->rods = new short[nModules];
    modulesInCPUFull->subdets = new short[nModules];
    modulesInCPUFull->sides = new short[nModules];
    modulesInCPUFull->isInverted = new bool[nModules];
    modulesInCPUFull->isLower = new bool[nModules];

    modulesInCPUFull->hitRanges = new int[2*nModules];
    modulesInCPUFull->mdRanges = new int[2*nModules];
    modulesInCPUFull->segmentRanges = new int[2*nModules];
    modulesInCPUFull->trackletRanges = new int[2*nModules];
    modulesInCPUFull->tripletRanges = new int[2*nModules];
    modulesInCPUFull->trackCandidateRanges = new int[2*nModules];

    modulesInCPUFull->moduleType = new ModuleType[nModules];
    modulesInCPUFull->moduleLayerType = new ModuleLayerType[nModules];

    modulesInCPUFull->lowerModuleIndices = new unsigned int[nLowerModules+1];
    modulesInCPUFull->reverseLookupLowerModuleIndices = new int[nModules];
    modulesInCPUFull->trackCandidateModuleIndices = new int[nLowerModules+1];
    modulesInCPUFull->quintupletModuleIndices = new int[nLowerModules];

    cudaMemcpy(modulesInCPUFull->detIds,modulesInGPU->detIds,nModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->moduleMap,modulesInGPU->moduleMap,40*nModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->nConnectedModules,modulesInGPU->nConnectedModules,nModules*sizeof(unsigned int),cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->drdzs,modulesInGPU->drdzs,sizeof(float)*nModules,cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->slopes,modulesInGPU->slopes,sizeof(float)*nModules,cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->nLowerModules,modulesInGPU->nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->layers,modulesInGPU->layers,nModules*sizeof(short),cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->rings,modulesInGPU->rings,sizeof(short)*nModules,cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->modules,modulesInGPU->modules,sizeof(short)*nModules,cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->rods,modulesInGPU->rods,sizeof(short)*nModules,cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->subdets,modulesInGPU->subdets,sizeof(short)*nModules,cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->sides,modulesInGPU->sides,sizeof(short)*nModules,cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->isInverted,modulesInGPU->isInverted,sizeof(bool)*nModules,cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->isLower,modulesInGPU->isLower,sizeof(bool)*nModules,cudaMemcpyDeviceToHost);

    cudaMemcpy(modulesInCPUFull->hitRanges, modulesInGPU->hitRanges, 2*nModules * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->mdRanges, modulesInGPU->mdRanges, 2*nModules * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->segmentRanges, modulesInGPU->segmentRanges, 2*nModules * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->trackletRanges, modulesInGPU->trackletRanges, 2*nModules * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->tripletRanges, modulesInGPU->tripletRanges, 2*nModules * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->trackCandidateRanges, modulesInGPU->trackCandidateRanges, 2*nModules * sizeof(int), cudaMemcpyDeviceToHost);

    cudaMemcpy(modulesInCPUFull->reverseLookupLowerModuleIndices, modulesInGPU->reverseLookupLowerModuleIndices, nModules * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->lowerModuleIndices, modulesInGPU->lowerModuleIndices, (nLowerModules+1) * sizeof(unsigned int), cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->trackCandidateModuleIndices, modulesInGPU->trackCandidateModuleIndices, (nLowerModules+1) * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->quintupletModuleIndices, modulesInGPU->quintupletModuleIndices, nLowerModules * sizeof(int), cudaMemcpyDeviceToHost);

    cudaMemcpy(modulesInCPUFull->moduleType,modulesInGPU->moduleType,sizeof(ModuleType)*nModules,cudaMemcpyDeviceToHost);
    cudaMemcpy(modulesInCPUFull->moduleLayerType,modulesInGPU->moduleLayerType,sizeof(ModuleLayerType)*nModules,cudaMemcpyDeviceToHost);
    }
    return modulesInCPUFull;
}
SDL::modules* SDL::Event::getModules()
{
    //if(modulesInCPU == nullptr)
    //{
        modulesInCPU = new SDL::modules;
        unsigned int nLowerModules;
        cudaMemcpy(&nLowerModules, modulesInGPU->nLowerModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        modulesInCPU->nLowerModules = new unsigned int[1];
        modulesInCPU->nModules = new unsigned int[1];
        modulesInCPU->lowerModuleIndices = new unsigned int[nLowerModules+1];
        modulesInCPU->detIds = new unsigned int[nModules];
        modulesInCPU->hitRanges = new int[2*nModules];
        modulesInCPU->isLower = new bool[nModules];
        modulesInCPU->trackCandidateModuleIndices = new int[nLowerModules+1];
        modulesInCPU->quintupletModuleIndices = new int[nLowerModules];
        modulesInCPU->layers = new short[nModules];
        modulesInCPU->subdets = new short[nModules];
        modulesInCPU->rings = new short[nModules];


        cudaMemcpy(modulesInCPU->nLowerModules, modulesInGPU->nLowerModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(modulesInCPU->nModules, modulesInGPU->nModules, sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(modulesInCPU->lowerModuleIndices, modulesInGPU->lowerModuleIndices, (nLowerModules+1) * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(modulesInCPU->detIds, modulesInGPU->detIds, nModules * sizeof(unsigned int), cudaMemcpyDeviceToHost);
        cudaMemcpy(modulesInCPU->hitRanges, modulesInGPU->hitRanges, 2*nModules * sizeof(int), cudaMemcpyDeviceToHost);
        cudaMemcpy(modulesInCPU->isLower, modulesInGPU->isLower, nModules * sizeof(bool), cudaMemcpyDeviceToHost);
        cudaMemcpy(modulesInCPU->trackCandidateModuleIndices, modulesInGPU->trackCandidateModuleIndices, (nLowerModules+1) * sizeof(int), cudaMemcpyDeviceToHost);
        cudaMemcpy(modulesInCPU->quintupletModuleIndices, modulesInGPU->quintupletModuleIndices, nLowerModules * sizeof(int), cudaMemcpyDeviceToHost);
        cudaMemcpy(modulesInCPU->layers, modulesInGPU->layers, nModules * sizeof(short), cudaMemcpyDeviceToHost);
        cudaMemcpy(modulesInCPU->subdets, modulesInGPU->subdets, nModules * sizeof(short), cudaMemcpyDeviceToHost);
        cudaMemcpy(modulesInCPU->rings, modulesInGPU->rings, nModules * sizeof(short), cudaMemcpyDeviceToHost);
    //}
    return modulesInCPU;
}
#else
SDL::modules* SDL::Event::getModules()
{
    return modulesInGPU;
}
SDL::modules* SDL::Event::getFullModules()
{
    return modulesInGPU;
}
#endif
