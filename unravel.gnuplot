set datafile separator ','
set output 'unravel.pdf'
set terminal pdf

set key autotitle columnhead

f(x) = a + b*x;
g(x) = c + d*x;



fit f(x) 'unravel.csv' using 1:3 via a, b
fit g(x) 'unravel.csv' using 1:4 via c, d

set ylabel "Time (ms)" # label for the Y axis
set xlabel 'Size (chars)' # label for the X axis

 
plot 'unravel.csv' using 1:3 with points, '' using 1:4 with points, f(x), g(x)

