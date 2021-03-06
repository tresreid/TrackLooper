// -*- C++ -*-
#ifndef SDL_H
#define SDL_H
#include "Math/LorentzVector.h"
#include "Math/Point3D.h"
#include "TMath.h"
#include "TBranch.h"
#include "TTree.h"
#include "TH1F.h"
#include "TFile.h"
#include "TBits.h"
#include <vector>
#include <unistd.h>
typedef ROOT::Math::LorentzVector<ROOT::Math::PxPyPzE4D<float> > LorentzVector;

// Generated with file: /home/users/bsathian/SDL/TrackLooper_central_take3/TrackLooper/output/outputs_478b0bb_PU200/gpu_unified.root

using namespace std;
class SDL {
private:
protected:
  unsigned int index;
  vector<float> *t3_eta_;
  TBranch *t3_eta_branch;
  bool t3_eta_isLoaded;
  vector<float> *t3_phi_;
  TBranch *t3_phi_branch;
  bool t3_phi_isLoaded;
  vector<int> *sim_parentVtxIdx_;
  TBranch *sim_parentVtxIdx_branch;
  bool sim_parentVtxIdx_isLoaded;
  vector<int> *t3_isDuplicate_;
  TBranch *t3_isDuplicate_branch;
  bool t3_isDuplicate_isLoaded;
  vector<float> *pLS_phi_;
  TBranch *pLS_phi_branch;
  bool pLS_phi_isLoaded;
  vector<int> *sim_event_;
  TBranch *sim_event_branch;
  bool sim_event_isLoaded;
  vector<int> *sim_pT4_matched_;
  TBranch *sim_pT4_matched_branch;
  bool sim_pT4_matched_isLoaded;
  vector<int> *sim_q_;
  TBranch *sim_q_branch;
  bool sim_q_isLoaded;
  vector<float> *sim_eta_;
  TBranch *sim_eta_branch;
  bool sim_eta_isLoaded;
  vector<float> *tc_eta_;
  TBranch *tc_eta_branch;
  bool tc_eta_isLoaded;
  vector<float> *tc_phi_;
  TBranch *tc_phi_branch;
  bool tc_phi_isLoaded;
  vector<int> *sim_T5_matched_;
  TBranch *sim_T5_matched_branch;
  bool sim_T5_matched_isLoaded;
  vector<vector<int> > *sim_T5_types_;
  TBranch *sim_T5_types_branch;
  bool sim_T5_types_isLoaded;
  vector<int> *t4_occupancies_;
  TBranch *t4_occupancies_branch;
  bool t4_occupancies_isLoaded;
  vector<int> *t3_occupancies_;
  TBranch *t3_occupancies_branch;
  bool t3_occupancies_isLoaded;
  vector<int> *t5_isDuplicate_;
  TBranch *t5_isDuplicate_branch;
  bool t5_isDuplicate_isLoaded;
  vector<vector<int> > *sim_pT4_types_;
  TBranch *sim_pT4_types_branch;
  bool sim_pT4_types_isLoaded;
  vector<vector<int> > *sim_tcIdx_;
  TBranch *sim_tcIdx_branch;
  bool sim_tcIdx_isLoaded;
  vector<int> *t4_isFake_;
  TBranch *t4_isFake_branch;
  bool t4_isFake_isLoaded;
  vector<int> *tc_occupancies_;
  TBranch *tc_occupancies_branch;
  bool tc_occupancies_isLoaded;
  vector<float> *simvtx_x_;
  TBranch *simvtx_x_branch;
  bool simvtx_x_isLoaded;
  vector<float> *simvtx_y_;
  TBranch *simvtx_y_branch;
  bool simvtx_y_isLoaded;
  vector<float> *simvtx_z_;
  TBranch *simvtx_z_branch;
  bool simvtx_z_isLoaded;
  vector<int> *sim_T4_matched_;
  TBranch *sim_T4_matched_branch;
  bool sim_T4_matched_isLoaded;
  vector<int> *sim_TC_matched_;
  TBranch *sim_TC_matched_branch;
  bool sim_TC_matched_isLoaded;
  vector<int> *pLS_isDuplicate_;
  TBranch *pLS_isDuplicate_branch;
  bool pLS_isDuplicate_isLoaded;
  vector<int> *module_subdets_;
  TBranch *module_subdets_branch;
  bool module_subdets_isLoaded;
  vector<int> *t5_occupancies_;
  TBranch *t5_occupancies_branch;
  bool t5_occupancies_isLoaded;
  vector<float> *tc_pt_;
  TBranch *tc_pt_branch;
  bool tc_pt_isLoaded;
  vector<int> *tc_isDuplicate_;
  TBranch *tc_isDuplicate_branch;
  bool tc_isDuplicate_isLoaded;
  vector<float> *pLS_pt_;
  TBranch *pLS_pt_branch;
  bool pLS_pt_isLoaded;
  vector<vector<int> > *sim_T4_types_;
  TBranch *sim_T4_types_branch;
  bool sim_T4_types_isLoaded;
  vector<int> *pT4_isDuplicate_;
  TBranch *pT4_isDuplicate_branch;
  bool pT4_isDuplicate_isLoaded;
  vector<float> *sim_phi_;
  TBranch *sim_phi_branch;
  bool sim_phi_isLoaded;
  vector<int> *t3_isFake_;
  TBranch *t3_isFake_branch;
  bool t3_isFake_isLoaded;
  vector<int> *md_occupancies_;
  TBranch *md_occupancies_branch;
  bool md_occupancies_isLoaded;
  vector<int> *t5_isFake_;
  TBranch *t5_isFake_branch;
  bool t5_isFake_isLoaded;
  vector<vector<int> > *sim_TC_types_;
  TBranch *sim_TC_types_branch;
  bool sim_TC_types_isLoaded;
  vector<int> *sg_occupancies_;
  TBranch *sg_occupancies_branch;
  bool sg_occupancies_isLoaded;
  vector<float> *sim_pca_dz_;
  TBranch *sim_pca_dz_branch;
  bool sim_pca_dz_isLoaded;
  vector<int> *t4_isDuplicate_;
  TBranch *t4_isDuplicate_branch;
  bool t4_isDuplicate_isLoaded;
  vector<float> *pT4_pt_;
  TBranch *pT4_pt_branch;
  bool pT4_pt_isLoaded;
  vector<vector<int> > *sim_pLS_types_;
  TBranch *sim_pLS_types_branch;
  bool sim_pLS_types_isLoaded;
  vector<int> *sim_pLS_matched_;
  TBranch *sim_pLS_matched_branch;
  bool sim_pLS_matched_isLoaded;
  vector<int> *pT4_isFake_;
  TBranch *pT4_isFake_branch;
  bool pT4_isFake_isLoaded;
  vector<float> *pT4_phi_;
  TBranch *pT4_phi_branch;
  bool pT4_phi_isLoaded;
  vector<float> *t4_phi_;
  TBranch *t4_phi_branch;
  bool t4_phi_isLoaded;
  vector<float> *t5_phi_;
  TBranch *t5_phi_branch;
  bool t5_phi_isLoaded;
  vector<int> *sim_T3_matched_;
  TBranch *sim_T3_matched_branch;
  bool sim_T3_matched_isLoaded;
  vector<float> *t5_pt_;
  TBranch *t5_pt_branch;
  bool t5_pt_isLoaded;
  vector<float> *t3_pt_;
  TBranch *t3_pt_branch;
  bool t3_pt_isLoaded;
  vector<int> *module_rings_;
  TBranch *module_rings_branch;
  bool module_rings_isLoaded;
  vector<float> *t4_eta_;
  TBranch *t4_eta_branch;
  bool t4_eta_isLoaded;
  vector<float> *sim_pt_;
  TBranch *sim_pt_branch;
  bool sim_pt_isLoaded;
  vector<int> *pLS_isFake_;
  TBranch *pLS_isFake_branch;
  bool pLS_isFake_isLoaded;
  vector<int> *sim_bunchCrossing_;
  TBranch *sim_bunchCrossing_branch;
  bool sim_bunchCrossing_isLoaded;
  vector<int> *tc_isFake_;
  TBranch *tc_isFake_branch;
  bool tc_isFake_isLoaded;
  vector<vector<int> > *sim_T3_types_;
  TBranch *sim_T3_types_branch;
  bool sim_T3_types_isLoaded;
  vector<float> *t5_eta_;
  TBranch *t5_eta_branch;
  bool t5_eta_isLoaded;
  vector<float> *t4_pt_;
  TBranch *t4_pt_branch;
  bool t4_pt_isLoaded;
  vector<float> *pLS_eta_;
  TBranch *pLS_eta_branch;
  bool pLS_eta_isLoaded;
  vector<int> *module_layers_;
  TBranch *module_layers_branch;
  bool module_layers_isLoaded;
  vector<float> *pT4_eta_;
  TBranch *pT4_eta_branch;
  bool pT4_eta_isLoaded;
  vector<float> *sim_pca_dxy_;
  TBranch *sim_pca_dxy_branch;
  bool sim_pca_dxy_isLoaded;
  vector<int> *sim_pdgId_;
  TBranch *sim_pdgId_branch;
  bool sim_pdgId_isLoaded;
public:
  void Init(TTree *tree);
  void GetEntry(unsigned int idx);
  void LoadAllBranches();
  const vector<float> &t3_eta();
  const vector<float> &t3_phi();
  const vector<int> &sim_parentVtxIdx();
  const vector<int> &t3_isDuplicate();
  const vector<float> &pLS_phi();
  const vector<int> &sim_event();
  const vector<int> &sim_pT4_matched();
  const vector<int> &sim_q();
  const vector<float> &sim_eta();
  const vector<float> &tc_eta();
  const vector<float> &tc_phi();
  const vector<int> &sim_T5_matched();
  const vector<vector<int> > &sim_T5_types();
  const vector<int> &t4_occupancies();
  const vector<int> &t3_occupancies();
  const vector<int> &t5_isDuplicate();
  const vector<vector<int> > &sim_pT4_types();
  const vector<vector<int> > &sim_tcIdx();
  const vector<int> &t4_isFake();
  const vector<int> &tc_occupancies();
  const vector<float> &simvtx_x();
  const vector<float> &simvtx_y();
  const vector<float> &simvtx_z();
  const vector<int> &sim_T4_matched();
  const vector<int> &sim_TC_matched();
  const vector<int> &pLS_isDuplicate();
  const vector<int> &module_subdets();
  const vector<int> &t5_occupancies();
  const vector<float> &tc_pt();
  const vector<int> &tc_isDuplicate();
  const vector<float> &pLS_pt();
  const vector<vector<int> > &sim_T4_types();
  const vector<int> &pT4_isDuplicate();
  const vector<float> &sim_phi();
  const vector<int> &t3_isFake();
  const vector<int> &md_occupancies();
  const vector<int> &t5_isFake();
  const vector<vector<int> > &sim_TC_types();
  const vector<int> &sg_occupancies();
  const vector<float> &sim_pca_dz();
  const vector<int> &t4_isDuplicate();
  const vector<float> &pT4_pt();
  const vector<vector<int> > &sim_pLS_types();
  const vector<int> &sim_pLS_matched();
  const vector<int> &pT4_isFake();
  const vector<float> &pT4_phi();
  const vector<float> &t4_phi();
  const vector<float> &t5_phi();
  const vector<int> &sim_T3_matched();
  const vector<float> &t5_pt();
  const vector<float> &t3_pt();
  const vector<int> &module_rings();
  const vector<float> &t4_eta();
  const vector<float> &sim_pt();
  const vector<int> &pLS_isFake();
  const vector<int> &sim_bunchCrossing();
  const vector<int> &tc_isFake();
  const vector<vector<int> > &sim_T3_types();
  const vector<float> &t5_eta();
  const vector<float> &t4_pt();
  const vector<float> &pLS_eta();
  const vector<int> &module_layers();
  const vector<float> &pT4_eta();
  const vector<float> &sim_pca_dxy();
  const vector<int> &sim_pdgId();
  static void progress( int nEventsTotal, int nEventsChain );
};

#ifndef __CINT__
extern SDL sdl;
#endif

namespace tas {

  const vector<float> &t3_eta();
  const vector<float> &t3_phi();
  const vector<int> &sim_parentVtxIdx();
  const vector<int> &t3_isDuplicate();
  const vector<float> &pLS_phi();
  const vector<int> &sim_event();
  const vector<int> &sim_pT4_matched();
  const vector<int> &sim_q();
  const vector<float> &sim_eta();
  const vector<float> &tc_eta();
  const vector<float> &tc_phi();
  const vector<int> &sim_T5_matched();
  const vector<vector<int> > &sim_T5_types();
  const vector<int> &t4_occupancies();
  const vector<int> &t3_occupancies();
  const vector<int> &t5_isDuplicate();
  const vector<vector<int> > &sim_pT4_types();
  const vector<vector<int> > &sim_tcIdx();
  const vector<int> &t4_isFake();
  const vector<int> &tc_occupancies();
  const vector<float> &simvtx_x();
  const vector<float> &simvtx_y();
  const vector<float> &simvtx_z();
  const vector<int> &sim_T4_matched();
  const vector<int> &sim_TC_matched();
  const vector<int> &pLS_isDuplicate();
  const vector<int> &module_subdets();
  const vector<int> &t5_occupancies();
  const vector<float> &tc_pt();
  const vector<int> &tc_isDuplicate();
  const vector<float> &pLS_pt();
  const vector<vector<int> > &sim_T4_types();
  const vector<int> &pT4_isDuplicate();
  const vector<float> &sim_phi();
  const vector<int> &t3_isFake();
  const vector<int> &md_occupancies();
  const vector<int> &t5_isFake();
  const vector<vector<int> > &sim_TC_types();
  const vector<int> &sg_occupancies();
  const vector<float> &sim_pca_dz();
  const vector<int> &t4_isDuplicate();
  const vector<float> &pT4_pt();
  const vector<vector<int> > &sim_pLS_types();
  const vector<int> &sim_pLS_matched();
  const vector<int> &pT4_isFake();
  const vector<float> &pT4_phi();
  const vector<float> &t4_phi();
  const vector<float> &t5_phi();
  const vector<int> &sim_T3_matched();
  const vector<float> &t5_pt();
  const vector<float> &t3_pt();
  const vector<int> &module_rings();
  const vector<float> &t4_eta();
  const vector<float> &sim_pt();
  const vector<int> &pLS_isFake();
  const vector<int> &sim_bunchCrossing();
  const vector<int> &tc_isFake();
  const vector<vector<int> > &sim_T3_types();
  const vector<float> &t5_eta();
  const vector<float> &t4_pt();
  const vector<float> &pLS_eta();
  const vector<int> &module_layers();
  const vector<float> &pT4_eta();
  const vector<float> &sim_pca_dxy();
  const vector<int> &sim_pdgId();
}
#endif
