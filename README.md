# VBSVVHCore.jl

## Quick start

    ] add https://github.com/sgnoohc/VBSVVHCore.jl

    using VBSVVHCore

    # To create arrow outputs

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


    using Arrow

    t = Arrow.Table("VBSssWWH.arrow")

    hbbjet_pts = []
    for evt in t.event
        push!(hbbjet_pts, evt.hbbjet.p4.pt)
    end
