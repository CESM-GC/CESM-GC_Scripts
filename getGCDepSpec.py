#!/usr/bin/env python

## Author     : Thibaud M. Fritz
## Date       : 07/30/2020
## Affiliation: Laboratory for Aviation and the Environment, Massachusetts Institute of Technology
## Usage      :
##  python getGCDepSpec.py /path/to/geoschem.xml /path/to/species_database.yml

###############################################################################################

import sys
import yaml
import xml.etree.ElementTree as ET

HELP_MESSAGE = \
    '+ Usage   :\n' +\
    '  > python getGCDepSpec.py /path/to/geoschem.xml /path/to/species_database.yml\n\n' +\
    '+ Argument:\n' +\
    '++ 1) Path to geoschem.xml (usually in components/cam/bld/namelist_files/use_cases)\n' +\
    '++ 2) Path to species_database.yml (optional)\n'

USE_MAM4 = True

args = len(sys.argv) - 1
if args == 0:
    print(HELP_MESSAGE)
    sys.exit(0)
elif args == 1:
    # Path to geoschem.xml | Requires write permission!
    XMLFile = sys.argv[1]
    # Path to species_database.yml | Requires read access
    YAMLFile = '/glade/u/home/fritzt/species_database.yml'
elif args == 2:
    # Path to geoschem.xml | Requires write permission!
    XMLFile = sys.argv[1]
    # Path to species_database.yml | Requires read access
    YAMLFile= sys.argv[2]
else:
    print(HELP_MESSAGE)
    sys.exit(1)

###############################################################################################

GasDryDepList = []
GasWetDepList = []

if USE_MAM4:
    AerDryDepList = ['dst_a1','so4_a1','nh4_a1','pom_a1','pomff1_a1','pombb1_a1','soa_a1','bc_a1','ncl_a1','num_a1','so4_a2','nh4_a2','soa_a2','ncl_a2','dst_a2','num_a2','dst_a3','ncl_a3','so4_a3','pom_a3','bc_a3','num_a3','ncl_a4','so4_a4','pom_a4','pomff1_a4','pombb1_a4','bc_a4','nh4_a4','num_a4','dst_a5','so4_a5','nh4_a5','num_a5','ncl_a6','so4_a6','nh4_a6','num_a6','dst_a7','so4_a7','nh4_a7','num_a7','soa1_a1','soa1_a2','soa2_a1','soa2_a2','soa3_a1','soa3_a2','soa4_a1','soa4_a2','soa5_a1','soa5_a2','soaff1_a1','soaff2_a1','soaff3_a1','soaff4_a1','soaff5_a1','soabb1_a1','soabb2_a1','soabb3_a1','soabb4_a1','soabb5_a1','soabg1_a1','soabg2_a1','soabg3_a1','soabg4_a1','soabg5_a1','soaff1_a2','soaff2_a2','soaff3_a2','soaff4_a2','soaff5_a2','soabb1_a2','soabb2_a2','soabb3_a2','soabb4_a2','soabb5_a2','soabg1_a2','soabg2_a2','soabg3_a2','soabg4_a2','soabg5_a2']
    AerWetDepList = ['dst_a1','so4_a1','nh4_a1','pom_a1','pomff1_a1','pombb1_a1','soa_a1','bc_a1','ncl_a1','num_a1','so4_a2','nh4_a2','soa_a2','ncl_a2','dst_a2','num_a2','dst_a3','ncl_a3','so4_a3','pom_a3','bc_a3','num_a3','ncl_a4','so4_a4','pom_a4','pomff1_a4','pombb1_a4','bc_a4','nh4_a4','num_a4','dst_a5','so4_a5','nh4_a5','num_a5','ncl_a6','so4_a6','nh4_a6','num_a6','dst_a7','so4_a7','nh4_a7','num_a7','soa1_a1','soa1_a2','soa2_a1','soa2_a2','soa3_a1','soa3_a2','soa4_a1','soa4_a2','soa5_a1','soa5_a2','soaff1_a1','soaff2_a1','soaff3_a1','soaff4_a1','soaff5_a1','soabb1_a1','soabb2_a1','soabb3_a1','soabb4_a1','soabb5_a1','soabg1_a1','soabg2_a1','soabg3_a1','soabg4_a1','soabg5_a1','soaff1_a2','soaff2_a2','soaff3_a2','soaff4_a2','soaff5_a2','soabb1_a2','soabb2_a2','soabb3_a2','soabb4_a2','soabb5_a2','soabg1_a2','soabg2_a2','soabg3_a2','soabg4_a2','soabg5_a2']
else:
    AerDryDepList = []
    AerWetDepList = []

with open(YAMLFile, 'r') as stream:
    try:
        GCdict = yaml.safe_load(stream)
        for species in GCdict.keys():
            if '_PROP' not in species:
                string = 'Is_Gas'
                if ((string in GCdict[species].keys()) and (GCdict[species][string] == True)):
                    IsGas = True
                else:
                    IsGas = False
                string = 'Is_DryDep'
                if ((string in GCdict[species].keys()) and (GCdict[species][string] == True)):
                    IsDD = True
                else:
                    IsDD = False
                string = 'Is_WetDep'
                if ((string in GCdict[species].keys()) and (GCdict[species][string] == True)):
                    IsWD = True
                else:
                    IsWD = False
                if IsGas and IsDD:
                    GasDryDepList.append(species.upper())
                if IsGas and IsWD:
                    GasWetDepList.append(species.upper())
                if not IsGas and IsDD:
                    AerDryDepList.append(species.upper())
                if not IsGas and IsWD:
                    AerWetDepList.append(species.upper())
    except yaml.YAMLError as exc:
        print(exc)

class _CommentedTreeBuilder(ET.TreeBuilder):
    def comment(self, data):
        self.start('!--')
        self.data(data)
        self.end('--')

with open(XMLFile) as f:
    ctb = _CommentedTreeBuilder()
    xp = ET.XMLParser(target=ctb)
    tree = ET.parse(f, parser=xp)
    root = tree.getroot()
    for elem in root.getiterator():
        if elem.tag == 'drydep_list':
            List = GasDryDepList
            try:
                elem.text = "\n  "
                for spec in List:
                    elem.text += "'{:s}',".format(spec)
                elem.text += "\n"
            except AttributeError:
                pass
        elif elem.tag == 'aer_drydep_list':
            List = AerDryDepList
            try:
                elem.text = "\n  "
                for spec in List:
                    elem.text += "'{:s}',".format(spec)
                elem.text += "\n"
            except AttributeError:
                pass
        elif elem.tag == 'gas_wetdep_list':
            List = GasWetDepList
            try:
                elem.text = "\n  "
                for spec in List:
                    elem.text += "'{:s}',".format(spec)
                elem.text += "\n"
            except AttributeError:
                pass
        elif elem.tag == 'aer_wetdep_list':
            List = AerWetDepList
            try:
                elem.text = "\n  "
                for spec in List:
                    elem.text += "'{:s}',".format(spec)
                elem.text += "\n"
            except AttributeError:
                pass

tree.write(XMLFile, xml_declaration=True)
