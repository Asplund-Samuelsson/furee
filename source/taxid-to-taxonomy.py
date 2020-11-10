#!/usr/bin/env python

#==============================================================================
#
#    Usage:
#    ./taxid-to-taxonomy.py -i <infile> -n <names.dmp> -d <nodes.dmp>
#    -o <outfile>
#
#    Description:
#    Reads an infile, which is a two-column tab-delimited table of identifiers
#    of choice in the first column and taxids in the second. The NCBI taxnomy
#    names.dmp and nodes.dmp files must be specified. Output to outfile is a
#    tab-delimited table containing the identifier, the taxid and the full
#    NCBI taxonomy.
#
#    Author:
#    Johannes Asplund Samuelsson
#
#==============================================================================


from optparse import OptionParser
import sys

parser = OptionParser()
parser.add_option("-i", "--infile", dest="infile",
        action="store", type="string",
        help="Read tab-delimited infile (id, taxid).")
parser.add_option("-n", "--names", dest="names",
        action="store", type="string",
        help="Read NCBI names.dmp file.")
parser.add_option("-d", "--nodes", dest="nodes",
        action="store", type="string",
        help="Read NCBI nodes.dmp file.")
parser.add_option("-o", "--outfile", dest="outfile",
        action="store", type="string",
        help="Write to outfile.")

(options, args) = parser.parse_args()

if not options.infile or not options.names or not options.nodes \
or not options.outfile: sys.exit(parser.print_help())




################################################################################
### NCBI TAXONOMY PARSING BY ROMAIN STUDER (2013) ##############################
# https://evosite3d.blogspot.com/2013/06/browsing-ncbi-taxonomy-with-python.html

import os
import sys

# Definition of the classe Node
class Node:
    """Noeud"""
    def __init__(self):
        self.tax_id = 0       # Number of the tax id.
        self.parent = 0       # Number of the parent of this node
        self.children = []    # List of the children of this node
        self.tip = 0          # Tip=1 if it's a terminal node, 0 if not.
        self.name = ""        # Name of the node: taxa if it's a terminal node, numero if not.
    def genealogy(self):      # Trace genealogy from root to leaf
        ancestors = []        # Initialise the list of all nodes from root to leaf.
        tax_id = self.tax_id  # Define leaf
        while 1:
            if tax_id in name_object:
                ancestors.append(tax_id)
                tax_id = name_object[tax_id].parent
            else:
                break
            if tax_id == "1":
                # If it is the root, we reached the end.
                # Add it to the list and break the loop
                ancestors.append(tax_id)
                break
        return ancestors # Return the list

# Function to find common ancestor between two nodes or more
def common_ancestor(node_list):
    global name_object
    list1 = name_object[node_list[0]].genealogy()  # Define the whole genealogy of the first node
    for node in node_list:
        list2 = name_object[node].genealogy()      # Define the whole genealogy of the second node
        ancestral_list = []
        for i in list1:
            if i in list2:                         # Identify common nodes between the two genealogy
                ancestral_list.append(i)
        list1 = ancestral_list                     # Reassing ancestral_list to list 1.
    common_ancestor = ancestral_list[0]            # Finally, the first node of the ancestra_list is the common ancestor of all nodes.
    return common_ancestor                         # Return a node


#############################
#                           #
#   Read taxonomy files     #
#                           #
#############################

######################
#
# Load names defintion

name_dict = {}          # Initialise dictionary with TAX_ID:NAME
name_dict_reverse = {}  # Initialise dictionary with NAME:TAX_ID

# Load  NCBI names file ("names.dmp")

print("Loading NCBI names.dmp file.")

name_file =  open(options.names,"r")
while 1:
    line = name_file.readline()
    if line == "":
        break
    line = line.rstrip()
    line = line.replace("\t","")
    tab = line.split("|")
    if tab[3] == "scientific name":
        tax_id, name = tab[0], tab[1]     # Assign tax_id and name ...
        name_dict[tax_id] = name          # ... and load them
        name_dict_reverse[name] = tax_id  # ... into dictionaries
name_file.close()


######################
#
# Load taxonomy

# Define taxonomy variable
global name_object
name_object = {}


# Load taxonomy NCBI file ("nodes.dmp")

print("Loading NCBI nodes.dmp file.")

taxonomy_file = open(options.nodes,"r")
while 1:
    line = taxonomy_file.readline()
    if line == "":
        break
    #print line
    line = line.replace("\t","")
    tab = line.split("|")

    tax_id = str(tab[0])
    tax_id_parent = str(tab[1])
    division = str(tab[4])

    # Define name of the taxid
    name = "unknown"
    if tax_id in name_dict:
        name = name_dict[tax_id]

    if not tax_id in name_object:
        name_object[tax_id] = Node()
    name_object[tax_id].tax_id   = tax_id        # Assign tax_id
    name_object[tax_id].parent   = tax_id_parent # Assign tax_id parent
    name_object[tax_id].name     = name          # Assign name

    if  tax_id_parent in name_object:
        children = name_object[tax_id].children  # If parent is is already in the object
        children.append(tax_id)                  # ...we found its children.
        name_object[tax_id].children = children  # ... so add them to the parent
taxonomy_file.close()


#####################################################################################################
#####################################################################################################




# Read infile line-by-line, acquire taxonomy, write to outfile

print("Analysing taxonomy and writing to outfile.")

taxid_swap_dict = {}

def SwapTaxidViaEntrez(taxid):
    """Fetch the record for taxid from NCBI Entrez and return the current taxid."""

    from Bio import Entrez
    Entrez.email = 'johannes.asplund.samuelsson@scilifelab.se'

    print("Contacting NCBI Entrez regarding taxid %s..." % (taxid))

    handle = Entrez.efetch(db='taxonomy', id=taxid)
    record = Entrez.read(handle)
    if len(record) == 0:
        print("Warning: Taxid %s is not available in the NCBI taxonomy database. Returning 32644 - Unknown." % taxid)
        return '32644' # "Unknown"
    current_taxid = record[0]['TaxId']

    print("Swapping taxid %s for taxid %s, via NCBI Entrez." % (taxid, current_taxid))

    return current_taxid



print("Loading taxid-to-rank from nodes.dmp.")

taxid_to_rank = {}

for line in open(options.nodes):

    line = line.split("\t|\t")

    taxid = line[0]
    rank = line[2]

    taxid_to_rank[taxid] = rank


wanted_ranks = [
    'superkingdom','kingdom','phylum','class',
    'order','family','genus','species'
]


from Bio import Entrez
Entrez.email = 'johannes.asplund.samuelsson@scilifelab.se'


outfile = open(options.outfile, 'w')


# Write header to outfile

header = "\t".join([
    "identifier","taxid","group","\t".join(wanted_ranks),
    "lowest_rank_name","full_lineage\n"
])
outfile.write(header)


for line in open(options.infile):

    # Split line
    line = line.split("\t")
    taxid = line[1].rstrip()
    identifier = line[0]

    # If the taxonomy ID is empty, replace with 1 (root of NCBI taxonomy)
    if not taxid:
        taxid = "1"

    # Determine lineage of record
    try:
        lineage = name_object[taxid].genealogy()
    except KeyError:
        try:
            taxid = taxid_swap_dict[taxid]
        except KeyError:
            taxid_temp = SwapTaxidViaEntrez(taxid)
            taxid_swap_dict[taxid] = taxid_temp
            taxid = taxid_temp
        try:
            lineage = name_object[taxid].genealogy()
        except KeyError:
            print("Warning: Taxid %s for sequence %s is not available locally or online. Skipping sequence." % (taxid, identifier))
            continue

    # Go through lineage, adding wanted rank names
    wanted_rank_lineage = dict(zip(wanted_ranks, [''] * len(wanted_ranks)))
    previous_rank = ''

    lowest_rank_taxid = lineage[0]
    lowest_rank_name = name_object[lowest_rank_taxid].name

    for current_taxid in lineage:
        if taxid_to_rank[current_taxid] in wanted_ranks:
            wanted_rank_lineage[taxid_to_rank[current_taxid]] = current_taxid

    # Go through lineage and write to outfile
    full_lineage_names = []
    for taxid2 in lineage:
        full_lineage_names.append(name_object[taxid2].name)

    full_lineage = ["@".join(x) for x in zip(full_lineage_names, lineage)]

    wanted_rank_lineage_names = []

    for wanted_rank in wanted_ranks:
        if wanted_rank_lineage[wanted_rank] == '':
            wanted_rank_lineage_names.append('NA')
        else:
            wanted_rank_lineage_names.append(name_object[wanted_rank_lineage[wanted_rank]].name)

    # Determine group
    if wanted_rank_lineage['phylum'] == '':
        tax_phylum = 'NA'
    else:
        tax_phylum = name_object[wanted_rank_lineage['phylum']].name
    if wanted_rank_lineage['class'] == '':
        tax_class = 'NA'
    else:
        tax_class = name_object[wanted_rank_lineage['class']].name
    if tax_phylum == 'Proteobacteria':
        group = tax_class
    else:
        group = tax_phylum

    # Prepare output and write to outfile
    output = "\t".join([identifier, taxid, group, "\t".join(wanted_rank_lineage_names), lowest_rank_name, "|" + "|".join(full_lineage)]) + "|\n"
    outfile.write(output)

outfile.close()
