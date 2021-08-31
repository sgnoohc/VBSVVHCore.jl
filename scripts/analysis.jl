using Revise
using VBSVVHCore

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

path = "/home/users/phchang/public_html/analysis/hwh/signal_generations/ultralegacy/merge/mc/RunIISummer20UL18NanoAODv2/TTToHadronic_TuneCP5_13TeV-powheg-pythia8/NANOAODSIM/106X_upgrade2018_realistic_v15_L1v1-v1/10000/"
processsample(dirpath=path,
              globpattern="*.root",
              issig=false,
              xsec=1,
              ntotalevents=1,
              samplename="TTToHadronic",
              outputpath="TTToHadronic.arrow",
             )

