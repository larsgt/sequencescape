class StudySample < ActiveRecord::Base
  include Uuid::Uuidable

  belongs_to :study
  belongs_to :sample
  acts_as_audited :on => [:destroy, :update]

  validates_uniqueness_of :sample_id, :scope => [:study_id], :message => "cannot be added to the same study more than once" 
end
