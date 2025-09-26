param(
    [string]$FilePath = ".",
    [string]$CommitMessage = "Auto commit"
)

# Add file(s) to git
git add $FilePath

# Commit changes
git commit -m $CommitMessage

# Push to origin/main
git push origin main
