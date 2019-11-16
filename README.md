# PostPrep
Code to organize fMRIprepped data for further processing in AFNI, SPM, or FSL

For a lot of people, the organization and format of data outputted from fMRIprep serves as an obstacle for buy in. That is, it is hard for people integrate the fmriprep out into the lab data processing pipelines because it is different from the file formats and data organization that they are used to. To this end, PostPrep is set of scripts that converts file formats and changes data organization to what is common for each of the major fMRI software packages -- AFNI, SPM, and FSL. For AFNI users, the AFNI pipeline typically outputs all data belonging to a subject in a single folder, with all imaging data in HEAD/BRIK format, and all motion and timing parameters in text files with the .1D extension. For SPM users, the common data organization includes a subject-level folder that contains a subfolder for each run of a functional scan. Within each subfolder the imaging data are in 3D nifti or img/hdr format, with file (or pair of files) per volume. Motion and timing parameters are either in text files or .mat matlab files. I'm not as familiar with FSL, so I'm not sure if the data really need any reorginization. My guess is that since Stanfords Reproducible Neuroscinece group are fans of FSL, the output from fMRIprep fits what FSL typically wants. 

So far, I've created a couple of scripts for my lab. PostPrep.sh is a bash script that currently only converts everything to AFNI-style. I'd like to expand this to have flags for AFNI, SPM, or FSL. The accompanying ExtractRegressors.R script is called by PostPrep.sh and is an R script that takes *confounds_regressors.tsv* from fMRIprep, which outputs AFNI-style .1D motion files. 

What I'd like to do:

1) Expand this to have a flag that outputs SPM-style format/organization (which I have an idea of how to accomplish). For this goal, I'd like someone who is familiar with SPM so that they have an idea of what the output should look like.

2) Expand this to have a flag that outputs FSL-style format/organization (which I don't have an idea of how to accomplish). For this goal, I'd like someone who is familiar with FSL so that they have an idea of what the output should look like.

3) Have better code commenting and documentation so that it is easier to read, use, and hack if need be. A full manual would be great, as well as having line-by-line commenting so that the code is something that can be used by relative new users. 

4) I'd like to develop this all in bash and R, but I'm not completely tied to this idea! Python users are totally welcome, but I'm not the best at Python. I do want to keep this in the minimal number of programming languages as possible to reduce environment, version, and compatibility issues. 

5) I'd like hack partners that are willing to test this code and try to break it, so that we have an idea of its weaknesses, and what needs work. 

6) Make it more flexible, so that it can better suit the needs of all users.
