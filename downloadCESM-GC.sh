#!/bin/bash

if [ $# -eq 1 ]; then
    baseFolder=$1
else
    baseFolder=CESM-GC
fi

if [ -d $baseFolder ]; then
    echo "Folder $baseFolder already exists!"
    exit 1;
fi
baseFolder=$(realpath $baseFolder)

## Do not modify sharedFolder!
sharedFolder=/glade/p/univ/umit0034/Shared/

# Step 1: Create folders where CESM source code goes.
mkdir -p $baseFolder/cesm_standard; cd $baseFolder/cesm_standard

# Step 2: Obtain CESM source code
destFolder=cesm.2.1.1
branch=release-cesm2.1.1
git clone -b $branch https://github.com/ESCOMP/cesm.git $destFolder; cd $destFolder

# External* files indicate how and where to get external repositories.
# Here we indicate to get the appropriate CAM and CLM modifications
# required for GEOS-Chem to run within CESM.
# Step 3: Copy Externals.cfg
cp $sharedFolder/Externals.cfg .

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
git clone git@github.com:fritzt/CESM2-GC_SourceMods.git $baseFolder/CESM-GC_SourceMods
# As of right now, the option --user-mods-dir in create_newcase seems
# to not pick up the modified files. We thus revert to copying the changes
# where needed
cp $baseFolder/CESM-GC_SourceMods/src.drv/seq_drydep_mod.F90 $baseFolder/cesm_standard/$destFolder/cime/src/drivers/mct/shr

if [ $? != 0 ]; then
    echo "Error in Step 5: Something went wrong when applying changes to the coupler!"
    exit 1;
fi

# Step 6: Obtain configuration files. If you have already run CESM before,
# then you probably have these files already
if [ ! -d $HOME/.cime ]; then
    ln -s $sharedFolder/.cime $HOME/.cime
else
    echo "Skipping Step 5: $HOME/.cime already exists!"
fi

# Step 7: Only the GEOS-Chem chemistry files are compiled. We use a
# modified version of mkSrcfiles to exclude file at compile time
CIMEROOT=$PWD/cime/
if [ -d $CIMEROOT/scripts/Tools ]; then
    cp $sharedFolder/mkSrcfiles $CIMEROOT/scripts/Tools
    chmod +x $CIMEROOT/scripts/Tools/mkSrcfiles
else
    echo "Error in Step 6: Could not locate cime/scripts/Tools"
    echo "Attempt was $CIMEROOT/scripts/Tools"
    exit 1;
fi

echo ""
echo "Setup is complete!"
echo "To build a case, go to $CIMEROOT/scritps and create a new case:"
echo "GEOS-Chem has 3 different compsets, paired with each version of CLM:"
echo "- FGC (default GEOS-Chem compset paired with CLM4.0)"
echo "- FGC_CLM45 (GEOS-Chem compset paired with CLM4.5)"
echo "- FGC_CLM50 (GEOS-Chem compset paired with CLM5.0)"
echo "> $CIMEROOT/scripts/create_newcase --case /path/to/folder --compset FGC_CLM50 --res f19_f19_mg17 --run-unsupported --project PROJECT_ID"
echo "Please fill in /path/to/folder and PROJECT_ID"

