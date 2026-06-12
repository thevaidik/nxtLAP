import sys

file_path = "NxtLAP.xcodeproj/project.pbxproj"

with open(file_path, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if "RevenueCat" in line:
        continue
    new_lines.append(line)

with open(file_path, 'w') as f:
    f.writelines(new_lines)

print("Removed all RevenueCat dependencies from project.pbxproj!")
