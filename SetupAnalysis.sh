#!/bin/bash

if [ -z $CMSSW_BASE ]; then
    echo "========================================"
    echo "No CMS environment detected; stopping..."
    echo "========================================"
    exit 1
fi

if [ $# == 0 ]; then
    echo "========================================"
    echo "No analysis choice provided; stopping..."
    echo "========================================"
    exit 1
fi

isnew=0
analysis=$1
usebase=0

if [[ $analysis == 'new'* ]]; then
    analysis=${analysis#new}
    isnew=1
fi

if [ $# == 2 ]; then
    usebase=1
fi

source $CMSSW_BASE/src/LatinosSetup/Functions.sh

if [[ "$CMSSW_VERSION" == CMSSW_13_*_* ]]; then
    echo "======================================="
    echo "running with $CMSSW_VERSION - this is a 13.6 TeV setup!"
    echo "Current time:" $(date)
    echo "checking out additional repositories; this could take a while ..."
    echo "======================================="

    echo " - Basic Code"

    git clone git@github.com:scodella/LatinoAnalysis.git LatinoAnalysis
    cd LatinoAnalysis
    if [ $analysis == 'master' ]; then
        git remote add upstream https://github.com/latinos/LatinoAnalysis
        sed "s|https://github.com/latinos/setup|https://github.com/latinos/LatinoAnalysis|g" ../LatinosSetup/sync2upstream.sh > sync2upstream.sh    
    elif [ $usebase == 1 ]; then
        git checkout base
    elif [ $isnew == 1 ]; then
        git checkout base
        git checkout -b $analysis base
        sed -i "s|base|${analysis}|g;s|master|base|g" sync2master.sh 
        git mv sync2master.sh sync2base.sh ; git commit -m "sync2master to sync2base script"
    else
        git checkout $analysis
    fi     
    cd -

    if [ $analysis == 'master' ]; then
        exit 1
    fi

    echo " - Plots Configurations"

    if [ $isnew == 1 ]; then
        git clone -b base git@github.com:scodella/PlotsConfigurations PlotsConfigurations
        cd PlotsConfigurations
        git checkout -b $analysis base
        sed -i "s|RPLME_ANALYSIS|${analysis}|g" sync2base.sh
        git add sync2base.sh ; git commit -m "update to sync2base script"
	cd -
    else
        git clone -b $analysis git@github.com:scodella/PlotsConfigurations PlotsConfigurations
    fi

    if [ $analysis == 'base' ]; then
        exit 1
    fi

    echo " - Plotting Tools"

    git clone git@github.com:scodella/multidraw.git LatinoAnalysis/MultiDraw
    cd LatinoAnalysis/MultiDraw
    #git checkout 2.0.12 2>/dev/null # This gives me an error
    git checkout 2.0.12 >/dev/null
    ./mkLinkDef.py --cmssw
    cd ../..

    if [ $analysis == 'worker' ]; then
      
	echo " - Nano Tools"

        git clone git@github.com:scodella/nanoAOD-tools PhysicsTools/NanoAODTools

    fi

    if [ $analysis == 'BTagPerf' ]; then

	echo " - BTV scale factor repository"

    	git clone https://gitlab.cern.ch/cms-btv/btv-scale-factors

    fi

    if [ $analysis == 'XXX' ]; then

        echo " - MELA new version"
    
        git clone git@github.com:MELALabs/MelaAnalytics.git MelaAnalytics
        cd MelaAnalytics ; git checkout -b from-v22 v2.2 ; cd ..
        git clone https://github.com/JHUGen/JHUGenMela.git JHUGenMELA
        cd JHUGenMELA; git checkout -b from-v235 v2.3.5 ; source setup.sh -j 12 ; cd ..

    fi

    scram b -j 8

fi

