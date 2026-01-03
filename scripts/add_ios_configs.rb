require 'xcodeproj'

# Path to your Xcode project
project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# The name of the configuration to duplicate
source_config_name = 'Release'

# Find the source configuration
source_config = project.build_configurations.find { |c| c.name == source_config_name }

unless source_config
  puts "Configuration '#{source_config_name}' not found."
  exit 1
end

# Configurations to create
configs_to_create = ['Release-nightly', 'Release-stable']

configs_to_create.each do |config_name|
  # Skip if the configuration already exists
  if project.build_configurations.any? { |c| c.name == config_name }
    puts "Configuration '#{config_name}' already exists. Skipping."
    next
  end

  # Create a new configuration by duplicating the source
  new_config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
  new_config.name = config_name
  new_config.build_settings = source_config.build_settings.clone
  project.projects.first.build_configuration_list.build_configurations << new_config


  puts "Successfully created configuration '#{config_name}'"
end

# Save the project
project.save
