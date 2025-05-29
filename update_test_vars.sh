#!/bin/sh
# Update test variable names to use TEST_ prefix

# List of files to update (exclude already fixed files)
find tests -name "*.test.sh" | grep -v test_deinit_modes.test.sh > test_files.txt

# Variables to replace
while read -r test_file; do
  echo "Processing $test_file"
  
  # Use word boundaries to ensure we only replace the variables, not substrings
  sed -i 's/\<LOCAL_DIR\>/TEST_LOCAL_DIR/g' "$test_file"
  sed -i 's/\<SHARED_DIR\>/TEST_SHARED_DIR/g' "$test_file"
  sed -i 's/\<LOCAL_MANIFEST_FILE\>/TEST_LOCAL_MANIFEST_FILE/g' "$test_file"
  sed -i 's/\<COMMIT_MANIFEST_FILE\>/TEST_COMMIT_MANIFEST_FILE/g' "$test_file"
  sed -i 's/\<SOURCE_REPO\>/TEST_SOURCE_REPO/g' "$test_file"
  sed -i 's/\<TARGET_DIR\>/TEST_TARGET_DIR/g' "$test_file"
  sed -i 's/\<MANIFEST_FILE\>/TEST_MANIFEST_FILE/g' "$test_file"
done < test_files.txt

# Clean up
rm -f test_files.txt

echo "Variable replacement complete" 