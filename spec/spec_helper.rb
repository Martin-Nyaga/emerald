require "emerald"

RSpec.configure do |config|
  # Rspec 4 defaults
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Verbose output when running single tests
  config.default_formatter = "doc" if config.files_to_run.one?

  # :focus and fit/fdescribe/fcontext
  config.filter_run_when_matching :focus

  # support `--only-failures` and `--next-failure`
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Random order with overridable seed
  config.order = :random
  Kernel.srand config.seed
end
