set -e
set -x
sort -nk1 -t, unravel.csv > unravel-sorted.csv
gnuplot -p unravel.gnuplot
