module VBSVVHCore

using Arrow
using Hungarian
using LVCyl
using UnROOT
using ProgressMeter
using Glob
using Tables

export VBSVVHEvent
export GenBoson, GenJet
export FatJet, Jet, Lepton, MET
export LV

export writearrow, readarrow

export processsample

# ________________________________________________________________________________________________________________
"""
   LV = LorentzVectorCyl{Float32} 
"""
LV = LorentzVectorCyl{Float32}


# ________________________________________________________________________________________________________________
"""
    GenBoson

Struct containing information about the gen boson
"""
mutable struct GenBoson
    p4::LV
    pdgId::Int32
    f1_p4::LV # leading fermion decay
    f1_pdgId::Int32 # leading fermion pdgid
    f2_p4::LV # subleading fermion decay
    f2_pdgId::Int32 # leading fermion pdgid
end
GenBoson() = GenBoson(LV(0,0,0,0), -999, LV(0,0,0,0), -999, LV(0,0,0,0), -999)


# ________________________________________________________________________________________________________________
"""
    GenJet

Struct containing information about the gen jet
"""
mutable struct GenJet
    p4::LV
    pdgId::Int32
end
GenJet() = GenJet(LV(0,0,0,0), -999)


# ________________________________________________________________________________________________________________
"""
    FatJet

Struct containing information about the reco fat jet
"""
mutable struct FatJet
    p4::LV
    hscore::Float32 # DeepTag HbbvsQCD
    wscore::Float32 # DeepTag WvsQCD
    zscore::Float32 # DeepTag ZvsQCD
    matched_genboson::GenBoson # matched GenBoson
end
FatJet() = FatJet(LV(0,0,0,0), -999, -999, -999, GenBoson())


# ________________________________________________________________________________________________________________
"""
    Jet

Struct containing information about the reco jet
"""
mutable struct Jet
    p4::LV
    bscore::Float32 # DeepJet score
    matched_genjet::GenJet # matched GenJet
end
Jet() = Jet(LV(0,0,0,0), -999, GenJet())


# ________________________________________________________________________________________________________________
"""
    Lepton

Struct containing information about the reco lepton
"""
mutable struct Lepton
    p4::LV
end
Lepton() = Lepton(LV(0,0,0,0))


# ________________________________________________________________________________________________________________
"""
    MET

Struct containing information about the reco lepton
"""
mutable struct MET
    p4::LV
end
MET() = MET(LV(0,0,0,0))

# ________________________________________________________________________________________________________________
"""
    VBSVVHEvent

Struct containing about the event information
"""
mutable struct VBSVVHEvent
    vbsj1::Jet
    vbsj2::Jet
    hbbjet::FatJet
    nlepton::Int32
    lepton1::Lepton
    lepton2::Lepton
    lepton3::Lepton
    lepton4::Lepton
    nfatjet::Int32
    fatjet1::FatJet
    fatjet2::FatJet
    met::MET
    wgtsign::Int32
    rewgts::Vector{Float32}
end
VBSVVHEvent() = VBSVVHEvent(Jet(),
                            Jet(),
                            FatJet(),
                            0,
                            Lepton(),
                            Lepton(),
                            Lepton(),
                            Lepton(),
                            0,
                            FatJet(),
                            FatJet(),
                            MET(),
                            1,
                            Float32[]
                           )

ArrowTypes.arrowname(::Type{VBSVVHEvent}) = :VBSVVHEvent
ArrowTypes.arrowname(::Type{Lepton}) = :Lepton
ArrowTypes.arrowname(::Type{FatJet}) = :FatJet
ArrowTypes.arrowname(::Type{Jet}) = :Jet
ArrowTypes.arrowname(::Type{MET}) = :MET
ArrowTypes.arrowname(::Type{GenBoson}) = :GenBoson
ArrowTypes.arrowname(::Type{GenJet}) = :GenJet
ArrowTypes.arrowname(::Type{LV}) = :LV

ArrowTypes.JuliaType(::Val{:VBSVVHEvent}) = VBSVVHEvent
ArrowTypes.JuliaType(::Val{:Lepton}) = Lepton
ArrowTypes.JuliaType(::Val{:FatJet}) = FatJet
ArrowTypes.JuliaType(::Val{:Jet}) = Jet
ArrowTypes.JuliaType(::Val{:MET}) = MET
ArrowTypes.JuliaType(::Val{:GenBoson}) = GenBoson
ArrowTypes.JuliaType(::Val{:GenJet}) = GenJet
ArrowTypes.JuliaType(::Val{:LV}) = LV


"""
    match(cand::Vector{LV}, ref::Vector{LV})

returns the index of cand with total minimal deltar matched in order of ref
"""
@inline function match(cand::Vector{LV}, ref::Vector{LV})
    cost = deltar.(ref, permutedims(cand))
    assignment, cost = hungarian(cost)
    return assignment
end


# ________________________________________________________________________________________________________________
"""
    writearrow(fname::String, events::Vector{VBSVVHEvent})

Write the list of VBSVVHEvents to arrow
"""
function writearrow(fname::String, events::Vector{VBSVVHEvent}; xsec, ntotalevents, samplename)
    @info "[VBSVVHCore] Writing $fname..."
    # First create the `NamedTuple` of column name = event, and vector of events
    nt = (event=events,)
    # N.B. there is some gymnastics of calling `Tables.columns` involved here.
    # https://github.com/JuliaData/Arrow.jl/issues/211
    # Create a Arrow.Table
    t = Tables.columns(Arrow.Table(Arrow.tobuffer(nt)))
    # Add metadata
    Arrow.setmetadata!(t,
                       Dict(
                            "xsec" => string(xsec),
                            "ntotalevents" => string(ntotalevents),
                            "samplename" => samplename
                           )
                      )
    # Write to file
    @time Arrow.write(fname, t)
    @info "[VBSVVHCore] Wrote to $fname"
end


# ________________________________________________________________________________________________________________
"""
    readarrow(fname::String)

Read the list of VBSVVHEvents from arrow. Returns Vector{VBSVVHEvent}
"""
function readarrow(fname::String)
    @info "[VBSVVHCore] Opening $fname..."
    @time a = Arrow.Table(fname)
    @info "[VBSVVHCore] Opened $fname"
    return a
end

# ________________________________________________________________________________________________________________
"""
    getfile(fpath::String)

Opens up a NanoAOD ROOT file and return `ROOTFile`
"""
function getfile(fpath::String)
    f = ROOTFile(fpath)
    return f
end

# ________________________________________________________________________________________________________________
"""
    gettree(f::ROOTFile)

Returns the TTree from the NanoAOD ROOT file with branches to be read
"""
function gettree(f::ROOTFile)
    branches = [
        r"^FatJet_(pt|eta|phi|mass|msoftdrop|deepTagMD_WvsQCD|deepTagMD_ZvsQCD|deepTagMD_HbbvsQCD)$",
        r"^Jet_(pt|eta|phi|mass|btagDeepFlavB)$",
        r"^LHEPart_(pt|eta|phi|mass|pdgId)$",
        r"^LHEReweightingWeight$",
        ];
    t = LazyTree(f, "Events", branches)
    return t
end

# ________________________________________________________________________________________________________________
"""
    processsample(;dirpath::String, globpattern::String, issig::Bool, xsec::Real, ntotalevents::Real, samplename::String, output::String)

Process the NanoAOD ROOT file in `dirpath` with file names matched via `globpattern` and writes an output `.arrow` file.
"""
function processsample(;dirpath::String, globpattern::String, issig::Bool, xsec::Real, ntotalevents::Real, samplename::String, outputpath::String)

# Signals
files = glob(globpattern, dirpath);

@info "[VBSVVHCore] Processing NanoAOD dirpath=$dirpath"

# Prepare multi-thread output
events = Vector{Vector{VBSVVHEvent}}()

# Prepare a list of list of events to be threadsafe
for i in 1:Threads.nthreads()
    push!(events, VBSVVHEvent[])
end

# Multi-thread the output
Threads.@threads for file in files
    append!(events[Threads.threadid()], processfile(file, issig=issig))
end

# Splat it
events = vcat(events...)

@time writearrow(outputpath, events; xsec=xsec, ntotalevents=ntotalevents, samplename=samplename)

end

# ________________________________________________________________________________________________________________
"""
    processfile(file::String, issig::Bool)

Process the NanoAOD ROOT file in path `file` and return Vector{VBSVVHEvent}
"""
function processfile(file::String; issig::Bool)
    @info "[VBSVVHCore] Processing file=$file issig=$issig ..."
    f = getfile(file)
    t = gettree(f)
    a = processtree(t, issig)
    Base.close(f.fobj)
    return a
end

# ________________________________________________________________________________________________________________
"""
    processtree(

Process the TTree and return Vector{VBSVVHEvent}
"""
function processtree(t, issig)
    @info string("[VBSVVHCore] Total N Events = ", length(t))
    vbsvvhevents = VBSVVHEvent[]
    @showprogress for evt in t

        # Select generator level objects
        genj1, genj2, genw1, genw2, genh = select_gens(evt, issig)

        # Select fatjets
        selected_fatjets = select_fatjets(evt)

        # If n_fatjets < 3 skip
        length(selected_fatjets) < 3 && continue

        # Tag fatjets as boosted bosons
        hbbjet, fatjet1, fatjet2 = tag_fatjets(selected_fatjets)

        # Match the tagged boosted bosons against the genbosons
        match_fatjets_to_genbosons(genh, genw1, genw2, hbbjet, fatjet1, fatjet2)

        # Select jets not overlapping with the tagged boosted bosons
        selected_jets = select_jets(evt, FatJet[hbbjet, fatjet1, fatjet2])

        # If n_jets < 2 skip
        length(selected_jets) < 2 && continue

        # Tag vbsjets
        vbsj1, vbsj2 = tag_vbsjets(selected_jets)

        # Match the tagged vbsjets against the genvbsjets
        match_jets_to_genjets(genj1, genj2, vbsj1, vbsj2)

        push!(vbsvvhevents, VBSVVHEvent(vbsj1,
                                        vbsj2,
                                        hbbjet,
                                        -999,
                                        Lepton(),
                                        Lepton(),
                                        Lepton(),
                                        Lepton(),
                                        length(selected_fatjets),
                                        fatjet1,
                                        fatjet2,
                                        MET(),
                                        1,
                                        evt.LHEReweightingWeight
                                       )
             )

    end
    return vbsvvhevents
end




# ________________________________________________________________________________________________________________
function select_gens(evt, issig)
    genj1 = GenJet()
    genj2 = GenJet()
    genw1 = GenBoson()
    genw2 = GenBoson()
    genh = GenBoson()
    if issig
        lhe_pt = evt.LHEPart_pt
        lhe_eta = evt.LHEPart_eta
        lhe_phi = evt.LHEPart_phi
        lhe_mass = evt.LHEPart_mass
        lhe_pdgId = evt.LHEPart_pdgId
        nlhe = length(lhe_pt)
        # VBF Jets
        idx = 3; jA = LV(lhe_pt[idx], lhe_eta[idx], lhe_phi[idx], lhe_mass[idx]); jAid = lhe_pdgId[idx]
        idx = 4; jB = LV(lhe_pt[idx], lhe_eta[idx], lhe_phi[idx], lhe_mass[idx]); jBid = lhe_pdgId[idx]
        # V->qq
        idx = 5; WAqA = LV(lhe_pt[idx], lhe_eta[idx], lhe_phi[idx], lhe_mass[idx]); WAqAid = lhe_pdgId[idx]
        idx = 6; WAqB = LV(lhe_pt[idx], lhe_eta[idx], lhe_phi[idx], lhe_mass[idx]); WAqBid = lhe_pdgId[idx]
        # V->qq
        idx = 7; WBqA = LV(lhe_pt[idx], lhe_eta[idx], lhe_phi[idx], lhe_mass[idx]); WBqAid = lhe_pdgId[idx]
        idx = 8; WBqB = LV(lhe_pt[idx], lhe_eta[idx], lhe_phi[idx], lhe_mass[idx]); WBqBid = lhe_pdgId[idx]
        # H->bb
        idx = 9; HbA = LV(lhe_pt[idx], lhe_eta[idx], lhe_phi[idx], lhe_mass[idx]); HbAid = lhe_pdgId[idx]
        idx = 10; HbB = LV(lhe_pt[idx], lhe_eta[idx], lhe_phi[idx], lhe_mass[idx]); HbBid = lhe_pdgId[idx]
        genj1.p4 = jA.pt > jB.pt ? jA : jB
        genj2.p4 = jA.pt > jB.pt ? jB : jA
        genj1.pdgId = jA.pt > jB.pt ? jAid : jBid
        genj2.pdgId = jA.pt > jB.pt ? jBid : jAid
        WA = WAqA + WAqB
        WB = WBqA + WBqB
        genw1.p4 = WA.pt > WB.pt ? WA : WB
        genw2.p4 = WA.pt > WB.pt ? WB : WA
        genw1.f1_p4 = WA.pt > WB.pt ? (WAqA.pt > WAqB.pt ? WAqA : WAqB) : (WBqA.pt > WBqB.pt ? WBqA : WBqB)
        genw1.f2_p4 = WA.pt > WB.pt ? (WAqA.pt > WAqB.pt ? WAqB : WAqA) : (WBqA.pt > WBqB.pt ? WBqB : WBqA)
        genw2.f1_p4 = WA.pt > WB.pt ? (WBqA.pt > WBqB.pt ? WBqA : WBqB) : (WAqA.pt > WAqB.pt ? WAqA : WAqB)
        genw2.f2_p4 = WA.pt > WB.pt ? (WBqA.pt > WBqB.pt ? WBqB : WBqA) : (WAqA.pt > WAqB.pt ? WAqB : WAqA)
        genw1.f1_pdgId = WA.pt > WB.pt ? (WAqA.pt > WAqB.pt ? WAqAid : WAqBid) : (WBqA.pt > WBqB.pt ? WBqAid : WBqBid)
        genw1.f2_pdgId = WA.pt > WB.pt ? (WAqA.pt > WAqB.pt ? WAqBid : WAqAid) : (WBqA.pt > WBqB.pt ? WBqBid : WBqAid)
        genw2.f1_pdgId = WA.pt > WB.pt ? (WBqA.pt > WBqB.pt ? WBqAid : WBqBid) : (WAqA.pt > WAqB.pt ? WAqAid : WAqBid)
        genw2.f2_pdgId = WA.pt > WB.pt ? (WBqA.pt > WBqB.pt ? WBqBid : WBqAid) : (WAqA.pt > WAqB.pt ? WAqBid : WAqAid)
        genh.p4 = HbA + HbB
        genh.f1_p4 = HbA.pt > HbB.pt ? HbA : HbB
        genh.f2_p4 = HbA.pt > HbB.pt ? HbB : HbA
        genh.f1_pdgId = HbA.pt > HbB.pt ? HbAid : HbBid
        genh.f2_pdgId = HbA.pt > HbB.pt ? HbBid : HbAid
        # Assigning bosons' pdgIds based on the daughters
        genh.pdgId = 25 # This is obvious
        genw1.pdgId = genw1.f1_pdgId + genw1.f2_pdgId > 0 ? 24 : -24
        genw2.pdgId = genw1.f1_pdgId + genw1.f2_pdgId > 0 ? 24 : -24
    end
    return genj1, genj2, genw1, genw2, genh
end


# ________________________________________________________________________________________________________________
function select_fatjets(evt)
    # Declare
    selected_fatjets = Vector{FatJet}()
    # Get the FatJet data
    fj_pt = evt.FatJet_pt
    fj_eta = evt.FatJet_eta
    fj_phi = evt.FatJet_phi
    fj_msoftdrop = evt.FatJet_msoftdrop
    fj_hscore = evt.FatJet_deepTagMD_HbbvsQCD
    fj_wscore = evt.FatJet_deepTagMD_WvsQCD
    fj_zscore = evt.FatJet_deepTagMD_ZvsQCD
    nfj = length(fj_pt)
    # Loop over the fat jets
    for i in 1:nfj
        # Check if the fatjet msoftdrop mass is largest than 40
        fj_msoftdrop[i] < 40 && continue
        anafatjet = FatJet()
        anafatjet.p4 = LV(fj_pt[i], fj_eta[i], fj_phi[i], fj_msoftdrop[i])
        anafatjet.hscore = fj_hscore[i]
        anafatjet.wscore = fj_wscore[i]
        anafatjet.zscore = fj_zscore[i]
        anafatjet.matched_genboson = GenBoson()
        push!(selected_fatjets, anafatjet)
    end
    return selected_fatjets
end


# ________________________________________________________________________________________________________________
function tag_fatjets(selected_fatjets)
    # Select the highest hscore as the higgs jet
    sorted_fatjet = sort(selected_fatjets, by=x->x.hscore, rev=true)
    anah = sorted_fatjet[1]
    popfirst!(sorted_fatjet)
    wsorted_fatjet = sort(sorted_fatjet, by=x->x.wscore, rev=true)
    anaw1 = wsorted_fatjet[1]
    anaw2 = wsorted_fatjet[2]
    return anah, anaw1, anaw2
end


# ________________________________________________________________________________________________________________
function match_fatjets_to_genbosons(genh, genw1, genw2, anah, anaw1, anaw2)
    gens = GenBoson[genh, genw1, genw2]
    genp4s = LV[genh.p4, genw1.p4, genw2.p4]
    anap4s = LV[anah.p4, anaw1.p4, anaw2.p4]
    idxs = match(genp4s, anap4s)
    anah.matched_genboson = gens[idxs[1]]
    anaw1.matched_genboson = gens[idxs[2]]
    anaw2.matched_genboson = gens[idxs[3]]
end


# ________________________________________________________________________________________________________________
function select_jets(evt, selected_fatjets)
    # Declare
    selected_jets = Vector{Jet}()
    # Get the relevant jet data
    j_pt = evt.Jet_pt
    j_eta = evt.Jet_eta
    j_phi = evt.Jet_phi
    j_mass = evt.Jet_mass
    j_bscore = evt.Jet_btagDeepFlavB
    nj = length(j_pt)
    # Now loop over to select jets
    for i in 1:nj
        j_pt[i] < 30 && continue
        jet = Jet()
        jet.p4 = LV(j_pt[i], j_eta[i], j_phi[i], j_mass[i])
        jet.bscore = j_bscore[i]
        jet.matched_genjet = GenJet()
        # Do an overlap cleaning against selected fat_jets
        isoverlap = false
        for fj in selected_fatjets
            if deltar(jet.p4, fj.p4) < 0.8
                isoverlap = true
                break
            end
        end
        # If overlap then skip
        isoverlap && continue
        push!(selected_jets, jet)
    end
    return selected_jets
end


# ________________________________________________________________________________________________________________
function tag_vbsjets(selected_jets)
    if length(selected_jets) == 2
        return selected_jets[1], selected_jets[2]
    else
        # If not two jets we sort the jets in each hemisphere and pick the highest pt jets in each hemi
        # First organize the jets into two buckets
        jets_positive_eta = Jet[]
        jets_negative_eta = Jet[]
        for j in selected_jets
            if j.p4.eta > 0
                push!(jets_positive_eta, j)
            else
                push!(jets_negative_eta, j)
            end
        end
        # If there are not jets in either side of the hemisphere then we choose the two leading
        if length(jets_positive_eta) == 0 || length(jets_negative_eta) == 0
            return selected_jets[1], selected_jets[2]
        end
        jet_pos = Jet()
        for jp in jets_positive_eta
            if energy(jet_pos.p4) < energy(jp.p4)
                jet_pos = jp
            end
        end
        jet_neg = Jet()
        for jn in jets_negative_eta
            if energy(jet_neg.p4) < energy(jn.p4)
                jet_neg = jn
            end
        end
        jet_1 = jet_pos.p4.pt > jet_neg.p4.pt ? jet_pos : jet_neg
        jet_2 = jet_pos.p4.pt > jet_neg.p4.pt ? jet_neg : jet_pos
        return jet_1, jet_2
    end
end


# ________________________________________________________________________________________________________________
function match_jets_to_genjets(genj1, genj2, anaj1, anaj2)
    gens = GenJet[genj1, genj2]
    genp4s = LV[genj1.p4, genj2.p4]
    anap4s = LV[anaj1.p4, anaj2.p4]
    idxs = match(genp4s, anap4s)
    anaj1.matched_genjet = gens[idxs[1]]
    anaj2.matched_genjet = gens[idxs[2]]
end

end # module
