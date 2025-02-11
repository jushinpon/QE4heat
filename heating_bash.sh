#!/bin/bash
if [ -f /opt/anaconda3/bin/activate ]; then
    
    source /opt/anaconda3/bin/activate deepmd-cpu-v3
    export LD_LIBRARY_PATH=/opt/deepmd-cpu-v3/lib:/opt/deepmd-cpu-v3/lib/deepmd_lmp:$LD_LIBRARY_PATH
    export PATH=/opt/deepmd-cpu-v3/bin:$PATH

elif [ -f /opt/miniconda3/bin/activate ]; then
    source /opt/miniconda3/bin/activate deepmd-cpu-v3
    export LD_LIBRARY_PATH=/opt/deepmd-cpu-v3/lib:/opt/deepmd-cpu-v3/lib/deepmd_lmp:$LD_LIBRARY_PATH
    export PATH=/opt/deepmd-cpu-v3/bin:$PATH
else
    echo "Error: Neither /opt/anaconda3/bin/activate nor /opt/miniconda3/bin/activate found."
    exit 1  # Exit the script if neither exists
fi

rm -f /home/jsp1/AlP/QE4heat/crontab.log

cd /home/jsp1/AlP/QE4heat && echo "$(date) - Running check_QEjobs4heating.pl"  >> /home/jsp1/AlP/QE4heat/crontab.log 2>&1 && /usr/bin/perl /home/jsp1/AlP/QE4heat/check_QEjobs4heating.pl >> /home/jsp1/AlP/QE4heat/crontab.log 2>&1 && echo "$(date) - Running submit4newHeat.pl"  >> /home/jsp1/AlP/QE4heat/crontab.log 2>&1 && /usr/bin/perl /home/jsp1/AlP/QE4heat/submit4newHeat.pl  >> /home/jsp1/AlP/QE4heat/crontab.log 2>&1
