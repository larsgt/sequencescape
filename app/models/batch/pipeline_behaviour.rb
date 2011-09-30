module Batch::PipelineBehaviour
  def self.included(base)
    base.class_eval do
      # The associations with the pipeline
      belongs_to :pipeline
      attr_protected :pipeline_id

      # The validations that the pipeline & batch are correct
      validates_presence_of :pipeline

      # Validation of some of the batch information is left to the pipeline that it belongs to
      validate do |record|
        record.pipeline.validation_of_batch(record) if record.pipeline.present?
      end

      # The batch requires positions on it's requests if the pipeline does
      delegate :requires_position?, :to => :pipeline
    end
  end

  def externally_released?
    workflow.source_is_internal? && self.released?
  end

  def internally_released?
    workflow.source_is_external? && self.released?
  end
  
  def show_actions?
    return true if pipeline.is_a?(PulldownMultiplexLibraryPreparationPipeline) || pipeline.is_a?(CherrypickForPulldownPipeline)
    !released?
  end

  def has_item_limit?
    self.item_limit.present?
  end
  alias_method(:has_limit?, :has_item_limit?)
end
