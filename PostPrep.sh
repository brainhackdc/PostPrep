#!/bin/bash
#
################################################################################
# This script does everything that needs to be done after fmriprep
# to get it ready to model in AFNI:
#
# 1) converts the preprocessed, MNI_2009 normalized and AROMA BOLD data to AFNI
#    brik/head format.
# 2) scales the preprocessed BOLD images so that they activations can be
#    interpreted as percent signal change.
# 3) Multiplies the preprocessed, scaled data by the brain mask to remove out of
#    brain data.
# 4) extracts the 3 rotation, 3 translation, 1mm censor data, and framewise-
#    displacement values for each volume to be used as nuissance regressors.
#
# Note: Our censor criteria is 1 mm FD
#
# To use this script, you must modify the PARAMETERS section to match your study
# and can run as is. There are one of three ways to define which subjects you
# want to run this script on: 1) define the subjects in the parameters section;
# 2) give the subject id as input to the script, e.g. ./PostPrep.sh sub-JAM012 ;
# 3) or you can leave the subject parameter blank and not feed an id as input,
#   in which case it will perform these operations to all the subjects in the
#   fMRIprep folder! #Flexibility
#
################################################################################
##### PARAMETERS - CHANGE THESE TO MEET THE NEEDS OF YOUR STUDY ################
#
# First define fMRIprep superlevel directory ###################################
PrepDir="/Users/Junaid/Desktop/BIDS-fMRIprep"
#
# Second define the bold files that you want to perform these operations on ####
FuncName=("cmnt_run-01" "cmnt_run-02" "cmnt_run-03" "cmnt_run-04")
#
# Third define path to accompanying regressor extracting R script. This was too
# hard to do in bash, so I created R script to handle this part. Sloppy I know!
ExtractR="/Users/Junaid/Desktop/DSCNcode/ExtractRegressors.R"
#
# Fourth define template space of the data you want to perform these operations
# on, but make sure that it matches exactly how fmriprep labels it. Any typos
# will crash this. You can include more than one template space if you have it!
Template=("MNI152NLin2009cAsym")
# Finally define the subject IDs for which you want to run this script on. See
# above about the three ways you can define subjects. Easisest would be to
# define the subjects below. If you leave the below blank, then you can feed
# a subject ID in as an input. If you don't do that, then this will run on all
# the subjects in the PrepDir defined above!
SubID=("sub-REDCMNT137")
#
##### END OF PARAMETERS SECTION - DON'T MESS WITH THE STUFF BELOW #############
################################################################################
#
#
#
#
ErrorMessage="This script does everything that needs to be done after fmriprep \
to get it ready to model in AFNI, but needs the following:"
#
# Check to see if PrepDir has been assigned
if [ -z $PrepDir ] || [ -z $FuncName ] || [ -z $ExtractR ] ; then
	echo ""
	echo $ErrorMessage
	echo ""
	#
	if [ -z $PrepDir ] ; then
		echo "Need to define path to fmriprep directory"
		echo ""
		exit;
	fi
	#
	if [ -z $FuncName ] ; then
		echo "Need to define bold files"
		echo ""
		exit;
	fi
	#
	if [ -z $ExtractR ] ; then
		echo "Need to define bold files"
		echo ""
		exit;
	fi
	#
fi
#
#
#
if [ ! -z $SubID ]; then
	echo ""
	echo "Subject defined:"
	echo ""
else
	# If not, then check to see if a SubID was fed into the script as an option
	if [ $# -eq 1 ]; then
		SubID=$1
		echo ""
		echo "Subject defined:"
		echo ""
	fi
	# If no SubID was defined in the script, and there wasn't one fed as an option
	# search the PrepDir for subjects
	if [ -z $SubID ] && [ $# -ne 1 ]; then
		SubID=($(ls -d ${PrepDir}/sub*/))
		if [ -z $SubID ]; then
			echo ""
			echo $ErrorMessage
			echo ""
			echo "you've not defined SubID in the script, as an input, nor are there any subjects in the PrepDir"
			echo ""
			exit;
		else
			echo ""
			echo "Subject defined:"
			echo ""
		fi
	fi
fi
#
#
# Now that the checks are out of the way, let's look start copy/converting to
# appropriately names brik/head files.
#
# 1-3) Convert appropriate files to Brik/Head, scale the data, and create a
# brain masked version of the scaled data all in one loop
# Loop through the subjects
for sub in ${SubID[@]}; do
	#
	echo "------------------------------------------------------------------"
	echo Running PostPrep on ${sub}
	echo ""
	date
	echo "------------------------------------------------------------------"
	# Make the afni dir if there isn't one yet
	if [ ! -d ${PrepDir}/${sub}/afni ]; then
		mkdir ${PrepDir}/${sub}/afni
	fi
	#
	for temp in ${Template[@]}; do
	#
	# Copy over the relevant normalized structural if it hasn't been yet
	if [ ! -f ${PrepDir}/${sub}/afni/${sub}_space-${temp}_desc-preproc_T1w+tlrc.BRIK ]; then
		3dcopy ${PrepDir}/${sub}/anat/${sub}_space-${temp}_desc-preproc_T1w.nii.gz ${PrepDir}/${sub}/afni/${sub}_space-${temp}_desc-preproc_T1w+tlrc
	fi
		# Loop through the different functional files
		for fun in ${FuncName[@]}; do
			#
			# Starting first with the preprocessed function: 1) convert to brik/head,
			if [ ! -f ${PrepDir}/${sub}/afni/${sub}_${temp}_preproc_${fun}+tlrc.BRIK ]; then
				3dcopy ${PrepDir}/${sub}/func/${sub}_task-${fun}_space-${temp}_desc-preproc_bold.nii.gz ${PrepDir}/${sub}/afni/${sub}_${temp}_preproc_${fun}
				# 2) calculate the voxel-level mean, 3) scale to the mean
				3dTstat -prefix ${PrepDir}/${sub}/afni/${sub}_${temp}_mean-preproc_${fun}+tlrc ${PrepDir}/${sub}/afni/${sub}_${temp}_preproc_${fun}+tlrc
				# 3) scale to the mean
				3dcalc -a ${PrepDir}/${sub}/afni/${sub}_${temp}_preproc_${fun}+tlrc -b ${PrepDir}/${sub}/afni/${sub}_${temp}_mean-preproc_${fun}+tlrc \
				-expr 'min(200, a/b*100)*step(a)*step(b)' \
				-prefix ${PrepDir}/${sub}/afni/${sub}_${temp}_scaled-preproc_${fun}+tlrc
				# Clean up mean image
				rm -f ${PrepDir}/${sub}/afni/${sub}_${temp}_mean-preproc_${fun}+tlrc*
				#
				# Now copy over the brain mask into brik/head format
				3dcopy ${PrepDir}/${sub}/func/${sub}_task-${fun}_space-${temp}_desc-brain_mask.nii.gz ${PrepDir}/${sub}/afni/${sub}_${temp}_brainmask_${fun}
				#
				# Finally copy over the AROMAe'd data and scale like before
				3dcopy ${PrepDir}/${sub}/func/${sub}_task-${fun}_space-${temp}_desc-smoothAROMAnonaggr_bold.nii.gz ${PrepDir}/${sub}/afni/${sub}_${temp}_aroma_${fun}
				3dTstat -prefix ${PrepDir}/${sub}/afni/${sub}_${temp}_mean-aroma_${fun}+tlrc ${PrepDir}/${sub}/afni/${sub}_${temp}_aroma_${fun}+tlrc
				3dcalc -a ${PrepDir}/${sub}/afni/${sub}_${temp}_aroma_${fun}+tlrc -b ${PrepDir}/${sub}/afni/${sub}_${temp}_mean-aroma_${fun}+tlrc \
				-expr 'min(200, a/b*100)*step(a)*step(b)' \
				-prefix ${PrepDir}/${sub}/afni/${sub}_${temp}_scaled-aroma_${fun}+tlrc
				rm -f ${PrepDir}/${sub}/afni/${sub}_${temp}_mean-aroma_${fun}+tlrc*
				#
				#
				#
				# Now mask the scaled images. First have to rescale mask
				# First, the aroma, which has different dimensions, so needs to be rescaled
				3dresample -master ${PrepDir}/${sub}/afni/${sub}_${temp}_scaled-aroma_${fun}+tlrc -prefix ${PrepDir}/${sub}/afni/TempMask -input ${PrepDir}/${sub}/afni/${sub}_${temp}_brainmask_${fun}+tlrc
				3dcalc -a ${PrepDir}/${sub}/afni/TempMask+tlrc -b ${PrepDir}/${sub}/afni/${sub}_${temp}_scaled-aroma_${fun}+tlrc -expr 'a*b' -prefix ${PrepDir}/${sub}/afni/${sub}_${temp}_masked-scaled-aroma_${fun}
				rm -f ${PrepDir}/${sub}/afni/TempMask+tlrc*
				#
				# Then the preproc, which doesn't need scaling
				3dcalc -a ${PrepDir}/${sub}/afni/${sub}_${temp}_scaled-preproc_${fun}+tlrc -b ${PrepDir}/${sub}/afni/${sub}_${temp}_brainmask_${fun}+tlrc -expr 'a*b' -prefix ${PrepDir}/${sub}/afni/${sub}_${temp}_masked-scaled-preproc_${fun}
				#
			fi
			# Now convert the confound regressors file to afni compatible
			if [ -f ${PrepDir}/${sub}/afni/${sub}-${fun}-MotionSummary.csv ]; then
				echo "Looks like motion extraction has already occurred"
			else
				Rscript $ExtractR ${PrepDir}/${sub}/func/${sub}_task-${fun}_desc-confounds_regressors.tsv ${PrepDir}/${sub}/afni 1
			fi
		done
	done
done
#
