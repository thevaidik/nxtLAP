require 'rubygems'
require 'xcodeproj'

project_path = 'NxtLAP.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'NxtLAP' }

# Find the file reference
file_path = 'motorsports/ViewModels/FantasyEconomyViewModel.swift'
file_basename = File.basename(file_path)

file_ref = project.files.find { |f| f.path == file_basename || f.path == file_path }

if file_ref
  # Remove from target build phases
  target.source_build_phase.remove_file_reference(file_ref)
  # Remove from project group
  file_ref.remove_from_project
  project.save
  puts "Successfully removed #{file_path} from Xcode project."
else
  puts "Could not find file reference for #{file_path}."
end
