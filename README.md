# CESM-GC_Scripts

This repository contains utility scripts for use with CESM2-GC.

Authors: 
Thibaud M. Fritz (@fritzt)
Lizzie W. Lundgren (@lizziel)

-------------------------------------------------------------------------------------------------------

GEOS-Chem embedded in CESM2, or CESM2-GC, follows the same code architecture and run directory structure as when running with CAM-Chem.

For now, the interface between CAM6 (the atmospheric component of CESM2) and GEOS-Chem hasn't been pushed to the official Github repository of CAM6.

In the meantime, the code to run CESM2-GC can be obtained by providing a specific `Externals.cfg`, as provided in this repository.

CESM2 is a combination of different components, each of them being externally stored in a separate Github repository. `Externals.cfg` specifies which Github repository, branch or tag need to be checked out.


The `downloadCESM-GC.sh` bash script takes in one argument, which specifies the root folder of your CESM2 installation. It then downloads the CESM2-GC code directory (coupling CESM2.1.1 with GEOS-Chem 13.0.0) and provides instructions on how to setup a run directory with the GEOS-Chem chemistry option. Note that the atmospheric chemistry option (GEOS-Chem or CAM-Chem) needs to be defined when specifying the compset.

For now, compsets using GEOS-Chem chemistry end with "_GC":
- FCSD_GC (FCSD compset with GEOS-Chem chemistry)
- FCHIST_GC
- FC2010CLIMO_GC
- FC2000CLIMO




