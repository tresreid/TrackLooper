#ifndef Event_h
#define Event_h

#include <vector>
#include <list>
#include <map>
#include <stdlib.h>
#include <stdexcept>
#include <iostream>
#include <cmath>
#include <cassert>
#include <bitset>

#include "Module.h"
#include "Hit.h"
#include "MiniDoublet.h"
#include "Segment.h"
#include "Triplet.h"
#include "Layer.h"
#include "PrintUtil.h"
#include "Algo.h"
#include "ModuleConnectionMap.h"

namespace SDL
{
    namespace CPU
    {
        class Event
        {
            private:

                // map of modules (this holds the actual instances)
                std::map<unsigned int, SDL::CPU::Module> modulesMapByDetId_;

                Layer pixelLayer_;

                // map of barrel layers (this holds the actual instances)
                std::map<int, Layer> barrelLayers_;

                // map of endcap layers (this holds the actual instances)
                std::map<int, Layer> endcapLayers_;

                // list of hits (this holds the actual instances)
                std::list<Hit> hits_;

                // list of hit_boundaries (this holds the actual instances) this is only used for the 2S in the endcap
                std::list<Hit> hits_2s_edges_;

                // list of pixel hits (this holds the actual instances)
                std::list<Hit> pixel_hits_;

                // list of MiniDoublets (this holds the actual instances)
                std::list<MiniDoublet> miniDoublets_;

                // list of pixel "MiniDoublets" two layers together (this holds the actual instances)
                std::list<MiniDoublet> pixel_miniDoublets_;

                // list of Segments (this holds the actual instances)
                std::list<Segment> segments_;

                // list of Triplets (this holds the actual instances)
                std::list<Triplet> triplets_;

                // list of Tracklets (this holds the actual instances)
                std::list<Tracklet> tracklets_;

                // list of TrackCandidates (this holds the actual instances)
                std::list<TrackCandidate> trackcandidates_;

                // list of module pointers (hold only the pointers to the actual instances)
                std::vector<SDL::CPU::Module*> modulePtrs_;

                // list of layer pointers (hold only the pointers to the actual instances)
                std::vector<Layer*> layerPtrs_;

                // list of lower module pointers (hold only the pointers to the actual instances)
                // (lower means, the module that is closer to the luminous region)
                std::vector<SDL::CPU::Module*> lowerModulePtrs_;

                // boolean to turn on debug mode
                SDL::CPU::LogLevel logLevel_;

                // diagnostic variables
                // # of hits in barrel
                std::array<unsigned int, 6> n_hits_by_layer_barrel_;

                // # of hits in endcap
                std::array<unsigned int, 5> n_hits_by_layer_endcap_;

                // # of hits in barrel in upper module
                std::array<unsigned int, 6> n_hits_by_layer_barrel_upper_;

                // # of hits in endcap in upper module
                std::array<unsigned int, 5> n_hits_by_layer_endcap_upper_;

                // # of pairs of hits considered for mini-doublet
                std::array<unsigned int, 6> n_miniDoublet_candidates_by_layer_barrel_;

                // # of pairs of mini-doublets considered for segment
                std::array<unsigned int, 6> n_segment_candidates_by_layer_barrel_;

                // # of pairs of segment considered for tracklet
                std::array<unsigned int, 6> n_tracklet_candidates_by_layer_barrel_;

                // # of pairs of segment considered for triplet
                std::array<unsigned int, 6> n_triplet_candidates_by_layer_barrel_;

                // # of pairs of tracklet considered for trackcandidate
                std::array<unsigned int, 6> n_trackcandidate_candidates_by_layer_barrel_;

                // # of pairs of hits considered for mini-doublet
                std::array<unsigned int, 6> n_miniDoublet_by_layer_barrel_;

                // # of pairs of mini-doublets considered for segment
                std::array<unsigned int, 6> n_segment_by_layer_barrel_;

                // # of pairs of segment considered for tracklet
                std::array<unsigned int, 6> n_tracklet_by_layer_barrel_;

                // # of pairs of segment considered for triplet
                std::array<unsigned int, 6> n_triplet_by_layer_barrel_;

                // # of pairs of tracklet considered for trackcandidate
                std::array<unsigned int, 6> n_trackcandidate_by_layer_barrel_;

                // # of pairs of hits considered for mini-doublet
                std::array<unsigned int, 5> n_miniDoublet_candidates_by_layer_endcap_;

                // # of pairs of mini-doublets considered for segment
                std::array<unsigned int, 5> n_segment_candidates_by_layer_endcap_;

                // # of pairs of segment considered for tracklet
                std::array<unsigned int, 5> n_tracklet_candidates_by_layer_endcap_;

                // # of pairs of segment considered for triplet
                std::array<unsigned int, 5> n_triplet_candidates_by_layer_endcap_;

                // # of pairs of tracklet considered for trackcandidate
                std::array<unsigned int, 5> n_trackcandidate_candidates_by_layer_endcap_;

                // # of pairs of hits considered for mini-doublet
                std::array<unsigned int, 5> n_miniDoublet_by_layer_endcap_;

                // # of pairs of mini-doublets considered for segment
                std::array<unsigned int, 5> n_segment_by_layer_endcap_;

                // # of pairs of segment considered for tracklet
                std::array<unsigned int, 5> n_tracklet_by_layer_endcap_;

                // # of pairs of segment considered for triplet
                std::array<unsigned int, 5> n_triplet_by_layer_endcap_;

                // # of pairs of tracklet considered for trackcandidate
                std::array<unsigned int, 5> n_trackcandidate_by_layer_endcap_;

                // Multiplicity of mini-doublet candidates considered in this event
                void incrementNumberOfHits(SDL::CPU::Module& module);

                // Multiplicity of mini-doublet candidates considered in this event
                void incrementNumberOfMiniDoubletCandidates(SDL::CPU::Module& module);

                // Multiplicity of segment candidates considered in this event
                void incrementNumberOfSegmentCandidates(SDL::CPU::Module& module);

                // Multiplicity of tracklet candidates considered in this event
                void incrementNumberOfTrackletCandidates(SDL::CPU::Layer& layer);

                // Multiplicity of tracklet candidates considered in this event
                void incrementNumberOfTrackletCandidates(SDL::CPU::Module& module);

                // Multiplicity of triplet candidates considered in this event
                void incrementNumberOfTripletCandidates(SDL::CPU::Module& module);

                // Multiplicity of track candidate candidates considered in this event
                void incrementNumberOfTrackCandidateCandidates(SDL::CPU::Layer& layer);

                // Multiplicity of track candidate candidates considered in this event
                void incrementNumberOfTrackCandidateCandidates(SDL::CPU::Module& module);

                // Multiplicity of mini-doublet formed in this event
                void incrementNumberOfMiniDoublets(SDL::CPU::Module& module);

                // Multiplicity of segment formed in this event
                void incrementNumberOfSegments(SDL::CPU::Module& module);

                // Multiplicity of tracklet formed in this event
                void incrementNumberOfTracklets(SDL::CPU::Layer& layer);

                // Multiplicity of tracklet formed in this event
                void incrementNumberOfTracklets(SDL::CPU::Module& module);

                // Multiplicity of triplet formed in this event
                void incrementNumberOfTriplets(SDL::CPU::Module& module);

                // Multiplicity of track candidate formed in this event
                void incrementNumberOfTrackCandidates(SDL::CPU::Layer& layer);

                // Multiplicity of track candidate formed in this event
                void incrementNumberOfTrackCandidates(SDL::CPU::Module& module);

            public:

                // cnstr/destr
                Event();
                ~Event();

                // Module related functions
                bool hasModule(unsigned int detId);
                Module& getModule(unsigned int detId);
                const std::vector<Module*> getModulePtrs() const;
                const std::vector<Module*> getLowerModulePtrs() const;

                // Layer related functions
                void createLayers();
                Layer& getLayer(int layer, SDL::CPU::Layer::SubDet subdet);
                Layer& getPixelLayer();
                const std::vector<Layer*> getLayerPtrs() const;

                // Set debug
                void setLogLevel(SDL::CPU::LogLevel logLevel=SDL::CPU::Log_Nothing);

                // Hit related functions
                void addHitToModule(SDL::CPU::Hit hit, unsigned int detId);

                // MiniDoublet related functions
                void addMiniDoubletToEvent(SDL::CPU::MiniDoublet md, unsigned int detId, int layerIdx, SDL::CPU::Layer::SubDet subdet);

                // MiniDoublet related functions
                void addMiniDoubletToLowerModule(SDL::CPU::MiniDoublet md, unsigned int detId);

                // Segment related functions
                void addSegmentToEvent(SDL::CPU::Segment sg, unsigned int detId, int layerIdx, SDL::CPU::Layer::SubDet subdet);

                // Segment related functions
                void addSegmentToLowerModule(SDL::CPU::Segment sg, unsigned int detId);

                // Segment related functions
                void addSegmentToLowerLayer(SDL::CPU::Segment sg, int layerIdx, SDL::CPU::Layer::SubDet subdet);

                // Triplet related functions
                void addTripletToEvent(SDL::CPU::Triplet tp, unsigned int detId, int layerIdx, SDL::CPU::Layer::SubDet subdet);

                // Tracklet related functions
                void addTrackletToEvent(SDL::CPU::Tracklet tp, unsigned int detId, int layerIdx, SDL::CPU::Layer::SubDet subdet);

                // Tracklet related functions
                void addTrackletToLowerLayer(SDL::CPU::Tracklet tl, int layerIdx, SDL::CPU::Layer::SubDet subdet);

                // TrackCandidate related functions
                void addTrackCandidateToLowerLayer(SDL::CPU::TrackCandidate tc, int layerIdx, SDL::CPU::Layer::SubDet subdet);

                // Pixel Segments related functions
                void addPixelSegmentsToEvent(std::vector<SDL::CPU::Hit> hits, float dPhiChange, float ptIn, float ptErr, float px, float py, float pz, float etaErr, int iSeed);

                // Create mini doublets
                void createMiniDoublets(MDAlgo algo=Default_MDAlgo);

                // Create mini doublet for a module
                void createMiniDoubletsFromLowerModule(unsigned int detId, MDAlgo algo=Default_MDAlgo);

                // Pseudo mini-doublet (which is really just a hit) for study purpose only
                void createPseudoMiniDoubletsFromAnchorModule(MDAlgo algo=Default_MDAlgo);

                // Create segments
                void createSegments(SGAlgo algo=Default_SGAlgo);

                // Create segments for a lower module
                void createSegmentsFromInnerLowerModule(unsigned int detId, SGAlgo algo=Default_SGAlgo);

                // Create segments
                void createSegmentsWithModuleMap(SGAlgo algo=Default_SGAlgo);

                // Create segments
                void createSegmentsFromTwoLayers(int innerLayerIdx, SDL::CPU::Layer::SubDet innerLayerSubDet, int outerLayerIdx, SDL::CPU::Layer::SubDet outerLayerSubDet, SGAlgo algo=Default_SGAlgo);

                // Create triplets
                void createTriplets(TPAlgo algo=Default_TPAlgo);

                // Create triplets for a lower module
                void createTripletsFromInnerLowerModule(unsigned int detId, TPAlgo algo=Default_TPAlgo);

                // Create tracklets
                void createTracklets(TLAlgo algo=Default_TLAlgo);

                // Create tracklets
                void createTrackletsWithModuleMap(TLAlgo algo=Default_TLAlgo);

                // Create tracklets for a inner segment upper module
                void createTrackletsFromInnerLowerModule(unsigned int detId, TLAlgo algo=Default_TLAlgo);

                // Create tracklets with a gap (single)
                void createTrackletsWithAGapWithModuleMap(TLAlgo algo=Default_TLAlgo);

                // Create tracklets for a inner segment upper module but with a gap (single)
                void createTrackletsWithAGapFromInnerLowerModule(unsigned int detId, SDL::CPU::TLAlgo algo);

                // Create tracklets with a gap (single)
                void createTrackletsWithTwoGapsWithModuleMap(TLAlgo algo=Default_TLAlgo);

                // Create tracklets for a inner segment upper module but with a gap (single)
                void createTrackletsWithTwoGapsFromInnerLowerModule(unsigned int detId, SDL::CPU::TLAlgo algo);

                // Create tracklets from two layers (inefficient way)
                void createTrackletsFromTwoLayers(int innerLayerIdx, SDL::CPU::Layer::SubDet innerLayerSubDet, int outerLayerIdx, SDL::CPU::Layer::SubDet outerLayerSubDet, TLAlgo algo=Default_TLAlgo);

                // Create T5s
                void createT5s();

                // Create tracklets
                void createTrackletsViaNavigation(TLAlgo algo=Default_TLAlgo);

                // Create tracklets with pixel line segments
                void createTrackletsWithPixelLineSegments(TLAlgo algo=Default_TLAlgo);
                void createTrackletsWithPixelLineSegments_v2(TLAlgo algo=Default_TLAlgo);

                // Create pT3s
                void createpT3s();

                // Create trackcandidates
                void createTrackCandidates(TCAlgo algo=Default_TCAlgo);

                // Create trackcandidates
                void createTrackCandidatesWithModuleMap(TCAlgo algo=Default_TCAlgo);

                // Create trackcandidates from two layers (inefficient way)
                void createTrackCandidatesFromTwoLayers(int innerLayerIdx, SDL::CPU::Layer::SubDet innerLayerSubDet, int outerLayerIdx, SDL::CPU::Layer::SubDet outerLayerSubDet, TCAlgo algo=Default_TCAlgo);

                // Create trackcandidates
                void createTrackCandidatesFromTriplets(TCAlgo algo=Default_TCAlgo);

                // Create trackcandidates
                void createTrackCandidatesFromTracklets(TCAlgo algo=Default_TCAlgo);

                // Create trackcandidates from two triplets
                void createTrackCandidatesFromInnerModulesFromTriplets(unsigned int detId, SDL::CPU::TCAlgo algo);

                // Create trackcandidates from two tracklets
                void createTrackCandidatesFromInnerModulesFromTracklets(unsigned int detId, SDL::CPU::TCAlgo algo);

                // Create trackcandidates from inner tracklets to outer triplets
                void createTrackCandidatesFromInnerModulesFromTrackletsToTriplets(unsigned int detId, SDL::CPU::TCAlgo algo);

                // Demonstration for create trackcandidates with multiple different types
                void createTrackCandidatesTest_v1(TCAlgo algo=Default_TCAlgo);
                void createTrackCandidatesTest_v2(TCAlgo algo=Default_TCAlgo);

                // Multiplicity of Hits
                unsigned int getNumberOfHits();

                // Multiplicity of hits in this event
                unsigned int getNumberOfHitsByLayerBarrel(unsigned int);

                // Multiplicity of hits in this event
                unsigned int getNumberOfHitsByLayerEndcap(unsigned int);

                // Multiplicity of hits in this event for upper module
                unsigned int getNumberOfHitsByLayerBarrelUpperModule(unsigned int);

                // Multiplicity of hits in this event for upper module
                unsigned int getNumberOfHitsByLayerEndcapUpperModule(unsigned int);

                // Multiplicity of mini-doublets
                unsigned int getNumberOfMiniDoublets();

                // Multiplicity of segments
                unsigned int getNumberOfSegments();

                // Multiplicity of tracklets
                unsigned int getNumberOfTracklets();

                // Multiplicity of triplets
                unsigned int getNumberOfTriplets();

                // Multiplicity of track candidates
                unsigned int getNumberOfTrackCandidates();

                // Multiplicity of mini-doublet candidates considered in this event
                unsigned int getNumberOfMiniDoubletCandidates();

                // Multiplicity of segment candidates considered in this event
                unsigned int getNumberOfSegmentCandidates();

                // Multiplicity of tracklet candidates considered in this event
                unsigned int getNumberOfTrackletCandidates();

                // Multiplicity of triplet candidates considered in this event
                unsigned int getNumberOfTripletCandidates();

                // Multiplicity of track candidate candidates considered in this event
                unsigned int getNumberOfTrackCandidateCandidates();

                // Multiplicity of mini-doublet candidates considered in this event
                unsigned int getNumberOfMiniDoubletCandidatesByLayerBarrel(unsigned int);

                // Multiplicity of segment candidates considered in this event
                unsigned int getNumberOfSegmentCandidatesByLayerBarrel(unsigned int);

                // Multiplicity of tracklet candidates considered in this event
                unsigned int getNumberOfTrackletCandidatesByLayerBarrel(unsigned int);

                // Multiplicity of triplet candidates considered in this event
                unsigned int getNumberOfTripletCandidatesByLayerBarrel(unsigned int);

                // Multiplicity of track candidate candidates considered in this event
                unsigned int getNumberOfTrackCandidateCandidatesByLayerBarrel(unsigned int);

                // Multiplicity of mini-doublet candidates considered in this event
                unsigned int getNumberOfMiniDoubletCandidatesByLayerEndcap(unsigned int);

                // Multiplicity of segment candidates considered in this event
                unsigned int getNumberOfSegmentCandidatesByLayerEndcap(unsigned int);

                // Multiplicity of tracklet candidates considered in this event
                unsigned int getNumberOfTrackletCandidatesByLayerEndcap(unsigned int);

                // Multiplicity of triplet candidates considered in this event
                unsigned int getNumberOfTripletCandidatesByLayerEndcap(unsigned int);

                // Multiplicity of track candidate candidates considered in this event
                unsigned int getNumberOfTrackCandidateCandidatesByLayerEndcap(unsigned int);

                // Multiplicity of mini-doublet formed in this event
                unsigned int getNumberOfMiniDoubletsByLayerBarrel(unsigned int);

                // Multiplicity of segment formed in this event
                unsigned int getNumberOfSegmentsByLayerBarrel(unsigned int);

                // Multiplicity of tracklet formed in this event
                unsigned int getNumberOfTrackletsByLayerBarrel(unsigned int);

                // Multiplicity of triplet formed in this event
                unsigned int getNumberOfTripletsByLayerBarrel(unsigned int);

                // Multiplicity of track candidate formed in this event
                unsigned int getNumberOfTrackCandidatesByLayerBarrel(unsigned int);

                // Multiplicity of mini-doublet formed in this event
                unsigned int getNumberOfMiniDoubletsByLayerEndcap(unsigned int);

                // Multiplicity of segment formed in this event
                unsigned int getNumberOfSegmentsByLayerEndcap(unsigned int);

                // Multiplicity of tracklet formed in this event
                unsigned int getNumberOfTrackletsByLayerEndcap(unsigned int);

                // Multiplicity of triplet formed in this event
                unsigned int getNumberOfTripletsByLayerEndcap(unsigned int);

                // Multiplicity of track candidate formed in this event
                unsigned int getNumberOfTrackCandidatesByLayerEndcap(unsigned int);

                // cout printing
                friend std::ostream& operator<<(std::ostream& out, const Event& event);
                friend std::ostream& operator<<(std::ostream& out, const Event* event);

        };
    }
}

#endif
