#!/usr/bin/env python
"""
Evan Kersey
3/13/2020
input and output sink created sucessfully
sandwich node in between
"""

from os.path import join as opj

from nipype import Node, Workflow, IdentityInterface
from nipype.interfaces.freesurfer import ReconAll
from nipype.interfaces.io import SelectFiles, DataSink

# First, let's specify the list of subjects
subject_list = ['M75005160']  # what subjects are to be run
sessionIterator = ['01']  # what session numbers are checked

# create identity interface node
infosource = Node(IdentityInterface(fields=['subject_id']),
                  name="infosource")
infosource.iterables = [('subject_id', subject_list,)]

# get the anat file for every session for the subject
for session in sessionIterator:
    anat_file = opj('sub-{subject_id}', 'ses-' + session, 'anat', 'sub-{subject_id}_ses-' + session + '_T1w.nii')

templates = {'anat': anat_file}

selectfiles = Node(SelectFiles(templates, base_directory='/mnt/Filbey/Evan/examples/BIDS'), name="selectfiles")

# Datasink - creates output folder for important outputs
datasink = Node(DataSink(base_directory="/mnt/Filbey/Evan/tmp/sinker",
                         container="datasink"),
                name="datasink")

# reconAll node
recon_all = Node(ReconAll(), name="reconAll")

wf_sub = Workflow(name="choosing_subjects")

wf_sub.connect(infosource, "subject_id", selectfiles, "subject_id")
wf_sub.connect(selectfiles, "anat", datasink, "anat_files")
wf_sub.connect(selectfiles, "anat", recon_all, 'input.inputspec.T1_files')
wf_sub.connect(infosource, "subject_id", recon_all, 'input.inputspec.subject_id')
wf_sub.run()
