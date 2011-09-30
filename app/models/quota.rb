class Quota < ActiveRecord::Base
  include Uuid::Uuidable

  belongs_to :project
  belongs_to :request_type

  acts_as_audited :on => [:destroy, :update]

  named_scope :request_type, lambda {|*args| {:conditions => { :request_type_id => args[0]} } }
end
