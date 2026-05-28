require 'rubygems'
require 'xcodeproj'

project_path = 'NxtLAP.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'NxtLAP' }

files_to_add = [
  'motorsports/Models/FantasyCardModels.swift',
  'motorsports/ViewModels/FantasyEconomyViewModel.swift',
  'motorsports/Views/FantasyDashboardView.swift',
  'motorsports/Views/CardMarketView.swift',
  'motorsports/Views/MyGarageView.swift'
]

files_to_add.each do |file_path|
  # Create groups if they don't exist
  dir = File.dirname(file_path)
  group = project.main_group
  dir.split('/').each do |folder|
    group = group.groups.find { |g| g.path == folder || g.name == folder } || group.new_group(folder, folder)
  end
  
  # Add file reference
  file_ref = group.files.find { |f| f.path == File.basename(file_path) } || group.new_file(File.basename(file_path))
  
  # Add to target
  unless target.source_build_phase.files_references.include?(file_ref)
    target.add_file_references([file_ref])
    puts "Added #{file_path} to target"
  end
end

project.save
puts "Project saved successfully!"
