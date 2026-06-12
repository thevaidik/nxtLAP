require 'xcodeproj'
project_path = 'NxtLAP.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the motorsports/Views group
main_group = project.main_group
motorsports_group = main_group.children.find { |c| c.path == 'motorsports' || c.name == 'motorsports' }
views_group = motorsports_group.children.find { |c| c.path == 'Views' || c.name == 'Views' }

# Create file reference
file_path = 'motorsports/Views/UpcomingRacesCarouselView.swift'
file_ref = views_group.new_reference(file_path)

# Add to the main app target
target = project.targets.find { |t| t.name == 'NxtLAP' }
target.add_file_references([file_ref])

project.save
puts "Successfully added UpcomingRacesCarouselView.swift to Xcode project!"
