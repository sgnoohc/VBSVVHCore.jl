using Revise
using VBSVVHCore
using PlotlyJSWrapper
using LVCyl
using FHist
using Arrow
using ProgressMeter

path = "/home/users/phchang/public_html/analysis/hwh/signal_generations/ultralegacy/merge/VBSssWWHAllHad";
processsample(dirpath=path,
              globpattern="merged.root",
              issig=true,
              xsec=0.00391,
              ntotalevents=47750,
              samplename="VBSssWWH",
              outputpath="VBSssWWH.arrow",
             )
path = "/home/users/phchang/public_html/analysis/hwh/signal_generations/ultralegacy/merge/VBSosWWHAllHad";
processsample(dirpath=path,
              globpattern="merged.root",
              issig=true,
              xsec=0.00595,
              ntotalevents=49250,
              samplename="VBSosWWH",
              outputpath="VBSosWWH.arrow",
             )
path = "/home/users/phchang/public_html/analysis/hwh/signal_generations/ultralegacy/merge/VBSWZHAllHad";
processsample(dirpath=path,
              globpattern="merged.root",
              issig=true,
              xsec=0.00411,
              ntotalevents=48500,
              samplename="VBSWZH",
              outputpath="VBSWZH.arrow",
             )
path = "/home/users/phchang/public_html/analysis/hwh/signal_generations/ultralegacy/merge/VBSZZHAllHad";
processsample(dirpath=path,
              globpattern="merged.root",
              issig=true,
              xsec=0.00358,
              ntotalevents=48000,
              samplename="VBSZZH",
              outputpath="VBSZZH.arrow",
             )

path = "/nfs-7/userdata/phchang/nanoaod/mc/RunIISummer19UL18NanoAODv2/QCD_HT700to1000_TuneCP5_PSWeights_13TeV-madgraphMLM-pythia8/NANOAODSIM/106X_upgrade2018_realistic_v15_L1v1-v1/280000/"
processsample(dirpath=path,
              globpattern="*.root",
              issig=false,
              xsec=1,
              ntotalevents=66704+1338868+1147959+1341443+720740,
              samplename="QCD_HT700to1000",
              outputpath="QCD_HT700to1000.arrow",
             )

function gethistograms(arrowfilepath)
    t = Arrow.Table(arrowfilepath)
    samplename = Arrow.getmetadata(t)["samplename"]
    isqcd = occursin("QCD_HT700to1000", samplename)
    rewgt_idx = isqcd ? 0 : 25
    xsec = isqcd ? 6344 : parse(Float64,Arrow.getmetadata(t)["xsec"])
    ntotalevents = isqcd ? 42953639 : parse(Float64,Arrow.getmetadata(t)["ntotalevents"])
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
    @showprogress for evt in t.event
        smrewgt = if rewgt_idx == 0
            1
        else
            evt.rewgts[rewgt_idx]
        end
        evt.hbbjet.hscore < 0.9 && continue
        abs(evt.vbsj1.p4.eta - evt.vbsj2.p4.eta) < 5 && continue
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
                )
end

sig_hists = gethistograms("VBSssWWH.arrow")
qcd_hists = gethistograms("QCD_HT700to1000.arrow")

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
         ]

for i in 1:length(hnames)
    hname = hnames[i]
    plot_stack(backgrounds=[qcd_hists[hname]],
               signals=[sig_hists[hname]],
               outputname="plots/$hname.{html,png,pdf}",
               xaxistitle="$hname",
               backgroundlabels=["QCD_HT700to1000"],
               ylog=true,
              );
end
