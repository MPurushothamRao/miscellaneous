# change dssp executable path and required force field and use python3 martinize.py -h for help
#python3 martinize.py -f 1UBQ.pdb -o single-ubq.top -x 1UBQ-CG.pdb -dssp /usr/local/bin/mkdssp -p backbone -ff martini22
#or use this edit python script according to naming of files
mkdssp -i 1UBQ.pdb -o 1UBQ.dssp
python3 dssp2ssd.py -i 1UBQ.dssp -o 1UBQ.ssd
python martinize.py -f 1UBQ.pdb -o single-ubq.top -x 1UBQ-CG.pdb -ss 1UBQ.ssd -p backbone -ff martini22
# to change name martini itp in toplogy 
sed -i -e 's/martini\.itp/martini_v2.2.itp/' single-ubq.top
# to setup box
gmx editconf -f 1UBQ-CG.pdb -o box.gro -d 1.0 -c -bt dodecahedron
# to minimise the coarse_grained structure in vaccum
gmx grompp -f em_vac.mdp -c box.gro -p single-ubq.top -o em_vac.tpr
gmx mdrun -deffnm em_vac -v
# solvate the protein
gmx solvate -cp em_vac.gro -cs water.gro -radius 0.21 -o solvated.gro
cp single-ubq.top system.top
count=$(grep -c "W" solvated.gro | tr -d '\n')
#polarised water divide it by 3 
echo -e "\nW    $count" >> system.top
#to add ions
gmx grompp -f ions.mdp -c solvated.gro -p system.top -o ions.tpr
echo 13 | gmx genion -s ions.tpr -o ions.gro -p system.top -pname NA+ -nname CL- -neutral
# make new index file to group solvate and ions into one solvent change according to requirement
#gmx make_ndx -f solvated.gro -o index.ndx < index.txt
#minimisation
gmx grompp -f em.mdp -c solvated.gro -r solvated.gro -p system.top -o em.tpr -maxwarn 1
gmx mdrun -deffnm em -v
# nvt equilibration
gmx grompp -f nvt.mdp -c em.gro -r em.gro -p system.top -o nvt.tpr
gmx mdrun -deffnm nvt -v
#npt equilibration
gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro  -p system.top -o npt.tpr
gmx mdrun -deffnm npt -v
#md run
gmx grompp -f md.mdp -c npt.gro -p system.top -o md.tpr
gmx mdrun -deffnm md -v
#analysis
echo 1 1 | gmx trjconv -f md.gro -s md.tpr -o recentered_traj.gro -pbc mol -center
echo 1 | gmx trjconv -f recentered_traj.gro -s md.tpr -conect -o connected_traj.pdb
echo 1 1 | gmx trjconv -f md.xtc -s md.tpr -o recentered_traj.xtc -pbc mol -center
sed -i '/ENDMDL/d' connected_traj.pdb
echo 1 1 | gmx rms -s md.tpr -f recentered_traj.xtc -o rmsd.xvg
echo 1 | gmx gyrate -s md.tpr -f recentered_traj.xtc -o gyrate.xvg
# to visualise
vmd recentered_traj.xtc connected_traj.pdb
