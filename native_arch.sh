set -e

# Our GitHub action is executed either on an x64 or Rosetta 2 emulated arm64 host. 
# Brew needs to be executed on the host arch in order to function correctly.
# Similar problem and more info here: https://gregmfoster.medium.com/using-m1-mac-minis-to-power-our-github-actions-ios-ci-540c55af13ea

EXIT_CODE=0
arch -arm64 echo > /dev/null || EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then 
  # if we can execute on arm64 arch, it means we are an arm64 host system (possible emulated by Rosetta 2), so use that arch
  arch -arm64 "$@"
else 
  # if we can not, we can simply execute the command on the host system (intel based)
  "$@"
fi