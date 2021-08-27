reset
set cbrange [0:max_v]
set pm3d explicit at b
set pm3d interpolate 16,16
set palette maxcolors 100

set palette defined ( 0 '#a100c7', 1 '#6e00dc', 2 '#1f3dfa', 3 '#00c7c7', 4 '#00d18c', 5 '#a1e633', 6 '#e6dc33', 7 '#f08229', 8 '#f00000', 9 '#dc0063')
set view map 

set contour base
set cntrparam bspline
set cntrparam level incremental 0, max_v/10.0, max_v

set cbtics 0, max_v/10.0, max_v
set cbtics out scale 0.01
set cntrlabel start 50 interval -1
set cntrlabel format "%0.1f"
set cntrlabel font "Helvetica,10"

set linetype 1 dt 5 lw 1
set for [i=1:50] style line i dt i lt 1 lc rgb "#000000" 
set style increment userstyles 

unset key
unset xtics
set xrange [-98:-82]
set yrange [38:50]
unset ytics
unset border
set tmargin at screen 0.95
set bmargin at screen 0.09
set lmargin at screen 0.05
set rmargin at screen 0.95
set output outfile

set colorbox horizontal user origin 0.1, 0.035 size 0.8, 0.02
set terminal pngcairo notransparent size 1000, 1000 font "Helvetica,10"
set title plottitle font "Helvetica, 20"

set multiplot
splot infile u 2:1:3 with pm3d nocontour
splot '' u 2:1:3 with lines dt 2 nosurface
