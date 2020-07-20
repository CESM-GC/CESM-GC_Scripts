#!/bin/bash

# Optionally pass where to download
if [ $# -eq 1 ]; then
    baseFolder=$1
else
    echo "Must pass destination folder path as argument, e.g. ../CESM-GC!"
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
destFolder=$cesmSrcFolder/cesm.2.1.1
branch=release-cesm2.1.1
git clone -b $branch https://github.com/ESCOMP/cesm.git $destFolder
cd $destFolder

# External* files indicate how and where to get external repositories.
# Here we indicate to get the appropriate CAM and CLM modifications
# required for GEOS-Chem to run within CESM. Copying is just for archiving.
# Step 3: Copy Externals.cfg
if [ -f ./Externals.cfg ]; then
    echo "Will checkout externals based on $externalsCfg, copied to $destFolder"
    echo ""
    cp $externalsCfg $destFolder
else
    echo "File Externals.cfg must be in the same directory where downloadCESM-GC.sh is run!"
    exit 1;
fi

# Step 4: Obtain modifications
./manage_externals/checkout_externals
# N.B.: If you already ran ./manage_externals/checkout_externals before
# Step 3, then you'll have to:
# rm -rf $baseFolder/cesm_standard/$destFolder/components/cam
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

# Step 5: Get modifications to the coupler.
git clone git@github.com:CESM-GC/CESM2-GC_SourceMods.git $baseFolder/CESM-GC_SourceMods
# As of right now, the option --user-mods-dir in create_newcase seems
# to not pick up the modified files. We thus revert to copying the changes
# where needed
cp $baseFolder/CESM-GC_SourceMods/src.drv/seq_drydep_mod.F90 $destFolder/cime/src/drivers/mct/shr

if [ $? != 0 ]; then
    echo "Error in Step 5: Something went wrong when applying changes to the coupler!"
    exit 1;
fi

# Step 6: Obtain configuration files. If you have already run CESM before,
# then you probably have these files already
if [ ! -d $HOME/.cime ]; then
    ln -s $sharedFolder/.cime $HOME/.cime
else
    echo "Skipping Step 6: $HOME/.cime already exists!"
fi

# Step 7: Only the GEOS-Chem chemistry files are compiled. We use a
# modified version of mkSrcfiles to exclude file at compile time
CIMEROOT=$PWD/cime/
if [ -d $CIMEROOT/scripts/Tools ]; then
    cp $sharedFolder/mkSrcfiles $CIMEROOT/scripts/Tools
    chmod +x $CIMEROOT/scripts/Tools/mkSrcfiles
else
    echo "Error in Step 7: Could not locate cime/scripts/Tools"
    echo "Attempt was $CIMEROOT/scripts/Tools"
    exit 1;
fi

# Step 8: Create convenience symbolic links to HEMCO and GEOS-Chem
echo ""
echo "Creating symbolic links for convenience:"
gcFolder=$baseFolder/cesm_standard/cesm.2.1.1/components/cam/src/chemistry/pp_geoschem/geoschem_src
ln -s $gcFolder  $baseFolder/GEOS-Chem
echo "--> GEOS-Chem: $gcFolder"
hemcoFolder=$baseFolder/cesm_standard/cesm.2.1.1/components/cam/src/hemco/HEMCO
ln -s $hemcoFolder $baseFolder/HEMCO
echo "--> HEMCO: $hemcoFolder"
ln -s $destFolder/Externals.cfg $baseFolder
echo "--> Externals.cfg: $destFolder/Externals.cfg"

echo ""
echo "Setup is complete!"
echo "To build a case, go to $CIMEROOT/scritps and create a new case:"
echo "GEOS-Chem has 3 different compsets, paired with each version of CLM:"
echo "- FGC (default GEOS-Chem compset paired with CLM4.0)"
echo "- FGC_CLM45 (GEOS-Chem compset paired with CLM4.5)"
echo "- FGC_CLM50 (GEOS-Chem compset paired with CLM5.0)"
echo "> $CIMEROOT/scripts/create_newcase --case /path/to/folder --compset FGC_CLM50 --res f19_f19_mg17 --run-unsupported --project PROJECT_ID"
echo "Please fill in /path/to/folder and PROJECT_ID"

