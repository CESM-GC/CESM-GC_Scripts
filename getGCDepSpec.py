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
AerDryDepList = []
GasWetDepList = []
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
                    GasDryDepList.append(species)
                if IsGas and IsWD:
                    GasWetDepList.append(species)
                if not IsGas and IsDD:
                    AerDryDepList.append(species)
                if not IsGas and IsWD:
                    AerWetDepList.append(species)
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
                    elem.text += "'{:s}',".format(spec.upper())
                elem.text += "\n"
            except AttributeError:
                pass
        elif elem.tag == 'aer_drydep_list':
            List = AerDryDepList
            try:
                elem.text = "\n  "
                for spec in List:
                    elem.text += "'{:s}',".format(spec.upper())
                elem.text += "\n"
            except AttributeError:
                pass
        elif elem.tag == 'gas_wetdep_list':
            List = GasWetDepList
            try:
                elem.text = "\n  "
                for spec in List:
                    elem.text += "'{:s}',".format(spec.upper())
                elem.text += "\n"
            except AttributeError:
                pass
        elif elem.tag == 'aer_wetdep_list':
            List = AerWetDepList
            try:
                elem.text = "\n  "
                for spec in List:
                    elem.text += "'{:s}',".format(spec.upper())
                elem.text += "\n"
            except AttributeError:
                pass

tree.write(XMLFile, xml_declaration=True)
