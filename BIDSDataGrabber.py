"""
BIDSDataGrabber.py
Evan Kersey
03/11/2020

practice bids data grabber and layout
"""
print("init bidsGrabber")
from nipype.interfaces.io import BIDSDataGrabber
from nipype.pipeline import Node, MapNode, Workflow 
from bids.layout import BIDSLayout
from nipype.interfaces.utility import Function

#make the layout
layout = BIDSLayout("/mnt/Filbey/Evan/MJXProcessing/examples/examples/BIDS")
layout.get_subjects
layout.get_modalities()
layout.get_session()
print(layout.get(subject=[], extensions=['.nii'], return_type='file'))

"""
#create first node
#this uses the layout to make a node
bg = Node(BIDSDataGrabber(), name='bids-grabber', layout = layout)
#this defines the root dir
# ToDo fixme

  File "/mnt/Filbey/Evan/MJXProcessing/env/lib/python3.6/site-packages/bids/layout/layout.py", line 460, in _validate_root
    raise ValueError("BIDS root does not exist: %s" % self.root)
ValueError: BIDS root does not exist: /tmp/tmp9g7ddldw/bids-grabber/examples/examples/BIDS



#problem with base_dir  
bg.inputs.base_dir = "/mnt/Filbey/Evan/MJXProcessing/examples/examples/BIDS"

bg.inputs.subject = 'M7500516'
#bg.inputs.output_query = {'T1w': dict(type='anat')}
res = bg.run()
res.outputs
print("done")
"""


def printMe(paths):
    print("\n\nanalyzing " + str(paths) + "\n\n")
    
analyzeANAT = Node(Function(function=printMe, input_names=["paths"],
                            output_names=[]), name="analyzeANAT")

bg_all = Node(BIDSDataGrabber(), name='bids-grabber')
bg_all.inputs.base_dir = '/mnt/Filbey/Evan/MJXProcessing/examples/examples/BIDS'
bg_all.inputs.output_query = {'ses': dict(type='session')}
bg_all.iterables = ('subject', layout.get_subjects()[0])
wf = Workflow(name="bids_demo")
wf.connect(bg_all, "session", analyzeANAT, "paths")
wf.run()


