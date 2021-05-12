#!/usr/bin/env bash

# Read input flags
while getopts k:i:o: flag
	do
	    case "${flag}" in
          k) KOS=${OPTARG};;       # KOs separated by comma
          i) INFILE=${OPTARG};;   # Infile listing KOs
	        o) OUTFILE=${OPTARG};;  # Output FASTA
	    esac
	done

# Print out KOs
(
  if [ "$KOS" ]; then echo $KOS | tr "," "\n"; fi
  if [ -f "$INFILE" ]; then cat $INFILE; fi
) |

while read KO; do

  # Get UniProt links from KEGG
  wget -qO - https://www.genome.jp/kegg-bin/uniprot_list?ko=${KO} |
  grep "www.uniprot.org" | cut -f 2 -d \' | sed -e 's/$/.fasta/'

done | sort | uniq |

# Download sequences from UniProt
sed -e 's/^/wget -qO - /' | parallel --no-notice --jobs 16 > $OUTFILE
