using Revise
using VBSVVHCore
using PlotlyJSWrapper
using LVCyl
using FHist
using Arrow
using ProgressMeter

hnames = ["h_mjj",
          "h_detajj",
          "h_pthbbjet",
          "h_ptfatjet1",
          "h_ptfatjet2",
          "h_mhbbjet",
          "h_mfatjet1",
          "h_mfatjet2",
          "h_nfatjet",
          "h_hscore",
          "h_wscore1",
          "h_wscore2",
          "h_mvvv",
         ]

function gethistograms(arrowfilepath)
    t = Arrow.Table(arrowfilepath)
    samplename = Arrow.getmetadata(t)["samplename"]
    isqcd = occursin("QCD_HT700to1000", samplename)
    isttbar = occursin("TTToHadronic", samplename)
    rewgt_idx = isqcd || isttbar ? 0 : 25
    xsec = isqcd ? 6344 : (isttbar ? 377.96 : parse(Float64,Arrow.getmetadata(t)["xsec"]))
    ntotalevents = isqcd ? 42953639 : (isttbar ? 38520000 : parse(Float64,Arrow.getmetadata(t)["ntotalevents"]))
    h_mjj = Hist1D(Float32; bins=0:50:4500);
    h_detajj = Hist1D(Float32; bins=0:0.5:10);
    h_pthbbjet = Hist1D(Float32; bins=0:50:2000);
    h_ptfatjet1 = Hist1D(Float32; bins=0:50:2000);
    h_ptfatjet2 = Hist1D(Float32; bins=0:50:2000);
    h_mhbbjet = Hist1D(Float32; bins=0:5:200);
    h_mfatjet1 = Hist1D(Float32; bins=0:5:200);
    h_mfatjet2 = Hist1D(Float32; bins=0:5:200);
    h_nfatjet = Hist1D(Float32; bins=0:1:6);
    h_hscore = Hist1D(Float32; bins=0:0.02:1);
    h_wscore1 = Hist1D(Float32; bins=0:0.02:1);
    h_wscore2 = Hist1D(Float32; bins=0:0.02:1);
    h_mvvv = Hist1D(Float32; bins=0:50:4500);
    @showprogress for evt in t.event
        smrewgt = if rewgt_idx == 0
            1
        else
            evt.rewgts[rewgt_idx]
        end
        evt.hbbjet.hscore < 0.9 && continue
        evt.fatjet1.wscore < 0.5 && continue
        evt.fatjet2.wscore < 0.5 && continue
        evt.hbbjet.p4.pt < 400 && continue
        evt.hbbjet.p4.mass > 150 && continue
        evt.fatjet1.p4.mass > 100 && continue
        evt.fatjet2.p4.mass > 100 && continue
        abs(evt.vbsj1.p4.eta - evt.vbsj2.p4.eta) < 5 && continue
        fast_mass(evt.vbsj1.p4, evt.vbsj2.p4) < 1500 && continue
        evtwgt = xsec * 1000 / ntotalevents * 137 * smrewgt
        push!(h_mjj, fast_mass(evt.vbsj1.p4, evt.vbsj2.p4), evtwgt)
        push!(h_detajj, abs(evt.vbsj1.p4.eta - evt.vbsj2.p4.eta), evtwgt)
        push!(h_pthbbjet, evt.hbbjet.p4.pt, evtwgt)
        push!(h_ptfatjet1, evt.fatjet1.p4.pt, evtwgt)
        push!(h_ptfatjet2, evt.fatjet2.p4.pt, evtwgt)
        push!(h_mhbbjet, evt.hbbjet.p4.mass, evtwgt)
        push!(h_mfatjet1, evt.fatjet1.p4.mass, evtwgt)
        push!(h_mfatjet2, evt.fatjet2.p4.mass, evtwgt)
        push!(h_nfatjet, evt.nfatjet, evtwgt)
        push!(h_hscore, evt.hbbjet.hscore, evtwgt)
        push!(h_wscore1, evt.fatjet1.wscore, evtwgt)
        push!(h_wscore2, evt.fatjet2.wscore, evtwgt)
        push!(h_mvvv, (evt.hbbjet.p4+evt.fatjet1.p4+evt.fatjet2.p4).mass, evtwgt)
    end
    hists = Dict(
                 "h_mjj" => h_mjj,
                 "h_detajj" => h_detajj,
                 "h_pthbbjet" => h_pthbbjet,
                 "h_ptfatjet1" =>h_ptfatjet1,
                 "h_ptfatjet2" =>h_ptfatjet2,
                 "h_mhbbjet" => h_mhbbjet,
                 "h_mfatjet1" => h_mfatjet1,
                 "h_mfatjet2" => h_mfatjet2,
                 "h_nfatjet" => h_nfatjet,
                 "h_hscore" => h_hscore,
                 "h_wscore1" => h_wscore1,
                 "h_wscore2" => h_wscore2,
                 "h_mvvv" => h_mvvv,
                )
end

sig1_hists = gethistograms("VBSssWWH.arrow")
sig2_hists = gethistograms("VBSosWWH.arrow")
sig3_hists = gethistograms("VBSWZH.arrow")
sig4_hists = gethistograms("VBSZZH.arrow")
qcd_hists = gethistograms("QCD_HT700to1000.arrow")
ttb_hists = gethistograms("TTToHadronic.arrow")

@showprogress for i in 1:length(hnames)
    hname = hnames[i]
    sigs = [sig1_hists[hname]+sig2_hists[hname]+sig3_hists[hname]+sig4_hists[hname]]
    bkgs = [qcd_hists[hname], ttb_hists[hname]]
    bkglabel = ["QCD_HT700to1000", "TTToHadronic"]
    plot_stack(backgrounds=bkgs,
               signals=sigs,
               outputname="plots/$hname.{html,png,pdf}",
               xaxistitle="$hname",
               backgroundlabels=bkglabel,
               signallabels=["VBSVVH"],
               showfomfromleft=true,
               # showratio=true,
              );
end




