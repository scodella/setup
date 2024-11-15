#!/bin/bash

if [[ $CMSSW_BASE == 'CMSSW'* ]]; then
    echo "========================================"
    echo "CMS environment detected; stopping...   "
    echo "========================================"
    exit 1
fi

if [ $# == 0 ]; then
    echo "========================================"
    echo "No analysis choice provided; stopping..."
    echo "========================================"
    exit 1
fi

base=base
analysis=$1

isnew=0

if [[ $analysis == 'new'* ]]; then
    analysis=${analysis#new}
    isnew=1
fi

latino=$analysis

if [ $# == 2 ]; then
    if [[ $2 != 'keep' ]]; then
        base=${2#keep}
    fi
    if [[ $2 == 'keep'* ]]; then
	latino=$base
    fi
fi

echo " - mkShapesRDF"

git clone https://github.com/scodella/mkShapesRDF.git
cd mkShapesRDF/
if [ $analysis == 'master' ]; then
    git remote add upstream https://github.com/latinos/mkShapesRDF.git
    sed "s|setup|mkShapesRDF|g" ../LatinosSetup/sync2upstream.sh > sync2upstream.sh
    exit 1
elif [ $isnew == 0 ]; then
    git checkout $latino
else 
    git checkout $base
    if [ $latino != $base ]; then
        git checkout -b $analysis $base
        sed -i "s|${base}|${analysis}|g;s|master|${base}|g" sync2master.sh 
        git mv sync2master.sh sync2$base.sh ; git commit -m "sync2master to sync2$base script"
    fi
fi     
cd -

echo " - PlotsConfigurationsRun3"

if [ $isnew == 1 ]; then
    git clone -b $base git@github.com:scodella/PlotsConfigurationsRun3 PlotsConfigurationsRun3
    cd PlotsConfigurationsRun3
    git checkout -b $analysis $base
    sed -i "s|RPLME_ANALYSIS|${analysis}|g" sync2$base.sh
    git add sync2$base.sh ; git commit -m "update sync2$base script"
    cd -
else
    git clone -b $analysis git@github.com:scodella/PlotsConfigurationsRun3 PlotsConfigurationsRun3
fi

if [ $analysis == $base ]; then
    exit 1
fi





