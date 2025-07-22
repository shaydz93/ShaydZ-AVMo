#!/bin/bash

# List of Swift files to check and update
FILES=(
  "/workspaces/ShaydZ-AVMo/ShaydZ-AVMo/ViewModels/AppLibraryViewModel.swift"
  "/workspaces/ShaydZ-AVMo/ShaydZ-AVMo/Services/AppCatalogService.swift"
  "/workspaces/ShaydZ-AVMo/ShaydZ-AVMo/Services/AuthenticationService.swift"
  "/workspaces/ShaydZ-AVMo/ShaydZ-AVMo/Services/VirtualMachineService.swift"
)

# For each file, check if it imports the Models module and add if missing
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    # Check if the file needs to import Models
    if ! grep -q "import Models" "$file"; then
      # Add the import after Foundation import
      sed -i '1,/import Foundation/ s/import Foundation/import Foundation\nimport Models/' "$file"
      echo "Added Models import to $file"
    else
      echo "Models already imported in $file"
    fi
  else
    echo "File not found: $file"
  fi
done

echo "Import updates completed!"
