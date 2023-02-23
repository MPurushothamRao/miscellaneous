def dssp_to_ssd(dssp_file, ssd_file):
    """
    Converts a DSSP file to an SSD file.

    Args:
    dssp_file (str): Path to the DSSP file.
    ssd_file (str): Path to the SSD file to create.
    """
    i=-1
    with open(dssp_file, "r") as dssp_f, open(ssd_file, "w") as ssd_f:
        for line in dssp_f:
            if line.startswith("  #"):
                continue
            residue = line[13]
            structure = line[16]
            chain = line[11]
            if chain == "A":
                
                if structure == " ":
                    structure = "~"
                if i !=-1:
                    ssd_f.write(structure)
                i+=1
    with open(ssd_file, 'r') as f:
        original_text = f.read()
    
    with open(ssd_file, 'w') as f:
        new_text = f"{i}\n"
        f.write(new_text + original_text)

import argparse

parser = argparse.ArgumentParser(description='to convert dssp file to ssd file')
parser.add_argument('-i', '--input', type=str, help='input file in dssp extension')
parser.add_argument('-o', '--output', type=str, help='output file in ssd extension')

args = parser.parse_args()

i = args.input
o = args.output

dssp_to_ssd(i,o)
