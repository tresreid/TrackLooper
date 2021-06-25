#ifdef __CUDACC__
#define CUDA_CONST_VAR __device__
#endif
# include "Quintuplet.cuh"
#include "allocate.h"

SDL::quintuplets::quintuplets()
{
    tripletIndices = nullptr;
    lowerModuleIndices = nullptr;
    nQuintuplets = nullptr;
    innerRadius = nullptr;
    outerRadius = nullptr;
    isDup = nullptr;
    pt = nullptr;
    layer = nullptr;
//    eta = nullptr;
//    phi = nullptr;

#ifdef CUT_VALUE_DEBUG
    innerRadiusMin = nullptr;
    innerRadiusMin2S = nullptr;
    innerRadiusMax = nullptr;
    innerRadiusMax2S = nullptr;
    bridgeRadius = nullptr;
    bridgeRadiusMin = nullptr;
    bridgeRadiusMin2S = nullptr;
    bridgeRadiusMax = nullptr;
    bridgeRadiusMax2S = nullptr;
    outerRadiusMin = nullptr;
    outerRadiusMin2S = nullptr;
    outerRadiusMax = nullptr;
    outerRadiusMax2S = nullptr;
#endif
}

SDL::quintuplets::~quintuplets()
{
}

void SDL::quintuplets::freeMemoryCache()
{
#ifdef Explicit_T5
    int dev;
    cudaGetDevice(&dev);
    cms::cuda::free_device(dev,tripletIndices);
    cms::cuda::free_device(dev, lowerModuleIndices);
    cms::cuda::free_device(dev, nQuintuplets);
    cms::cuda::free_device(dev, innerRadius);
    cms::cuda::free_device(dev, outerRadius);
    cms::cuda::free_device(dev, isDup);
    cms::cuda::free_device(dev, pt);
#else
    cms::cuda::free_managed(tripletIndices);
    cms::cuda::free_managed(lowerModuleIndices);
    cms::cuda::free_managed(nQuintuplets);
    cms::cuda::free_managed(innerRadius);
    cms::cuda::free_managed(outerRadius);
    cms::cuda::free_managed(isDup);
    cms::cuda::free_managed(pt);
#endif
}

void SDL::quintuplets::freeMemory()
{
    cudaFree(tripletIndices);
    cudaFree(lowerModuleIndices);
    cudaFree(nQuintuplets);
    cudaFree(innerRadius);
    cudaFree(outerRadius);
    cudaFree(isDup);
    cudaFree(pt);
    cudaFree(layer);

#ifdef CUT_VALUE_DEBUG
    cudaFree(innerRadiusMin);
    cudaFree(innerRadiusMin2S);
    cudaFree(innerRadiusMax);
    cudaFree(innerRadiusMax2S);
    cudaFree(bridgeRadius);
    cudaFree(bridgeRadiusMin);
    cudaFree(bridgeRadiusMin2S);
    cudaFree(bridgeRadiusMax);
    cudaFree(bridgeRadiusMax2S);
    cudaFree(outerRadiusMin);
    cudaFree(outerRadiusMin2S);
    cudaFree(outerRadiusMax);
    cudaFree(outerRadiusMax2S);
#endif
}

//TODO:Reuse the track candidate one instead of this!
void SDL::createEligibleModulesListForQuintuplets(struct modules& modulesInGPU,struct triplets& tripletsInGPU, unsigned int& nEligibleModules, unsigned int* indicesOfEligibleModules, unsigned int maxQuintuplets, unsigned int& maxTriplets)
{
    unsigned int nLowerModules;
    maxTriplets = 0;
    cudaMemcpy(&nLowerModules,modulesInGPU.nLowerModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
    unsigned int nModules;
    cudaMemcpy(&nModules,modulesInGPU.nModules,sizeof(unsigned int),cudaMemcpyDeviceToHost);
    cudaMemset(modulesInGPU.quintupletModuleIndices, -1, sizeof(int) * (nLowerModules));

    short* module_subdets;
    cudaMallocHost(&module_subdets, nModules* sizeof(short));
    cudaMemcpy(module_subdets,modulesInGPU.subdets,nModules*sizeof(short),cudaMemcpyDeviceToHost);
    unsigned int* module_lowerModuleIndices;
    cudaMallocHost(&module_lowerModuleIndices, nLowerModules * sizeof(unsigned int));
    cudaMemcpy(module_lowerModuleIndices,modulesInGPU.lowerModuleIndices, nLowerModules * sizeof(unsigned int),cudaMemcpyDeviceToHost);
    short* module_layers;
    cudaMallocHost(&module_layers, nModules * sizeof(short));
    cudaMemcpy(module_layers,modulesInGPU.layers,nModules * sizeof(short),cudaMemcpyDeviceToHost);
    int* module_quintupletModuleIndices;
    cudaMallocHost(&module_quintupletModuleIndices, nLowerModules * sizeof(int));
    cudaMemcpy(module_quintupletModuleIndices,modulesInGPU.quintupletModuleIndices,nLowerModules *sizeof(int),cudaMemcpyDeviceToHost);

    unsigned int* nTriplets;
    cudaMallocHost(&nTriplets, nLowerModules * sizeof(unsigned int));
    cudaMemcpy(nTriplets, tripletsInGPU.nTriplets, nLowerModules * sizeof(unsigned int), cudaMemcpyDeviceToHost);

    //start filling
    for(unsigned int i = 0; i < nLowerModules; i++)
    {
        //condition for a quintuple to exist for a module
        //TCs don't exist for layers 5 and 6 barrel, and layers 2,3,4,5 endcap
        unsigned int idx = module_lowerModuleIndices[i];
        if(((module_subdets[idx] == SDL::Barrel and module_layers[idx] < 5) or (module_subdets[idx] == SDL::Endcap and module_layers[idx] == 1)) and nTriplets[i] != 0)
        {
            module_quintupletModuleIndices[i] = nEligibleModules * maxQuintuplets;
            indicesOfEligibleModules[nEligibleModules] = i;
            nEligibleModules++;
            maxTriplets = max(nTriplets[i], maxTriplets);

        }
    }
    cudaMemcpy(modulesInGPU.quintupletModuleIndices,module_quintupletModuleIndices,nLowerModules*sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(modulesInGPU.nEligibleT5Modules,&nEligibleModules,sizeof(unsigned int),cudaMemcpyHostToDevice);
    cudaFreeHost(module_subdets);
    cudaFreeHost(module_lowerModuleIndices);
    cudaFreeHost(module_layers);
    cudaFreeHost(module_quintupletModuleIndices);
    cudaFreeHost(nTriplets);
}


void SDL::createQuintupletsInUnifiedMemory(struct SDL::quintuplets& quintupletsInGPU, const unsigned int& maxQuintuplets, const unsigned int& nLowerModules, const unsigned int& nEligibleModules)
{
    unsigned int nMemoryLocations = maxQuintuplets * nEligibleModules;
    std::cout<<"Number of eligible T5 modules = "<<nEligibleModules<<std::endl;

#ifdef CACHE_ALLOC
    cudaStream_t stream = 0;
    quintupletsInGPU.tripletIndices = (unsigned int*)cms::cuda::allocate_managed(nMemoryLocations * 2 * sizeof(unsigned int), stream);
    quintupletsInGPU.lowerModuleIndices = (unsigned int*)cms::cuda::allocate_managed(nMemoryLocations * 5 * sizeof(unsigned int), stream);
    quintupletsInGPU.nQuintuplets = (unsigned int*)cms::cuda::allocate_managed(nLowerModules * sizeof(unsigned int), stream);
    quintupletsInGPU.innerRadius = (float*)cms::cuda::allocate_managed(nMemoryLocations * sizeof(float), stream);
    quintupletsInGPU.outerRadius = (float*)cms::cuda::allocate_managed(nMemoryLocations * sizeof(float), stream);
    quintupletsInGPU.isDup = (bool*)cms::cuda::allocate_managed(nMemoryLocations * sizeof(bool), stream);
    quintupletsInGPU.pt = (float*)cms::cuda::allocate_managed(nMemoryLocations *5* sizeof(float), stream);
#else
    cudaMallocManaged(&quintupletsInGPU.tripletIndices, 2 * nMemoryLocations * sizeof(unsigned int));
    cudaMallocManaged(&quintupletsInGPU.lowerModuleIndices, 5 * nMemoryLocations * sizeof(unsigned int));

    cudaMallocManaged(&quintupletsInGPU.nQuintuplets, nLowerModules * sizeof(unsigned int));
    cudaMallocManaged(&quintupletsInGPU.innerRadius, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.outerRadius, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.isDup, nMemoryLocations * sizeof(bool));
    cudaMallocManaged(&quintupletsInGPU.pt, nMemoryLocations *16* sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.layer, nMemoryLocations *1* sizeof(int));

#ifdef CUT_VALUE_DEBUG
    cudaMallocManaged(&quintupletsInGPU.innerRadiusMin, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.innerRadiusMax, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.bridgeRadius, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.bridgeRadiusMin, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.bridgeRadiusMax, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.outerRadiusMin, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.outerRadiusMax, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.innerRadiusMin2S, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.innerRadiusMax2S, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.bridgeRadiusMin2S, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.bridgeRadiusMax2S, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.outerRadiusMin2S, nMemoryLocations * sizeof(float));
    cudaMallocManaged(&quintupletsInGPU.outerRadiusMax2S, nMemoryLocations * sizeof(float));
#endif
#endif
    quintupletsInGPU.eta = quintupletsInGPU.pt + nMemoryLocations;
    quintupletsInGPU.phi = quintupletsInGPU.pt + 2*nMemoryLocations;
    quintupletsInGPU.distance = quintupletsInGPU.pt + 3*nMemoryLocations;
    quintupletsInGPU.slope = quintupletsInGPU.pt + 4*nMemoryLocations;
    quintupletsInGPU.score = quintupletsInGPU.pt + 5*nMemoryLocations;
    quintupletsInGPU.score2 = quintupletsInGPU.pt + 6*nMemoryLocations;
    quintupletsInGPU.score3 = quintupletsInGPU.pt + 7*nMemoryLocations;
    quintupletsInGPU.score4 = quintupletsInGPU.pt + 8*nMemoryLocations;
    quintupletsInGPU.score5 = quintupletsInGPU.pt + 9*nMemoryLocations;
    quintupletsInGPU.score6 = quintupletsInGPU.pt + 10*nMemoryLocations;
    quintupletsInGPU.score7 = quintupletsInGPU.pt + 11*nMemoryLocations;
    quintupletsInGPU.score8 = quintupletsInGPU.pt + 12*nMemoryLocations;
    quintupletsInGPU.score9 = quintupletsInGPU.pt + 13*nMemoryLocations;
    quintupletsInGPU.p1 = quintupletsInGPU.pt + 14*nMemoryLocations;
    quintupletsInGPU.p2 = quintupletsInGPU.pt + 15*nMemoryLocations;
#pragma omp parallel for
    for(size_t i = 0; i<nLowerModules;i++)
    {
        quintupletsInGPU.nQuintuplets[i] = 0;
    }

}

void SDL::createQuintupletsInExplicitMemory(struct SDL::quintuplets& quintupletsInGPU, const unsigned int& maxQuintuplets, const unsigned int& nLowerModules, const unsigned int& nEligibleModules)
{
    unsigned int nMemoryLocations = nEligibleModules * maxQuintuplets;
#ifdef CACHE_ALLOC
    cudaStream_t stream = 0;
    int dev;
    cudaGetDevice(&dev);
    quintupletsInGPU.tripletIndices = (unsigned int*)cms::cuda::allocate_device(dev, 2 * nMemoryLocations * sizeof(unsigned int), stream);
    quintupletsInGPU.lowerModuleIndices = (unsigned int*)cms::cuda::allocate_device(dev, 5 * nMemoryLocations * sizeof(unsigned int), stream);
    quintupletsInGPU.nQuintuplets = (unsigned int*)cms::cuda::allocate_device(dev, nLowerModules * sizeof(unsigned int), stream);
    quintupletsInGPU.innerRadius = (float*)cms::cuda::allocate_device(dev, nMemoryLocations * sizeof(float), stream);
    quintupletsInGPU.outerRadius = (float*)cms::cuda::allocate_device(dev, nMemoryLocations * sizeof(float), stream);
    quintupletsInGPU.isDup = (bool*)cms::cuda::allocate_device(dev, nMemoryLocations * sizeof(bool), stream);
    quintupletsInGPU.pt = (float*)cms::cuda::allocate_device(dev, nMemoryLocations *5* sizeof(float), stream);
#else
    cudaMalloc(&quintupletsInGPU.tripletIndices, 2 * nMemoryLocations * sizeof(unsigned int));
    cudaMalloc(&quintupletsInGPU.lowerModuleIndices, 5 * nMemoryLocations * sizeof(unsigned int));
    cudaMalloc(&quintupletsInGPU.nQuintuplets, nLowerModules * sizeof(unsigned int));
    cudaMalloc(&quintupletsInGPU.innerRadius, nMemoryLocations * sizeof(float));
    cudaMalloc(&quintupletsInGPU.outerRadius, nMemoryLocations * sizeof(float));
    cudaMalloc(&quintupletsInGPU.isDup, nMemoryLocations * sizeof(bool));
    cudaMalloc(&quintupletsInGPU.pt, nMemoryLocations *16* sizeof(float));
    cudaMalloc(&quintupletsInGPU.layer, nMemoryLocations *1* sizeof(int));
#endif
    quintupletsInGPU.eta = quintupletsInGPU.pt + nMemoryLocations;
    quintupletsInGPU.phi = quintupletsInGPU.pt + 2*nMemoryLocations;
    quintupletsInGPU.distance = quintupletsInGPU.pt + 3*nMemoryLocations;
    quintupletsInGPU.slope = quintupletsInGPU.pt + 4*nMemoryLocations;
    quintupletsInGPU.score = quintupletsInGPU.pt + 5*nMemoryLocations;
    quintupletsInGPU.score2 = quintupletsInGPU.pt + 6*nMemoryLocations;
    quintupletsInGPU.score3 = quintupletsInGPU.pt + 7*nMemoryLocations;
    quintupletsInGPU.score4 = quintupletsInGPU.pt + 8*nMemoryLocations;
    quintupletsInGPU.score5 = quintupletsInGPU.pt + 9*nMemoryLocations;
    quintupletsInGPU.score6 = quintupletsInGPU.pt + 10*nMemoryLocations;
    quintupletsInGPU.score7 = quintupletsInGPU.pt + 11*nMemoryLocations;
    quintupletsInGPU.score8 = quintupletsInGPU.pt + 12*nMemoryLocations;
    quintupletsInGPU.score9 = quintupletsInGPU.pt + 13*nMemoryLocations;
    quintupletsInGPU.p1 = quintupletsInGPU.pt + 14*nMemoryLocations;
    quintupletsInGPU.p2 = quintupletsInGPU.pt + 15*nMemoryLocations;
    cudaMemset(quintupletsInGPU.nQuintuplets,0,nLowerModules * sizeof(unsigned int));
}


#ifdef CUT_VALUE_DEBUG
__device__ void SDL::addQuintupletToMemory(struct SDL::quintuplets& quintupletsInGPU, unsigned int innerTripletIndex, unsigned int outerTripletIndex, unsigned int lowerModule1, unsigned int lowerModule2, unsigned int lowerModule3, unsigned int lowerModule4, unsigned int lowerModule5, float innerRadius, float innerRadiusMin, float innerRadiusMax, float outerRadius, float outerRadiusMin, float outerRadiusMax, float bridgeRadius, float bridgeRadiusMin, float bridgeRadiusMax,
        float innerRadiusMin2S, float innerRadiusMax2S, float bridgeRadiusMin2S, float bridgeRadiusMax2S, float outerRadiusMin2S, float outerRadiusMax2S,unsigned int quintupletIndex)

#else
__device__ void SDL::addQuintupletToMemory(struct SDL::quintuplets& quintupletsInGPU, unsigned int innerTripletIndex, unsigned int outerTripletIndex, unsigned int lowerModule1, unsigned int lowerModule2, unsigned int lowerModule3, unsigned int lowerModule4, unsigned int lowerModule5, float innerRadius, float outerRadius, unsigned int quintupletIndex,bool isDup, float pt, float eta, float phi,float distance,float* scores,int layer)
#endif

{
    quintupletsInGPU.tripletIndices[2 * quintupletIndex] = innerTripletIndex;
    quintupletsInGPU.tripletIndices[2 * quintupletIndex + 1] = outerTripletIndex;

    quintupletsInGPU.lowerModuleIndices[5 * quintupletIndex] = lowerModule1;
    quintupletsInGPU.lowerModuleIndices[5 * quintupletIndex + 1] = lowerModule2;
    quintupletsInGPU.lowerModuleIndices[5 * quintupletIndex + 2] = lowerModule3;
    quintupletsInGPU.lowerModuleIndices[5 * quintupletIndex + 3] = lowerModule4;
    quintupletsInGPU.lowerModuleIndices[5 * quintupletIndex + 4] = lowerModule5;
    quintupletsInGPU.innerRadius[quintupletIndex] = innerRadius;
    quintupletsInGPU.outerRadius[quintupletIndex] = outerRadius;
    quintupletsInGPU.isDup[quintupletIndex] = isDup;
    quintupletsInGPU.pt[quintupletIndex] = pt;
    quintupletsInGPU.eta[quintupletIndex] = eta;
    quintupletsInGPU.phi[quintupletIndex] = phi;
    quintupletsInGPU.distance[quintupletIndex] = distance;
    quintupletsInGPU.slope[quintupletIndex] = scores[0];
    quintupletsInGPU.score[quintupletIndex] = scores[1];
    quintupletsInGPU.score2[quintupletIndex] = scores[2];
    quintupletsInGPU.score3[quintupletIndex] = scores[3];
    quintupletsInGPU.score4[quintupletIndex] = scores[4];
    quintupletsInGPU.score5[quintupletIndex] = scores[5];
    quintupletsInGPU.score6[quintupletIndex] = scores[6];
    quintupletsInGPU.score7[quintupletIndex] = scores[7];
    quintupletsInGPU.score8[quintupletIndex] = scores[8];
    quintupletsInGPU.score9[quintupletIndex] = scores[9];
    quintupletsInGPU.p1[quintupletIndex] = scores[10];
    quintupletsInGPU.p2[quintupletIndex] = scores[11];
    quintupletsInGPU.layer[quintupletIndex] = layer;

#ifdef CUT_VALUE_DEBUG
    quintupletsInGPU.innerRadiusMin[quintupletIndex] = innerRadiusMin;
    quintupletsInGPU.innerRadiusMax[quintupletIndex] = innerRadiusMax;
    quintupletsInGPU.outerRadiusMin[quintupletIndex] = outerRadiusMin;
    quintupletsInGPU.outerRadiusMax[quintupletIndex] = outerRadiusMax;
    quintupletsInGPU.bridgeRadius[quintupletIndex] = bridgeRadius;
    quintupletsInGPU.bridgeRadiusMin[quintupletIndex] = bridgeRadiusMin;
    quintupletsInGPU.bridgeRadiusMax[quintupletIndex] = bridgeRadiusMax;
    quintupletsInGPU.innerRadiusMin2S[quintupletIndex] = innerRadiusMin2S;
    quintupletsInGPU.innerRadiusMax2S[quintupletIndex] = innerRadiusMax2S;
    quintupletsInGPU.bridgeRadiusMin2S[quintupletIndex] = bridgeRadiusMin2S;
    quintupletsInGPU.bridgeRadiusMax2S[quintupletIndex] = bridgeRadiusMax2S;
    quintupletsInGPU.outerRadiusMin2S[quintupletIndex] = outerRadiusMin2S;
    quintupletsInGPU.outerRadiusMax2S[quintupletIndex] = outerRadiusMax2S;
#endif

}
__device__ void SDL::rmQuintupletToMemory(struct SDL::quintuplets& quintupletsInGPU,unsigned int quintupletIndex)
{
    quintupletsInGPU.isDup[quintupletIndex] = 1;

}
__device__ bool SDL::runQuintupletDefaultAlgo(struct SDL::modules& modulesInGPU, struct SDL::hits& hitsInGPU, struct SDL::miniDoublets& mdsInGPU, struct SDL::segments& segmentsInGPU, struct SDL::triplets& tripletsInGPU, unsigned int lowerModuleIndex1, unsigned int lowerModuleIndex2, unsigned int lowerModuleIndex3, unsigned int lowerModuleIndex4, unsigned int lowerModuleIndex5, unsigned int innerTripletIndex, unsigned int outerTripletIndex, float& innerRadius, float& innerRadiusMin, float&
    innerRadiusMax, float& outerRadius, float& outerRadiusMin, float& outerRadiusMax, float& bridgeRadius, float& bridgeRadiusMin, float& bridgeRadiusMax, float& innerRadiusMin2S, float& innerRadiusMax2S, float& bridgeRadiusMin2S, float& bridgeRadiusMax2S, float& outerRadiusMin2S, float& outerRadiusMax2S)
{
    bool pass = true;

    //if(not T5HasCommonMiniDoublet(tripletsInGPU, segmentsInGPU, innerTripletIndex, outerTripletIndex))
    //{
    //    pass = false;
    //}

    unsigned int firstSegmentIndex = tripletsInGPU.segmentIndices[2 * innerTripletIndex];
    unsigned int secondSegmentIndex = tripletsInGPU.segmentIndices[2 * innerTripletIndex + 1];
    unsigned int thirdSegmentIndex = tripletsInGPU.segmentIndices[2 * outerTripletIndex];
    unsigned int fourthSegmentIndex = tripletsInGPU.segmentIndices[2 * outerTripletIndex + 1];

    unsigned int innerOuterOuterMiniDoubletIndex = segmentsInGPU.mdIndices[2 * secondSegmentIndex + 1]; //inner triplet outer segment outer MD index
    unsigned int outerInnerInnerMiniDoubletIndex = segmentsInGPU.mdIndices[2 * thirdSegmentIndex]; //outer triplet inner segmnet inner MD index

    if (innerOuterOuterMiniDoubletIndex != outerInnerInnerMiniDoubletIndex) pass = false;

    //apply T4 criteria between segments 1 and 3
    float zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta; //temp stuff
    float zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ;
    if(not runTrackletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, segmentsInGPU.innerLowerModuleIndices[firstSegmentIndex], segmentsInGPU.outerLowerModuleIndices[firstSegmentIndex], segmentsInGPU.innerLowerModuleIndices[thirdSegmentIndex], segmentsInGPU.outerLowerModuleIndices[thirdSegmentIndex], firstSegmentIndex, thirdSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ))
    {
        pass = false;
    }
    if(not runTrackletDefaultAlgo(modulesInGPU, hitsInGPU, mdsInGPU, segmentsInGPU, segmentsInGPU.innerLowerModuleIndices[firstSegmentIndex], segmentsInGPU.outerLowerModuleIndices[firstSegmentIndex], segmentsInGPU.innerLowerModuleIndices[fourthSegmentIndex], segmentsInGPU.outerLowerModuleIndices[fourthSegmentIndex], firstSegmentIndex, fourthSegmentIndex, zOut, rtOut, deltaPhiPos, deltaPhi, betaIn, betaOut, pt_beta, zLo, zHi, rtLo, rtHi, zLoPointed, zHiPointed, sdlCut, betaInCut, betaOutCut, deltaBetaCut, kZ))
    {
        pass = false;
    }

    //radius computation from the three triplet MD anchor hits
    unsigned int innerTripletFirstSegmentAnchorHitIndex = segmentsInGPU.innerMiniDoubletAnchorHitIndices[firstSegmentIndex];
    unsigned int innerTripletSecondSegmentAnchorHitIndex = segmentsInGPU.outerMiniDoubletAnchorHitIndices[firstSegmentIndex]; //same as second segment inner MD anchorhit index
    unsigned int innerTripletThirdSegmentAnchorHitIndex = segmentsInGPU.outerMiniDoubletAnchorHitIndices[secondSegmentIndex]; //same as third segment inner MD anchor hit index

    unsigned int outerTripletSecondSegmentAnchorHitIndex = segmentsInGPU.outerMiniDoubletAnchorHitIndices[thirdSegmentIndex]; //same as fourth segment inner MD anchor hit index
    unsigned int outerTripletThirdSegmentAnchorHitIndex = segmentsInGPU.outerMiniDoubletAnchorHitIndices[fourthSegmentIndex];

    float x1 = hitsInGPU.xs[innerTripletFirstSegmentAnchorHitIndex];
    float x2 = hitsInGPU.xs[innerTripletSecondSegmentAnchorHitIndex];
    float x3 = hitsInGPU.xs[innerTripletThirdSegmentAnchorHitIndex];
    float x4 = hitsInGPU.xs[outerTripletSecondSegmentAnchorHitIndex];
    float x5 = hitsInGPU.xs[outerTripletThirdSegmentAnchorHitIndex];

    float y1 = hitsInGPU.ys[innerTripletFirstSegmentAnchorHitIndex];
    float y2 = hitsInGPU.ys[innerTripletSecondSegmentAnchorHitIndex];
    float y3 = hitsInGPU.ys[innerTripletThirdSegmentAnchorHitIndex];
    float y4 = hitsInGPU.ys[outerTripletSecondSegmentAnchorHitIndex];
    float y5 = hitsInGPU.ys[outerTripletThirdSegmentAnchorHitIndex];


    //construct the arrays
    float x1Vec[] = {x1, x1, x1};
    float y1Vec[] = {y1, y1, y1};
    float x2Vec[] = {x2, x2, x2};
    float y2Vec[] = {y2, y2, y2};
    float x3Vec[] = {x3, x3, x3};
    float y3Vec[] = {y3, y3, y3};
    //float x4Vec[] = {x4, x4, x4};
    //float y4Vec[] = {y4, y4, y4};
    //float x5Vec[] = {x5, x5, x5};
    //float y5Vec[] = {y5, y5, y5};

    if(modulesInGPU.subdets[lowerModuleIndex1] == SDL::Endcap and modulesInGPU.moduleType[lowerModuleIndex1] == SDL::TwoS)
    {
        x1Vec[1] = hitsInGPU.lowEdgeXs[innerTripletFirstSegmentAnchorHitIndex];
        x1Vec[2] = hitsInGPU.highEdgeXs[innerTripletFirstSegmentAnchorHitIndex];

        y1Vec[1] = hitsInGPU.lowEdgeYs[innerTripletFirstSegmentAnchorHitIndex];
        y1Vec[2] = hitsInGPU.highEdgeYs[innerTripletFirstSegmentAnchorHitIndex];
    }
    if(modulesInGPU.subdets[lowerModuleIndex2] == SDL::Endcap and modulesInGPU.moduleType[lowerModuleIndex2] == SDL::TwoS)
    {
        x2Vec[1] = hitsInGPU.lowEdgeXs[innerTripletSecondSegmentAnchorHitIndex];
        x2Vec[2] = hitsInGPU.highEdgeXs[innerTripletSecondSegmentAnchorHitIndex];

        y2Vec[1] = hitsInGPU.lowEdgeYs[innerTripletSecondSegmentAnchorHitIndex];
        y2Vec[2] = hitsInGPU.highEdgeYs[innerTripletSecondSegmentAnchorHitIndex];

    }
    if(modulesInGPU.subdets[lowerModuleIndex3] == SDL::Endcap and modulesInGPU.moduleType[lowerModuleIndex3] == SDL::TwoS)
    {
        x3Vec[1] = hitsInGPU.lowEdgeXs[innerTripletThirdSegmentAnchorHitIndex];
        x3Vec[2] = hitsInGPU.highEdgeXs[innerTripletThirdSegmentAnchorHitIndex];

        y3Vec[1] = hitsInGPU.lowEdgeYs[innerTripletThirdSegmentAnchorHitIndex];
        y3Vec[2] = hitsInGPU.highEdgeYs[innerTripletThirdSegmentAnchorHitIndex];
    }
    computeErrorInRadius(x1Vec, y1Vec, x2Vec, y2Vec, x3Vec, y3Vec, innerRadiusMin2S, innerRadiusMax2S);

    for (int i=0; i<3; i++) {
      x1Vec[i] = x4;
      y1Vec[i] = y4;
    }
    if(modulesInGPU.subdets[lowerModuleIndex4] == SDL::Endcap and modulesInGPU.moduleType[lowerModuleIndex4] == SDL::TwoS)
    {
        x1Vec[1] = hitsInGPU.lowEdgeXs[outerTripletSecondSegmentAnchorHitIndex];
        x1Vec[2] = hitsInGPU.highEdgeXs[outerTripletSecondSegmentAnchorHitIndex];

        y1Vec[1] = hitsInGPU.lowEdgeYs[outerTripletSecondSegmentAnchorHitIndex];
        y1Vec[2] = hitsInGPU.highEdgeYs[outerTripletSecondSegmentAnchorHitIndex];
    }
    computeErrorInRadius(x2Vec, y2Vec, x3Vec, y3Vec, x1Vec, y1Vec, bridgeRadiusMin2S, bridgeRadiusMax2S);

    for(int i=0; i<3; i++) {
      x2Vec[i] = x5;
      y2Vec[i] = y5;
    }
    if(modulesInGPU.subdets[lowerModuleIndex5] == SDL::Endcap and modulesInGPU.moduleType[lowerModuleIndex5] == SDL::TwoS)
    {
        x2Vec[1] = hitsInGPU.lowEdgeXs[outerTripletThirdSegmentAnchorHitIndex];
        x2Vec[2] = hitsInGPU.highEdgeXs[outerTripletThirdSegmentAnchorHitIndex];

        y2Vec[1] = hitsInGPU.lowEdgeYs[outerTripletThirdSegmentAnchorHitIndex];
        y2Vec[2] = hitsInGPU.highEdgeYs[outerTripletThirdSegmentAnchorHitIndex];
    }
    computeErrorInRadius(x3Vec, y3Vec, x1Vec, y1Vec, x2Vec, y2Vec, outerRadiusMin2S, outerRadiusMax2S);

    innerRadius = computeRadiusFromThreeAnchorHits(x1, y1, x2, y2, x3, y3);
    outerRadius = computeRadiusFromThreeAnchorHits(x3, y3, x4, y4, x5, y5);
    bridgeRadius = computeRadiusFromThreeAnchorHits(x2, y2, x3, y3, x4, y4);


    //computeErrorInRadius(x1Vec, y1Vec, x2Vec, y2Vec, x3Vec, y3Vec, innerRadiusMin2S, innerRadiusMax2S);
    //computeErrorInRadius(x2Vec, y2Vec, x3Vec, y3Vec, x4Vec, y4Vec, bridgeRadiusMin2S, bridgeRadiusMax2S);
    //computeErrorInRadius(x3Vec, y3Vec, x4Vec, y4Vec, x5Vec, y5Vec, outerRadiusMin2S, outerRadiusMax2S);

    if(innerRadius < 0.95/(2 * k2Rinv1GeVf))
    {
        pass = false;
    }
    //split by category
    bool tempPass;
    if(modulesInGPU.subdets[lowerModuleIndex1] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex2] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex3] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex4] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex5] == SDL::Barrel)
    {
       tempPass = matchRadiiBBBBB(innerRadius, bridgeRadius, outerRadius, innerRadiusMin, innerRadiusMax, bridgeRadiusMin, bridgeRadiusMax, outerRadiusMin, outerRadiusMax);
    }
    else if(modulesInGPU.subdets[lowerModuleIndex1] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex2] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex3] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex4] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex5] == SDL::Endcap)
    {
        tempPass = matchRadiiBBBBE(innerRadius, bridgeRadius, outerRadius, innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S, outerRadiusMax2S, innerRadiusMin, innerRadiusMax, bridgeRadiusMin, bridgeRadiusMax, outerRadiusMin, outerRadiusMax);
    }
    else if(modulesInGPU.subdets[lowerModuleIndex1] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex2] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex3] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex4] == SDL::Endcap and modulesInGPU.subdets[lowerModuleIndex5] == SDL::Endcap)
    {
        if(modulesInGPU.layers[lowerModuleIndex1] == 1)
        {
            tempPass = matchRadiiBBBEE12378(innerRadius, bridgeRadius, outerRadius,innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S, outerRadiusMax2S, innerRadiusMin, innerRadiusMax, bridgeRadiusMin, bridgeRadiusMax, outerRadiusMin, outerRadiusMax);
        }
        else if(modulesInGPU.layers[lowerModuleIndex1] == 2)
        {
            tempPass = matchRadiiBBBEE23478(innerRadius, bridgeRadius, outerRadius,innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S, outerRadiusMax2S, innerRadiusMin, innerRadiusMax, bridgeRadiusMin, bridgeRadiusMax, outerRadiusMin, outerRadiusMax);
        }
        else
        {
            tempPass = matchRadiiBBBEE34578(innerRadius, bridgeRadius, outerRadius,innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S, outerRadiusMax2S, innerRadiusMin, innerRadiusMax, bridgeRadiusMin, bridgeRadiusMax, outerRadiusMin, outerRadiusMax);
        }
    }

    else if(modulesInGPU.subdets[lowerModuleIndex1] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex2] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex3] == SDL::Endcap and modulesInGPU.subdets[lowerModuleIndex4] == SDL::Endcap and modulesInGPU.subdets[lowerModuleIndex5] == SDL::Endcap)
    {
        tempPass = matchRadiiBBEEE(innerRadius, bridgeRadius, outerRadius, innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S, outerRadiusMax2S, innerRadiusMin, innerRadiusMax, bridgeRadiusMin, bridgeRadiusMax, outerRadiusMin, outerRadiusMax);
    }
    else if(modulesInGPU.subdets[lowerModuleIndex1] == SDL::Barrel and modulesInGPU.subdets[lowerModuleIndex2] == SDL::Endcap and modulesInGPU.subdets[lowerModuleIndex3] == SDL::Endcap and modulesInGPU.subdets[lowerModuleIndex4] == SDL::Endcap and modulesInGPU.subdets[lowerModuleIndex5] == SDL::Endcap)
    {
        tempPass = matchRadiiBEEEE(innerRadius, bridgeRadius, outerRadius, innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S, outerRadiusMax2S, innerRadiusMin, innerRadiusMax, bridgeRadiusMin, bridgeRadiusMax, outerRadiusMin, outerRadiusMax);
    }
    else
    {
        tempPass = matchRadiiEEEEE(innerRadius, bridgeRadius, outerRadius, innerRadiusMin2S, innerRadiusMax2S, bridgeRadiusMin2S, bridgeRadiusMax2S, outerRadiusMin2S, outerRadiusMax2S,innerRadiusMin, innerRadiusMax, bridgeRadiusMin, bridgeRadiusMax, outerRadiusMin, outerRadiusMax);
    }

    pass = pass & tempPass;
    return pass;
}

__device__ bool SDL::checkIntervalOverlap(const float& firstMin, const float& firstMax, const float& secondMin, const float& secondMax)
{
    return ((firstMin <= secondMin) & (secondMin < firstMax)) |  ((secondMin < firstMin) & (firstMin < secondMax));
}

/*bounds for high Pt taken from : http://uaf-10.t2.ucsd.edu/~bsathian/SDL/T5_efficiency/efficiencies/new_efficiencies/efficiencies_20210513_T5_recovering_high_Pt_efficiencies/highE_radius_matching/highE_bounds.txt */

__device__ bool SDL::matchRadiiBBBBB(const float& innerRadius, const float& bridgeRadius, const float& outerRadius, float& innerRadiusMin, float& innerRadiusMax, float& bridgeRadiusMin, float& bridgeRadiusMax, float& outerRadiusMin, float& outerRadiusMax)
{
    float innerInvRadiusErrorBound =  0.1512;
    float bridgeInvRadiusErrorBound = 0.1781;
    float outerInvRadiusErrorBound = 0.1840;

    if(innerRadius > 2.0/(2 * k2Rinv1GeVf))
    {
        innerInvRadiusErrorBound = 0.4449;
        bridgeInvRadiusErrorBound = 0.4033;
        outerInvRadiusErrorBound = 0.8016;
    }

    innerRadiusMin = innerRadius/(1 + innerInvRadiusErrorBound);
    innerRadiusMax = innerInvRadiusErrorBound < 1 ? innerRadius/(1 - innerInvRadiusErrorBound) : 123456789.f;

    bridgeRadiusMin = bridgeRadius/(1 + bridgeInvRadiusErrorBound);
    bridgeRadiusMax = bridgeInvRadiusErrorBound < 1 ? bridgeRadius/(1 - bridgeInvRadiusErrorBound) : 123456789.f;

    outerRadiusMin = outerRadius/(1 + outerInvRadiusErrorBound);
    outerRadiusMax = outerInvRadiusErrorBound < 1 ? outerRadius/(1 - outerInvRadiusErrorBound) : 123456789.f;

    return checkIntervalOverlap(1.0/innerRadiusMax, 1.0/innerRadiusMin, 1.0/bridgeRadiusMax, 1.0/bridgeRadiusMin);
}

__device__ bool SDL::matchRadiiBBBBE(const float& innerRadius, const float& bridgeRadius, const float& outerRadius, const float& innerRadiusMin2S, const float& innerRadiusMax2S, const float& bridgeRadiusMin2S, const float& bridgeRadiusMax2S, const float& outerRadiusMin2S, const float& outerRadiusMax2S, float& innerRadiusMin, float& innerRadiusMax, float& bridgeRadiusMin, float& bridgeRadiusMax, float& outerRadiusMin, float& outerRadiusMax)
{

    float innerInvRadiusErrorBound =  0.1781;
    float bridgeInvRadiusErrorBound = 0.2167;
    float outerInvRadiusErrorBound = 1.1116;

    if(innerRadius > 2.0/(2 * k2Rinv1GeVf))
    {
        innerInvRadiusErrorBound = 0.4750;
        bridgeInvRadiusErrorBound = 0.3903;
        outerInvRadiusErrorBound = 15.2120;
    }


    innerRadiusMin = innerRadius/(1 + innerInvRadiusErrorBound);
    innerRadiusMax = innerInvRadiusErrorBound < 1 ? innerRadius/(1 - innerInvRadiusErrorBound) : 123456789.f; //large number signifying infty

    bridgeRadiusMin = bridgeRadius/(1 + bridgeInvRadiusErrorBound);
    bridgeRadiusMax = bridgeInvRadiusErrorBound < 1 ? bridgeRadius/(1 - bridgeInvRadiusErrorBound) : 123456789.f;

    outerRadiusMin = outerRadius/(1 + outerInvRadiusErrorBound);
    outerRadiusMax = outerInvRadiusErrorBound < 1 ? outerRadius/(1 - outerInvRadiusErrorBound) : 123456789.f;

    return checkIntervalOverlap(1.0/innerRadiusMax, 1.0/innerRadiusMin, 1.0/bridgeRadiusMax, 1.0/bridgeRadiusMin);
}

__device__ bool SDL::matchRadiiBBBEE12378(const float& innerRadius, const float& bridgeRadius, const float& outerRadius, const float& innerRadiusMin2S, const float& innerRadiusMax2S, const float& bridgeRadiusMin2S, const float& bridgeRadiusMax2S, const float& outerRadiusMin2S, const float& outerRadiusMax2S, float& innerRadiusMin, float& innerRadiusMax, float& bridgeRadiusMin, float& bridgeRadiusMax, float& outerRadiusMin, float& outerRadiusMax)
{
    float innerInvRadiusErrorBound = 0.178;
    float bridgeInvRadiusErrorBound = 0.507;
    float outerInvRadiusErrorBound = 7.655;

    innerRadiusMin = innerRadius/(1 + innerInvRadiusErrorBound);
    innerRadiusMax = innerInvRadiusErrorBound < 1 ? innerRadius/(1 - innerInvRadiusErrorBound) : 123456789.f;

    bridgeRadiusMin = bridgeRadius/(1 + bridgeInvRadiusErrorBound);
    bridgeRadiusMax = bridgeInvRadiusErrorBound < 1 ? bridgeRadius/(1 - bridgeInvRadiusErrorBound) : 123456789.f;

    outerRadiusMin = outerRadius/(1 + outerInvRadiusErrorBound);
    outerRadiusMax = outerInvRadiusErrorBound < 1 ? outerRadius/(1 - outerInvRadiusErrorBound) : 123456789.f;

    return checkIntervalOverlap(1.0/innerRadiusMax, 1.0/innerRadiusMin, 1.0/fmaxf(bridgeRadiusMax, bridgeRadiusMax2S),1.0/fminf(bridgeRadiusMin, bridgeRadiusMin2S));
}

__device__ bool SDL::matchRadiiBBBEE23478(const float& innerRadius, const float& bridgeRadius, const float& outerRadius, const float& innerRadiusMin2S, const float& innerRadiusMax2S, const float& bridgeRadiusMin2S, const float& bridgeRadiusMax2S, const float& outerRadiusMin2S, const float& outerRadiusMax2S, float& innerRadiusMin, float& innerRadiusMax, float& bridgeRadiusMin, float& bridgeRadiusMax, float& outerRadiusMin, float& outerRadiusMax)
{
    float innerInvRadiusErrorBound = 0.2097;
    float bridgeInvRadiusErrorBound = 0.8557;
    float outerInvRadiusErrorBound = 24.0450;

    innerRadiusMin = innerRadius/(1 + innerInvRadiusErrorBound);
    innerRadiusMax = innerInvRadiusErrorBound < 1 ? innerRadius/(1 - innerInvRadiusErrorBound) : 123456789.f;

    bridgeRadiusMin = bridgeRadius/(1 + bridgeInvRadiusErrorBound);
    bridgeRadiusMax = bridgeInvRadiusErrorBound < 1 ? bridgeRadius/(1 - bridgeInvRadiusErrorBound) : 123456789.f;

    outerRadiusMin = outerRadius/(1 + outerInvRadiusErrorBound);
    outerRadiusMax = outerInvRadiusErrorBound < 1 ? outerRadius/(1 - outerInvRadiusErrorBound) : 123456789.f;

    return checkIntervalOverlap(1.0/innerRadiusMax, 1.0/innerRadiusMin, 1.0/fmaxf(bridgeRadiusMax, bridgeRadiusMax2S), 1.0/fminf(bridgeRadiusMin, bridgeRadiusMin2S));

}

__device__ bool SDL::matchRadiiBBBEE34578(const float& innerRadius, const float& bridgeRadius, const float& outerRadius, const float& innerRadiusMin2S, const float& innerRadiusMax2S, const float& bridgeRadiusMin2S, const float& bridgeRadiusMax2S, const float& outerRadiusMin2S, const float& outerRadiusMax2S, float& innerRadiusMin, float& innerRadiusMax, float& bridgeRadiusMin, float& bridgeRadiusMax, float& outerRadiusMin, float& outerRadiusMax)
{
    float innerInvRadiusErrorBound = 0.066;
    float bridgeInvRadiusErrorBound = 0.617;
    float outerInvRadiusErrorBound = 2.688;

    innerRadiusMin = innerRadius/(1 + innerInvRadiusErrorBound);
    innerRadiusMax = innerInvRadiusErrorBound < 1 ? innerRadius/(1 - innerInvRadiusErrorBound) : 123456789.f;

    bridgeRadiusMin = bridgeRadius/(1 + bridgeInvRadiusErrorBound);
    bridgeRadiusMax = bridgeInvRadiusErrorBound < 1 ? bridgeRadius/(1 - bridgeInvRadiusErrorBound) : 123456789.f;

    outerRadiusMin = outerRadius/(1 + outerInvRadiusErrorBound);
    outerRadiusMax = outerInvRadiusErrorBound < 1 ? outerRadius/(1 - outerInvRadiusErrorBound) : 123456789.f;

    return checkIntervalOverlap(1.0/innerRadiusMax, 1.0/innerRadiusMin, 1.0/fmaxf(bridgeRadiusMax, bridgeRadiusMax2S), 1.0/fminf(bridgeRadiusMin, bridgeRadiusMin2S));

}

__device__ bool SDL::matchRadiiBBBEE(const float& innerRadius, const float& bridgeRadius, const float& outerRadius, const float& innerRadiusMin2S, const float& innerRadiusMax2S, const float& bridgeRadiusMin2S, const float& bridgeRadiusMax2S, const float& outerRadiusMin2S, const float& outerRadiusMax2S, float& innerRadiusMin, float& innerRadiusMax, float& bridgeRadiusMin, float& bridgeRadiusMax, float& outerRadiusMin, float& outerRadiusMax)
{

    float innerInvRadiusErrorBound =  0.1840;
    float bridgeInvRadiusErrorBound = 0.5971;
    float outerInvRadiusErrorBound = 11.7102;

    if(innerRadius > 2.0/(2 * k2Rinv1GeVf)) //as good as no selections
    {
        innerInvRadiusErrorBound = 1.0412;
        outerInvRadiusErrorBound = 32.2737;
        bridgeInvRadiusErrorBound = 10.9688;
    }

    innerRadiusMin = innerRadius/(1 + innerInvRadiusErrorBound);
    innerRadiusMax = innerInvRadiusErrorBound < 1 ? innerRadius/(1 - innerInvRadiusErrorBound) : 123456789.f;

    bridgeRadiusMin = bridgeRadius/(1 + bridgeInvRadiusErrorBound);
    bridgeRadiusMax = bridgeInvRadiusErrorBound < 1 ? bridgeRadius/(1 - bridgeInvRadiusErrorBound) : 123456789.f;

    outerRadiusMin = outerRadius/(1 + outerInvRadiusErrorBound);
    outerRadiusMax = outerInvRadiusErrorBound < 1 ? outerRadius/(1 - outerInvRadiusErrorBound) : 123456789.f;

    return checkIntervalOverlap(1.0/innerRadiusMax, 1.0/innerRadiusMin, 1.0/fmaxf(bridgeRadiusMax, bridgeRadiusMax2S), 1.0/fminf(bridgeRadiusMin, bridgeRadiusMin2S));

}

__device__ bool SDL::matchRadiiBBEEE(const float& innerRadius, const float& bridgeRadius, const float& outerRadius, const float& innerRadiusMin2S, const float& innerRadiusMax2S, const float& bridgeRadiusMin2S, const float& bridgeRadiusMax2S, const float& outerRadiusMin2S, const float& outerRadiusMax2S, float& innerRadiusMin, float& innerRadiusMax, float& bridgeRadiusMin, float& bridgeRadiusMax, float& outerRadiusMin, float& outerRadiusMax)
{

    float innerInvRadiusErrorBound =  0.6376;
    float bridgeInvRadiusErrorBound = 2.1381;
    float outerInvRadiusErrorBound = 20.4179;

    if(innerRadius > 2.0/(2 * k2Rinv1GeVf)) //as good as no selections!
    {
        innerInvRadiusErrorBound = 12.9173;
        outerInvRadiusErrorBound = 25.6702;
        bridgeInvRadiusErrorBound = 5.1700;
    }

    innerRadiusMin = innerRadius/(1 + innerInvRadiusErrorBound);
    innerRadiusMax = innerInvRadiusErrorBound < 1 ? innerRadius/(1 - innerInvRadiusErrorBound) : 123456789.f;

    bridgeRadiusMin = bridgeRadius/(1 + bridgeInvRadiusErrorBound);
    bridgeRadiusMax = bridgeInvRadiusErrorBound < 1 ? bridgeRadius/(1 - bridgeInvRadiusErrorBound) : 123456789.f;

    outerRadiusMin = outerRadius/(1 + outerInvRadiusErrorBound);
    outerRadiusMax = outerInvRadiusErrorBound < 1 ? outerRadius/(1 - outerInvRadiusErrorBound) : 123456789.f;

    return checkIntervalOverlap(1.0/innerRadiusMax, 1.0/innerRadiusMin, 1.0/fmaxf(bridgeRadiusMax, bridgeRadiusMax2S), 1.0/fminf(bridgeRadiusMin, bridgeRadiusMin2S));

}

__device__ bool SDL::matchRadiiBEEEE(const float& innerRadius, const float& bridgeRadius, const float& outerRadius, const float& innerRadiusMin2S, const float& innerRadiusMax2S, const float& bridgeRadiusMin2S, const float& bridgeRadiusMax2S, const float& outerRadiusMin2S, const float& outerRadiusMax2S, float& innerRadiusMin, float& innerRadiusMax, float& bridgeRadiusMin, float& bridgeRadiusMax, float& outerRadiusMin, float& outerRadiusMax)
{

    float innerInvRadiusErrorBound =  1.9382;
    float bridgeInvRadiusErrorBound = 3.7280;
    float outerInvRadiusErrorBound = 5.7030;


    if(innerRadius > 2.0/(2 * k2Rinv1GeVf))
    {
        innerInvRadiusErrorBound = 23.2713;
        outerInvRadiusErrorBound = 24.0450;
        bridgeInvRadiusErrorBound = 21.7980;
    }

    innerRadiusMin = innerRadius/(1 + innerInvRadiusErrorBound);
    innerRadiusMax = innerInvRadiusErrorBound < 1 ? innerRadius/(1 - innerInvRadiusErrorBound) : 123456789.f;

    bridgeRadiusMin = bridgeRadius/(1 + bridgeInvRadiusErrorBound);
    bridgeRadiusMax = bridgeInvRadiusErrorBound < 1 ? bridgeRadius/(1 - bridgeInvRadiusErrorBound) : 123456789.f;

    outerRadiusMin = outerRadius/(1 + outerInvRadiusErrorBound);
    outerRadiusMax = outerInvRadiusErrorBound < 1 ? outerRadius/(1 - outerInvRadiusErrorBound) : 123456789.f;

    return checkIntervalOverlap(1.0/fmaxf(innerRadiusMax, innerRadiusMax2S), 1.0/fminf(innerRadiusMin, innerRadiusMin2S), 1.0/fmaxf(bridgeRadiusMax, bridgeRadiusMax2S), 1.0/fminf(bridgeRadiusMin, bridgeRadiusMin2S));

}

__device__ bool SDL::matchRadiiEEEEE(const float& innerRadius, const float& bridgeRadius, const float& outerRadius, const float& innerRadiusMin2S, const float& innerRadiusMax2S, const float& bridgeRadiusMin2S, const float& bridgeRadiusMax2S, const float& outerRadiusMin2S, const float& outerRadiusMax2S, float& innerRadiusMin, float& innerRadiusMax, float& bridgeRadiusMin, float& bridgeRadiusMax, float& outerRadiusMin, float& outerRadiusMax)
{
    float innerInvRadiusErrorBound =  1.9382;
    float bridgeInvRadiusErrorBound = 2.2091;
    float outerInvRadiusErrorBound = 7.4084;

    if(innerRadius > 2.0/(2 * k2Rinv1GeVf))
    {
        innerInvRadiusErrorBound = 22.5226;
        bridgeInvRadiusErrorBound = 21.0966;
        outerInvRadiusErrorBound = 19.1252;
    }

    innerRadiusMin = innerRadius/(1 + innerInvRadiusErrorBound);
    innerRadiusMax = innerInvRadiusErrorBound < 1 ? innerRadius/(1 - innerInvRadiusErrorBound) : 123456789.f;

    bridgeRadiusMin = bridgeRadius/(1 + bridgeInvRadiusErrorBound);
    bridgeRadiusMax = bridgeInvRadiusErrorBound < 1 ? bridgeRadius/(1 - bridgeInvRadiusErrorBound) : 123456789.f;

    outerRadiusMin = outerRadius/(1 + outerInvRadiusErrorBound);
    outerRadiusMax = outerInvRadiusErrorBound < 1 ? outerRadius/(1 - outerInvRadiusErrorBound) : 123456789.f;

    return checkIntervalOverlap(1.0/fmaxf(innerRadiusMax, innerRadiusMax2S), 1.0/fminf(innerRadiusMin, innerRadiusMin2S), 1.0/fmaxf(bridgeRadiusMax, bridgeRadiusMax2S), 1.0/fminf(bridgeRadiusMin, bridgeRadiusMin2S));

}

__device__ void SDL::computeErrorInRadius(float* x1Vec, float* y1Vec, float* x2Vec, float* y2Vec, float* x3Vec, float* y3Vec, float& minimumRadius, float& maximumRadius)
{
    //brute force
    float candidateRadius;
    minimumRadius = 123456789.f;
    maximumRadius = 0;
    for(size_t i = 0; i < 3; i++)
    {
        float x1 = x1Vec[i];
	float y1 = y1Vec[i];
        for(size_t j = 0; j < 3; j++)
        {
	    float x2 = x2Vec[j];
	    float y2 = y2Vec[j];
            for(size_t k = 0; k < 3; k++)
            {
	       float x3 = x3Vec[k];
               float y3 = y3Vec[k];
               candidateRadius = computeRadiusFromThreeAnchorHits(x1, y1, x2, y2, x3, y3);
               maximumRadius = fmaxf(candidateRadius, maximumRadius);
               minimumRadius = fminf(candidateRadius, minimumRadius);
            }
        }
    }
}
__device__ float SDL::computeRadiusFromThreeAnchorHits(float x1, float y1, float x2, float y2, float x3, float y3)
{
    float radius = 0;

    //writing manual code for computing radius, which obviously sucks
    //TODO:Use fancy inbuilt libraries like cuBLAS or cuSOLVE for this!
    //(g,f) -> center
    //first anchor hit - (x1,y1), second anchor hit - (x2,y2), third anchor hit - (x3, y3)

    /*
    if((y1 - y3) * (x2 - x3) - (x1 - x3) * (y2 - y3) == 0)
    {
        return -1; //WTF man three collinear points!
    }
    */

    float denomInv = 1.0/((y1 - y3) * (x2 - x3) - (x1 - x3) * (y2 - y3));

    float xy1sqr = x1 * x1 + y1 * y1;

    float xy2sqr = x2 * x2 + y2 * y2;

    float xy3sqr = x3 * x3 + y3 * y3;

    float g = 0.5 * ((y3 - y2) * xy1sqr + (y1 - y3) * xy2sqr + (y2 - y1) * xy3sqr) * denomInv;

    float f = 0.5 * ((x2 - x3) * xy1sqr + (x3 - x1) * xy2sqr + (x1 - x2) * xy3sqr) * denomInv;

    float c = ((x2 * y3 - x3 * y2) * xy1sqr + (x3 * y1 - x1 * y3) * xy2sqr + (x1 * y2 - x2 * y1) * xy3sqr) * denomInv;

    if(((y1 - y3) * (x2 - x3) - (x1 - x3) * (y2 - y3) == 0) || (g * g + f * f - c < 0))
    {
        printf("three collinear points or FATAL! r^2 < 0!\n");
	radius = -1;
    }
    else
      radius = sqrtf(g * g  + f * f - c);

    return radius;
}

__device__ bool SDL::T5HasCommonMiniDoublet(struct SDL::triplets& tripletsInGPU, struct SDL::segments& segmentsInGPU, unsigned int innerTripletIndex, unsigned int outerTripletIndex)
{
    unsigned int innerOuterSegmentIndex = tripletsInGPU.segmentIndices[2 * innerTripletIndex + 1];
    unsigned int outerInnerSegmentIndex = tripletsInGPU.segmentIndices[2 * outerTripletIndex];
    unsigned int innerOuterOuterMiniDoubletIndex = segmentsInGPU.mdIndices[2 * innerOuterSegmentIndex + 1]; //inner triplet outer segment outer MD index
    unsigned int outerInnerInnerMiniDoubletIndex = segmentsInGPU.mdIndices[2 * outerInnerSegmentIndex]; //outer triplet inner segmnet inner MD index


    return (innerOuterOuterMiniDoubletIndex == outerInnerInnerMiniDoubletIndex);
}
