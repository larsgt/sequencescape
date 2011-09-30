##################################################################################################################
# Submission workflows and their associated pipelines.
##################################################################################################################
# There is a common pattern to create a Submission::Workflow and it's supporting entities.  You can pretty much copy
# this structure and replace the appropriate values:
#
#   submission_workflow = Submission::Workflow.create! do |workflow|
#     # Update workflow attributes here
#   end
#   LabInterface::Workflow.create!(:name => XXXX) do |workflow|
#     workflow.pipeline = PipelineClass.create!(:name => XXXX) do |pipeline|
#       # Set the Pipeline attributes here
#
#       pipeline.location = Location.first(:conditions => { :name => YYYY }) or raise StandardError, "Cannot find 'YYYY' location'
#       pipeline.request_type = RequestType.create!(:workflow => submission_workflow, :key => xxxx, :name => XXXX) do |request_type|
#         # Set the RequestType attributes here
#       end
#     end
#   end.tap do |workflow|
#     # Setup tasks for your LabInterface::Workflow here
#   end
#
# That should be enough for you to work out what you need to do.

# Utility method for getting a sequence of Pipeline instances to flow properly.  Call with a Hash mapping the
# flow from left to right, if you get what I mean!
def set_pipeline_flow_to(sequence)
  sequence.each do |current_name, next_name|
    current_pipeline, next_pipeline = [ current_name, next_name ].map { |name| Pipeline.first(:conditions => { :name => name }) or raise "Cannot find pipeline '#{ name }'" }
    current_pipeline.update_attribute(:next_pipeline_id, next_pipeline.id)
    next_pipeline.update_attribute(:previous_pipeline_id, current_pipeline.id)
  end
end

locations_data = [
  'Library creation freezer',
  'Cluster formation freezer',
  'Sample logistics freezer',
  'Genotyping freezer',
  'Pulldown freezer',
  'PacBio sample prep freezer',
  'PacBio sequencing freezer'
]
Location.import [ :name ], locations_data, :validate => false


##################################################################################################################
# Next-gen sequencing
##################################################################################################################
next_gen_sequencing = Submission::Workflow.create! do |workflow|
  workflow.key        = 'short_read_sequencing'
  workflow.name       = 'Next-gen sequencing'
  workflow.item_label = 'library'
end

LibraryCreationPipeline.create!(:name => 'Library preparation') do |pipeline|
  pipeline.asset_type = 'LibraryTube'
  pipeline.sorter     = 0
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Library creation freezer' }) or raise StandardError, "Cannot find 'Library creation freezer' location"

  pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'library_creation', :name => 'Library creation') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class_name = LibraryCreationRequest.name
  end

end

LibraryCreationPipeline.create!(:name => 'MX Library Preparation [NEW]') do |pipeline|
  pipeline.asset_type          = 'LibraryTube'
  pipeline.sorter              = 0
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.group_by_submission = true
  pipeline.multiplexed         = true

  pipeline.location = Location.first(:conditions => { :name => 'Library creation freezer' }) or raise StandardError, "Cannot find 'Library creation freezer' location"
  pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'multiplexed_library_creation', :name => 'Multiplexed library creation') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class     = MultiplexedLibraryCreationRequest
    request_type.for_multiplexing  = true
  end

end

PulldownLibraryCreationPipeline.create!(:name => 'Pulldown library preparation') do |pipeline|
  pipeline.asset_type = 'LibraryTube'
  pipeline.sorter     = 12
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Library creation freezer' }) or raise StandardError, "Cannot find 'Library creation freezer' location"

  pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'pulldown_library_creation', :name => 'Pulldown library creation') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class = LibraryCreationRequest
  end
end

cluster_formation_se_request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'single_ended_sequencing', :name => 'Single ended sequencing') do |request_type|
  request_type.initial_state     = 'pending'
  request_type.asset_type        = 'LibraryTube'
  request_type.order             = 2
  request_type.multiples_allowed = true
  request_type.request_class =  SequencingRequest
end

SequencingPipeline.create!(:name => 'Cluster formation SE (spiked in controls)', :request_type => cluster_formation_se_request_type) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"
end

SequencingPipeline.create!(:name => 'Cluster formation SE', :request_type => cluster_formation_se_request_type) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"
end

SequencingPipeline.create!(:name => 'Cluster formation SE (no controls)', :request_type => cluster_formation_se_request_type) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"
end

single_ended_hi_seq_sequencing = RequestType.create!(:workflow => next_gen_sequencing, :key => 'single_ended_hi_seq_sequencing', :name => 'Single ended hi seq sequencing') do |request_type|
  request_type.initial_state     = 'pending'
  request_type.asset_type        = 'LibraryTube'
  request_type.order             = 2
  request_type.multiples_allowed = true
  request_type.request_class =  HiSeqSequencingRequest
end

SequencingPipeline.create!(:name => 'Cluster formation SE HiSeq', :request_type => single_ended_hi_seq_sequencing) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"
end

SequencingPipeline.create!(:name => 'Cluster formation SE HiSeq (no controls)', :request_type => single_ended_hi_seq_sequencing) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 2
  pipeline.automated  = false
  pipeline.active     = true

  pipeline.location = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"
end 

cluster_formation_pe_request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'paired_end_sequencing', :name => 'Paired end sequencing') do |request_type|
  request_type.initial_state     = 'pending'
  request_type.asset_type        = 'LibraryTube'
  request_type.order             = 2
  request_type.multiples_allowed = true
  request_type.request_class =  SequencingRequest
end

SequencingPipeline.create!(:name => 'Cluster formation PE', :request_type => cluster_formation_pe_request_type) do |pipeline|
  pipeline.asset_type = 'Lane'
  pipeline.sorter     = 3
  pipeline.automated  = false
  pipeline.active     = true
  pipeline.location   = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"
end

SequencingPipeline.create!(:name => 'Cluster formation PE (no controls)', :request_type => cluster_formation_pe_request_type) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"
end

SequencingPipeline.create!(:name => 'Cluster formation PE (spiked in controls)', :request_type => cluster_formation_pe_request_type) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

end

SequencingPipeline.create!(:name => 'HiSeq Cluster formation PE (spiked in controls)', :request_type => cluster_formation_pe_request_type) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

end

SequencingPipeline.create!(:name => 'Cluster formation SE HiSeq (spiked in controls)', :request_type => cluster_formation_pe_request_type) do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

end

# TODO: This pipeline has been cloned from the 'Cluster formation PE (no controls)'.  Needs checking
SequencingPipeline.create!(:name => 'HiSeq Cluster formation PE (no controls)') do |pipeline|
  pipeline.asset_type      = 'Lane'
  pipeline.sorter          = 8
  pipeline.automated       = false
  pipeline.active          = true
  pipeline.group_by_parent = false
  pipeline.location        = Location.first(:conditions => { :name => 'Cluster formation freezer' }) or raise StandardError, "Cannot find 'Cluster formation freezer' location"

  pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'hiseq_paired_end_sequencing', :name => 'HiSeq Paired end sequencing') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'LibraryTube'
    request_type.order             = 2
    request_type.multiples_allowed = true
    request_type.request_class =  HiSeqSequencingRequest
  end
end

##################################################################################################################
# Microarray genotyping
##################################################################################################################
microarray_genotyping = Submission::Workflow.create! do |workflow|
  workflow.key        = 'microarray_genotyping'
  workflow.name       = 'Microarray genotyping'
  workflow.item_label = 'Run'
end

CherrypickPipeline.create!(:name => 'Cherrypick') do |pipeline|
  pipeline.asset_type          = 'Well'
  pipeline.sorter              = 10
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.group_by_parent     = true
  pipeline.group_by_submission = true

  pipeline.location = Location.first(:conditions => { :name => 'Sample logistics freezer' }) or raise StandardError, "Cannot find 'Sample logistics freezer' location"

  pipeline.request_type = RequestType.create!(:workflow => microarray_genotyping, :key => 'cherrypick', :name => 'Cherrypick') do |request_type|
    request_type.initial_state     = 'blocked'
    request_type.target_asset_type = 'Well'
    request_type.asset_type        = 'Well'
    request_type.order             = 2
    request_type.request_class     = Request
    request_type.multiples_allowed = false
  end
end

CherrypickForPulldownPipeline.create!(:name => 'Cherrypicking for Pulldown') do |pipeline|
  pipeline.asset_type          = 'Well'
  pipeline.sorter              = 13
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.group_by_parent     = true
  pipeline.group_by_submission = true
  pipeline.max_size            = 96

  pipeline.location = Location.first(:conditions => { :name => 'Sample logistics freezer' }) or raise StandardError, "Cannot find 'Sample logistics freezer' location"

  pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'cherrypick_for_pulldown', :name => 'Cherrypicking for Pulldown') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.target_asset_type = 'Well'
    request_type.asset_type        = 'Well'
    request_type.order             = 1
    request_type.request_class     = CherrypickForPulldownRequest
    request_type.multiples_allowed = false
    request_type.for_multiplexing  = false
  end
end

DnaQcPipeline.create!(:name => 'DNA QC') do |pipeline|
  pipeline.sorter              = 9
  pipeline.automated           = false
  pipeline.active              = true
  pipeline.group_by_parent     = true
  pipeline.group_by_submission = true

  pipeline.location = Location.first(:conditions => { :name => 'Sample logistics freezer' }) or raise StandardError, "Cannot find 'Sample logistics freezer' location"

  pipeline.request_type = RequestType.create!(:workflow => microarray_genotyping, :key => 'dna_qc', :name => 'DNA QC') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'Well'
    request_type.order             = 1
    request_type.request_class     = QcRequest
    request_type.multiples_allowed = false
  end
end

GenotypingPipeline.create!(:name => 'Genotyping') do |pipeline|
  pipeline.sorter = 11
  pipeline.automated = false
  pipeline.active = true
  pipeline.group_by_parent = true

  pipeline.location = Location.first(:conditions => { :name => 'Genotyping freezer' }) or raise StandardError, "Cannot find 'Genotyping freezer' location"

  pipeline.request_type = RequestType.create!(:workflow => microarray_genotyping, :key => 'genotyping', :name => 'Genotyping') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'Well'
    request_type.order             = 3
    request_type.request_class     = GenotypingRequest
    request_type.multiples_allowed = false
  end
end

PulldownMultiplexLibraryPreparationPipeline.create!(:name => 'Pulldown Multiplex Library Preparation') do |pipeline|
  pipeline.asset_type           = 'Well'
  pipeline.sorter               = 14
  pipeline.automated            = false
  pipeline.active               = true
  pipeline.group_by_parent      = true
  pipeline.group_by_study       = false
  pipeline.max_size             = 96
  pipeline.max_number_of_groups = 1

  pipeline.location = Location.first(:conditions => { :name => 'Pulldown freezer' }) or raise StandardError, "Cannot find 'Pulldown freezer' location"

  pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'pulldown_multiplexing', :name => 'Pulldown Multiplex Library Preparation') do |request_type|
    request_type.asset_type        = 'Well'
    request_type.target_asset_type = 'PulldownMultiplexedLibraryTube'
    request_type.order             = 1
    request_type.request_class     = PulldownMultiplexedLibraryCreationRequest
    request_type.multiples_allowed = false
    request_type.for_multiplexing  = true
  end
end

set_pipeline_flow_to('Cherrypicking for Pulldown' => 'Pulldown Multiplex Library Preparation')
set_pipeline_flow_to('DNA QC' => 'Cherrypick')

PacBioSamplePrepPipeline.create!(:name => 'PacBio Sample Prep') do |pipeline|
  pipeline.sorter               = 14
  pipeline.automated            = false
  pipeline.active               = true
  pipeline.asset_type           = 'PacBioLibraryTube'

  pipeline.location = Location.first(:conditions => { :name => 'PacBio sample prep freezer' }) or raise StandardError, "Cannot find 'PacBio sample prep freezer' location"

  pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'pacbio_sample_prep', :name => 'PacBio Sample Prep') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'SampleTube'
    request_type.order             = 1
    request_type.multiples_allowed = false
    request_type.request_class = PacBioSamplePrepRequest
  end
end

PacBioSequencingPipeline.create!(:name => 'PacBio Sequencing') do |pipeline|
  pipeline.sorter               = 14
  pipeline.automated            = false
  pipeline.active               = true
  pipeline.max_size             = 96
  pipeline.asset_type           = 'Well'
  pipeline.group_by_parent = false
  pipeline.group_by_submission = true

  pipeline.location = Location.first(:conditions => { :name => 'PacBio sequencing freezer' }) or raise StandardError, "Cannot find 'PacBio sequencing freezer' location"

  pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :key => 'pacbio_sequencing', :name => 'PacBio Sequencing') do |request_type|
    request_type.initial_state     = 'pending'
    request_type.asset_type        = 'PacBioLibraryTube'
    request_type.order             = 1
    request_type.multiples_allowed = true
    request_type.request_class     = PacBioSequencingRequest
  end
end
set_pipeline_flow_to('PacBio Sample Prep' => 'PacBio Sequencing')

# Pulldown pipelines
[
  'WGS',
  'SC',
  'ISC'
].each do |pipeline_type|
  pipeline_name = "Pulldown #{pipeline_type}"
  Pipeline.create!(:name => pipeline_name) do |pipeline|
    pipeline.sorter             = Pipeline.maximum(:sorter) + 1
    pipeline.automated          = false
    pipeline.active             = true
    pipeline.asset_type         = 'LibraryTube'
    pipeline.externally_managed = true

    pipeline.location   = Location.find_by_name('Pulldown freezer') or raise StandardError, "Pulldown freezer does not appear to exist!"

    pipeline.request_type = RequestType.create!(:workflow => next_gen_sequencing, :name => pipeline_name) do |request_type|
      request_type.key               = pipeline_name.downcase.gsub(/\s+/, '_')
      request_type.initial_state     = 'pending'
      request_type.asset_type        = 'Well'
      request_type.target_asset_type = 'MultiplexedLibraryTube'
      request_type.order             = 1
      request_type.multiples_allowed = false
      request_type.request_class     = "Pulldown::Requests::#{pipeline_type.humanize}LibraryRequest".constantize
      request_type.for_multiplexing  = true
    end

  end
end
