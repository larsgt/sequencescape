class RemoveBatchDuplicates < ActiveRecord::Migration
  def self.up
    requests = Request.find_by_sql <<SQL
select requests.* from requests, 
                   (select request_id, count(batch_id) cnt 
                    from batch_requests group by request_id) a
where a.cnt > 1 and requests.id=a.request_id
SQL
    ActiveRecord::Base.transaction do
      # Various data fixes
      r = Request.find(578576)
      md = r.request_metadata
      md.read_length = 50
      md.save!

      requests.each do |request|
        # Missing batch
        say "Request #{request.id}"
        request.split_from_batches
      end
      execute "ALTER TABLE batch_requests ADD UNIQUE (request_id)"
    end
  end

  def self.down
  end
end
