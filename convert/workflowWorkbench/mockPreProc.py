import nipype.pipeline.engine as pe
from nipype import Node, JoinNode, Workflow
from nipype.interfaces.utility import IdentityInterface
from nipype.interfaces import (ants, dcm2nii, fsl)

#make workflow object
wf = Workflow(name='preprocess')
#infospec is a node that makes a subject identity. identity matrix is what Subject.py was trying to acomplish
inputspec = Node(IdentityInterface(fields=['image']),
                    name='inputspec')
#these look like the images that will be processed in this node. Subject.seq might work here
inputspec.iterables = [('image',
                       ['img1.nii', 'img2.nii', 'img3.nii'])]
#not sure what this is, applys img2flt (?) need to ask Ryan
img2flt = Node(fsl.ImageMaths(out_data_type='float'),
                  name='img2flt')
#connects the first node with the second node
wf.connect(inputspec, 'image', img2flt, 'in_file')
#3rd node
average = JoinNode(ants.AverageImages(), joinsource='inputspec',
                      joinfield='images', name='average')
#add new node to wf
wf.connect(img2flt, 'out_file', average, 'images')
#new node
realign = Node(fsl.FLIRT(), name='realign')
#add to wf after img2flt & after average
wf.connect(img2flt, 'out_file', realign, 'in_file')
wf.connect(average, 'output_average_image', realign, 'reference')
strip = Node(fsl.BET(), name='strip')
wf.connect(realign, 'out_file', strip, 'in_file')