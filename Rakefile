require "bundler/gem_tasks"
import 'lib/sequel/tasks/test.rake'
import 'lib/sequel/tasks/reset.rake'

task :default do 
  system %Q{bundle exec rspec --exclude-pattern="spec/**/*database_manager_spec.rb"}
end
  


