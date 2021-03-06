source 'http://rubygems.org'
source 'http://gems.github.com'

gem "rails", "2.3.11"

# Warehouse builder
gem "log4r"
gem "db-charmer"
# 1.1 activated by rails
#gem "rack", "~>1.2"

gem "aasm", "2.1.5"
gem "acts_as_audited"
gem "ar-extensions"
gem "configatron"
gem "curb"
gem "fastercsv", "~>1.4.0"
gem "formtastic", "1.1.0"
gem "mysql"
gem "spreadsheet"
gem "will_paginate"
gem 'net-ldap'

# This was once a plugin, now it's a gem:
gem 'catch_cookie_exception', :git => 'http://github.com/mhartl/catch_cookie_exception.git'

# The graph library (1.x only because 2.x uses Rails 3).  This specific respository fixes an issue
# seen in creating asset links during the assign_tags_handler (which blew up in rewire_crossing in the
# gem code).
gem "acts-as-dag", :git => "http://github.com/mattdenner/acts-as-dag.git", :branch => 'fix_rewire_crossing'

# QC poller / ActiveMQ
gem "activemessaging"
gem "stomp"

# For background processing
gem "delayed_job", '~>2.0.4'

#the most recent one that actually compiles
gem "ruby-oci8", "1.0.7" 
#any newer version requires ruby-oci8 => 2.0.1
gem "activerecord-oracle_enhanced-adapter" , "1.2.3" 

gem "cbrunnkvist-psd_logger"

# For the API level
gem "uuidtools"
gem "sinatra", "~>1.1.0"
gem "rack-acceptable", :require => 'rack/acceptable'
gem "yajl-ruby", :require => 'yajl'

group :development do
  gem "flay"
  gem "flog"
  gem "roodi"
  gem "rcov", :require => false
  #gem "rcov_rails" # gem only for Rails 3, plugin for Rails 2.3 :-/
  # ./script/plugin install http://svn.codahale.com/rails_rcov

  gem "ruby-debug"
  gem "utility_belt"
#  gem 'rack-perftools_profiler', '~> 0.1', :require => 'rack/perftools_profiler'
#  gem 'rbtrace', :require => 'rbtrace'
end

group :test do
  # bundler requires these gems while running tests
  gem "ci_reporter", :git => "http://github.com/sanger/ci_reporter.git"
  gem "factory_girl", '~>1.3.1'
  gem "launchy"
  gem "mocha", :require => false # avoids load order problems
  gem "nokogiri"
  gem "shoulda", "~>2.10.0"
  gem "timecop"
  gem "treetop", "~>1.2.5"
  gem "test-unit", "~>1.2.3", :require => "test/unit"
  gem 'parallel_tests'
end

group :cucumber do
  gem "capybara", '~>0.3.9', :require => false
  gem "cucumber-rails", "~>0.3.2", :require => false
  gem "database_cleaner", :require => false

  # A word of caution: if these are changed from these revisions then features break
  # not because they are wrong but because implementations have changed.  In Cucumber
  # 0.10.x 'table.rows' appears to reverse the columns (i.e. table might say |1|2|3|
  # but you get [3,2,1] in the array).
  gem "cucumber", "~>0.9.2", :require => false
end

group :deployment do
  gem "mongrel_cluster"
end
