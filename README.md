# VBSVVHCore.jl

## Installation

Start julia prompt

    julia

Install packages

    # (press ] key)
    dev git@github.com:sgnoohc/VBSVVHCore.jl.git # To develop
    # For additional packages that are useful
    add Revise
    add LVCyl
    add FHist
    add Arrow
    add ProgressMeter
    add https://github.com/sgnoohc/PlotlyJSWrapper.jl
    # (press backspace key)

The analysis script is [`analysis.jl`](https://github.com/sgnoohc/VBSVVHCore.jl/blob/main/scripts/analysis.jl).  
One can copy paste it to the notebook, or use [`vim-slime`](https://github.com/jpalardy/vim-slime) + [`screen`](https://www.gnu.org/software/screen/) or [`tmux`](https://github.com/tmux/tmux/wiki)

To run multithread start your kernel with

    julia --threads 20

For notebooks, set `julia_num_threads` environment variable.
