bg_all = Node(BIDSDataGrabber(), name='bids-grabber')
bg_all.inputs.base_dir = '/mnt/Filbey/Evan/MJXProcessing/examples/examples/BIDS'
bg_all.inputs.output_query = {'ses': dict(type='session')}

bg_all.iterables = ('subject', layout.get_subjects())
bg.run
