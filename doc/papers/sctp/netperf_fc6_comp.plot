set terminal fig color small portrait fontsize 9 inches size 4.5 2.4
set output 'netperf_fc6_comp.fig'
set nologscale
set logscale x
set ylabel 'Percentage Improvement (over Sockets)'
set y2label '|'
set xlabel 'Message Size (Bytes)'
set grid x y
set key top right Left reverse
set xtics nomirror (1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192)
set ytics nomirror
set border 3 lw 1
plot \
     'netperf_fc6.dat' using 1:(($4/$6)*100) smooth unique title "SCTP Streams Tx" with linespoints lt 6 lw 0.5,\
     'netperf_fc6.dat' using 1:(($5/$7)*100) smooth unique title "SCTP Streams Rx" with linespoints lt 5 lw 0.5,\
     'netperf_fc6.dat' using 1:(($6/$6)*100) smooth unique title "TCP Sockets Tx (N)" with linespoints lt 4 lw 0.5,\
     'netperf_fc6.dat' using 1:(($7/$7)*100) smooth unique title "TCP Sockets Rx (N)" with linespoints lt 3 lw 0.5,\
     'netperf_fc6.dat' using 1:(($8/$7)*100) smooth unique title "TCP Sockets Tx (A)" with linespoints lt 11 lw 0.5,\
     'netperf_fc6.dat' using 1:(($9/$7)*100) smooth unique title "TCP Sockets Rx (A)" with linespoints lt 10 lw 0.5,\
     'netperf_fc6.dat' using 1:(($2/$6)*100) smooth unique title "TCP XTIoS Tx"   with linespoints lt 1 lw 0.5,\
     'netperf_fc6.dat' using 1:(($3/$7)*100) smooth unique title "TCP XTIoS Rx"   with linespoints lt 2 lw 0.5

