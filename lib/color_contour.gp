# Gnuplot control script for contour maps

# Setup
reset
set terminal pngcairo notransparent size 1000, 1000 font "Helvetica, 10"
set output outfile
set multiplot
set title plottitle font "Helvetica, 20"
set palette maxcolors 100
set palette defined ( 0 '#a100c7', 1 '#6e00dc', 2 '#1f3dfa', 3 '#00c7c7', 4 '#00d18c', 5 '#a1e633', 6 '#e6dc33', 7 '#f08229', 8 '#f00000', 9 '#dc0063')

# Map
set view map
set xrange [-98:-82]
set yrange [38:50]
set tmargin at screen 0.95
set bmargin at screen 0.09
set lmargin at screen 0.05
set rmargin at screen 0.95
unset key
unset xtics
unset ytics
unset border

# Countours
set contour base
set pm3d explicit at b
set pm3d interpolate 16, 16
set cntrparam bspline
set cntrparam level incremental min_val, max_val / 10.0, max_val
set cntrlabel start 1 interval 1
set cntrlabel format "%0.1f"
set cntrlabel font "Helvetica, 10"
set colorbox horizontal user origin 0.1, 0.035 size 0.8, 0.02
set cbrange [min_val:max_val]
set cbtics min_val, (max_val - min_val) / 10.0, max_val
set cbtics out nomirror scale 0.5

# Plot the surface
splot infile u 2:1:3 with pm3d

# Plot contour lines
set for [i=1:12] linetype i dt 4 lc rgb "#000000"
set style increment user
splot '' u 2:1:3 with lines lw 0.5 nosurface
