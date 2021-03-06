require 'test_helper'

class SequencingPipelineTest < ActiveSupport::TestCase
  def assert_comment_exists(commentable, matcher, message)
    assert_not_nil(commentable.comments.detect { |c| c.description =~ matcher }, message)
  end

  context 'SequencingPipeline' do
    setup do
      @pipeline = SequencingPipeline.new(
        :workflow     => LabInterface::Workflow.new,
        :request_type => RequestType.new
      )
    end

    context '#detach_request_from_batch' do
      should 'clone the request and add appropriate comments' do
        batch, request = @pipeline.batches.build, @pipeline.request_type.new

        clone = @pipeline.detach_request_from_batch(batch, request)
        assert_equal('pending', clone.state)
        assert_nil(clone.target_asset, 'Target asset is not nil')
        assert_comment_exists(clone,   /removed from batch #{batch.id}/i, 'Cannot find removal comment')
        assert_comment_exists(clone,   /clone of request #{request.id}/i, 'Cannot find clone comment')
        assert_comment_exists(request, /request #{clone.id} is/i,         'Cannot find source comment')
      end
    end
  end
end
