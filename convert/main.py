from nipype import Workflow, Node
from nipype.interfaces.freesurfer import ReconAll
from nipype import Workflow, Node
from nipype.interfaces.freesurfer import ReconAll
import Subject

out_path = "/home/evan/Filbey/Evan/BIDS"

"""
test_subject = Subject("/home/evan/Filbey/common/Studies/MJXProcessing/examples/NL/sub-1126", out_path, "/home/evan/Filbey/Evan")

#convert dicom to nifti
test_subject.get_seqs()
test_subject.to_bids(out_path)
"""
# create array of subject objects with path to raw data

subjectList = [Subject]  # Subject
# includes pointers to bids format data and a to_bids function


# recon all freesurfer - build commamd

for subject in subjectList:
    # initialize reconAll interface
    reconall = ReconAll()
    # add various attributes to the interface
    reconall.inputs.subject_id = subject.subjectID
    reconall.inputs.directive = 'foo'
    reconall.inputs.subjects_dir = subject.bidsPath
    reconall.inputs.T1_files = subject.seqs.anat
    # execute the command in shell with above attributes
    #todo
    #check if output exists prior to execution or catch error from command line
    reconall.cmdline

# add recon-all & ants to subject object

# need to add new attributes to subject class. subclass? add to existing? what is "pythonic"? how do I enforce order in
# processing and handle process failure or error? could try hashing the output prior to running the command. this
# checks if the object exists. shell script may have the check already but the goal is to not reprocess anything.


# pulls from bids


