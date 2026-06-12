require 'xcodeproj'
project_path = 'NxtLAP.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'NxtLAP' }

pkg_url = "https://github.com/RevenueCat/purchases-ios-spm.git"
pkg_ref = project.root_object.add_swift_package_reference(pkg_url, "upToNextMajorVersion", "5.0.0")

rc_framework = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
rc_framework.product_name = "RevenueCat"
rc_framework.package = pkg_ref
target.package_product_dependencies << rc_framework

rcui_framework = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
rcui_framework.product_name = "RevenueCatUI"
rcui_framework.package = pkg_ref
target.package_product_dependencies << rcui_framework

project.save
puts "Successfully added RevenueCat & RevenueCatUI to Xcode project!"
