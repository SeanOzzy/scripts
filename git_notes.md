# Git cheatsheet 
## Basic notes for completing a change and PR
 - Fork the project repository
 - Clone your fork locally - ```git clone https://github.com/%yourForkedRepository%```
 - Confirm your fork is the origin of the local repo - ```git remote -v```
  - You can add remotes origins using - ```git remote add origin %urlOfFork%```
 - Add the project repo as the upstream remote - ```git remote add upstream %urlOfProjectRepo%```
  - ```git remote -v``` to confirm
 - Make sure you have the latest changes from upstream - ``git pull upstream master```
 - Create a new branch for your code change in your local repo - ```git checkout -b %branchName%```
 - Checkout the new local branch and make your changes
 - Stage and commit any changes - ```git add and git commit -m "Your nice useful commit message"```
 - Push the changes to your fork - ```git push origin %branchName%```
 - Select to compare and pull request in your fork
 - Create the pull request 

## Adding commits to the pull request
 - Return to your local repo and branch - ```git checkout %branchName%```
 - Make your additional changes and commit them

## Cleanup
 - Once your change is accepted and merge its good practice to cleanup the branch in your fork
 - Cleanup the branch in your local repo - ```git branch -D %branchName%```
 - Resync your fork - ```git pull upstream master```
 - Push your local repo back to your fork - '``git push origin master```

### References
1. https://github.com/firstcontributions/first-contributions
2. https://github.com/github/docs/blob/main/CONTRIBUTING.md
3. https://www.dataschool.io/how-to-contribute-on-github/

 
