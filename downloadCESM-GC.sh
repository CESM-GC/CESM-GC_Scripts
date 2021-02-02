#!/bin/bash

# Optionally pass where to download
if [ $# -eq 1 ]; then
    baseFolder=$1
else
    echo "Must pass destination folder path as argument, e.g. ~/CESM-GC!"
    exit 1;
fi

if [ -d $baseFolder ]; then
    echo "Folder $baseFolder already exists!"
    exit 1;
fi
baseFolder=$(realpath $baseFolder)
echo "Downloading CESM to $baseFolder"
echo ""

if [ ! -f ./Externals.cfg ]; then
    echo "Externals.cfg must exist in directory download script is run in!"
    exit 1;
else
    externalsCfg=./Externals.cfg
    externalsCfg=$(realpath $externalsCfg)
fi

## Do not modify sharedFolder!
sharedFolder=/glade/p/univ/umit0034/Shared/

# Step 1: Create folders where CESM source code goes.
cesmSrcFolder=$baseFolder/cesm_standard
mkdir -p $cesmSrcFolder
cd $cesmSrcFolder

# Step 2: Obtain CESM source code
cesmRepo=$cesmSrcFolder/cesm.2.1.1
branch=release-cesm2.1.1
git clone -b $branch https://github.com/ESCOMP/cesm.git $cesmRepo
cd $cesmRepo

# External* files indicate how and where to get external repositories.
# Here we indicate to get the appropriate CAM and CLM modifications
# required for GEOS-Chem to run within CESM. Copying is just for archiving.
# Step 3: Copy Externals.cfg
if [ -f ./Externals.cfg ]; then
    echo "Will checkout externals based on $externalsCfg, copied to $cesmRepo"
    echo ""
    cp $externalsCfg $cesmRepo
else
    echo "File Externals.cfg must be in the same directory where downloadCESM-GC.sh is run!"
    exit 1;
fi

# Step 4: Obtain modifications
./manage_externals/checkout_externals
# N.B.: If you already ran ./manage_externals/checkout_externals before
# Step 3, then you'll have to:
# rm -rf $baseFolder/cesm_standard/$cesmRepo/components/cam
# and perform Step 4 again
# This occurs because by default `release-cesm2.1.1` uses svn to obtain
# the CAM repo. CAM has since then moved to git for version control and
# checkout_externals will throw out an error if it detects that the version
# control software has changed.

if [ $? != 0 ]; then
    echo "Error in Step 4: Something went wrong in checkout_externals!"
    #echo "Did you run checkout_externals before obtaining Externals.cfg?"
    exit 1;
fi

# Step 5: Obtain configuration files. If you have already run CESM before,
# then you probably have these files already
if [ ! -d $HOME/.cime ]; then
    ln -s $sharedFolder/.cime $HOME/.cime
else
    echo "Skipping Step 5: $HOME/.cime already exists!"
fi

CIMEROOT=$PWD/cime/

# Step 6: Create convenience symbolic links to HEMCO and GEOS-Chem
echo ""
echo "Creating symbolic links for convenience:"

srcDir=$cesmRepo/cime/scripts
ln -s $srcDir $baseFolder/scripts
echo "--> scripts: $srcDir"

srcDir=$cesmRepo/components/cam/src/chemistry/geoschem/geoschem_src
ln -s $srcDir  $baseFolder/GEOS-Chem
echo "--> GEOS-Chem: $srcDir"

srcDir=$cesmRepo/components/cam
ln -s $srcDir  $baseFolder/CAM
echo "--> CAM: $srcDir"

srcDir=$cesmRepo/components/cam/src/hemco/HEMCO
ln -s $srcDir $baseFolder/HEMCO
echo "--> HEMCO: $srcDir"

srcDir=$cesmRepo/components/cam/src/hemco
ln -s $srcDir $baseFolder/HEMCO_CESM
echo "--> HEMCO_CESM: $srcDir"

srcFile=$cesmRepo/Externals.cfg
ln -s $srcFile $baseFolder
echo "--> Externals.cfg: $srcFile"

srcFile=$cesmRepo/components/cam/Externals_CAM.cfg
ln -s $srcFile $baseFolder
echo "--> Externals_CAM.cfg: $srcFile"

srcFile=$cesmRepo/components/cam/src/hemco/Externals_HCO.cfg
ln -s $srcFile $baseFolder
echo "--> Externals_HCO.cfg: $srcFile"

echo ""
echo "Setup is complete!"
echo "To build a case, go to $CIMEROOT/scritps and create a new case:"
echo "GEOS-Chem has different compsets, built around the existing compsets for CAM-Chem:"
echo "- FC2010climo_GC"
echo "- FC2000climo_GC"
echo "- FCSD_GC"
echo "- FCHIST_GC"
echo "> $CIMEROOT/scripts/create_newcase --case /path/to/folder --compset FCSD_GC --res f09_f09_mg17 --run-unsupported --project PROJECT_ID"
echo "Please fill in /path/to/folder and PROJECT_ID"

