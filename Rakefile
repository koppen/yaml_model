task :default => 'ym:test'

namespace :ym do
  desc "Runs the YamlModel test suite"
  task :test do
    system("../../../script/rails runner ./test/yaml_model_test.rb")
  end
end
