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
  project.build_configuration_list.build_configurations << new_config


  puts "Successfully created configuration '#{config_name}'"
end

# Save the project
project.save

# ---- Modify Podfile ----
podfile_path = 'ios/Podfile'
podfile_content = File.read(podfile_path)

# Set platform version
podfile_content.gsub!(/# platform :ios, '11.0'/, "platform :ios, '13.0'")

# Define the new post_install block
new_post_install_block = <<-BLOCK
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '5.0'
    end
  end
end
BLOCK

# Replace the existing post_install block
podfile_content.gsub!(/post_install do \|installer\|.*?end/m, new_post_install_block)

# Write the changes back to the Podfile
File.write(podfile_path, podfile_content)
puts "Successfully modified Podfile with platform and Swift version."
