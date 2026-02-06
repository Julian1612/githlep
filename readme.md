Das macht absolut Sinn. Wenn du dieses Setup auf GitHub (oder GitLab/Bitbucket) hochlädst, können andere (oder du auf einem neuen Laptop) es einfach "clonen" und installieren.Hier ist die aktualisierte README.md, inklusive dem Schritt zum Klonen des Repositories.📄 Updated README.mdSpeichere das als README.md in deinem Ordner.Markdown# 🚀 Git Professional Suite

A high-performance collection of interactive CLI tools designed to optimize your Git and VS Code workflow. Stop typing long commands—start using smart wizards.

## 📦 Quick Installation

You can set up the entire suite on any Linux/WSL/macOS machine in minutes.

### 1. Download the Repository
Clone this repository to your local machine:

```bash
git clone [https://github.com/YOUR-USERNAME/git-professional-suite.git](https://github.com/YOUR-USERNAME/git-professional-suite.git)
cd git-professional-suite
(Replace YOUR-USERNAME with your actual GitHub username)2. Run the InstallerThis script will install all tools to ~/.local/bin and configure your shell automatically.Bashbash install_git_suite.sh
3. ActivateRestart your terminal or reload your configuration to activate the new aliases:Bashsource ~/.zshrc
# OR if you use bash:
# source ~/.bashrc
That's it! Type gh to open your new command center.🛠 Feature Overview1. The DashboardCommandDescriptionghCommand Center. Shows your favorites and available tools.Use gh -l to see a full reference list of all commands.Use gh -a <cmd> "Desc" to add favorites.2. Workflow ToolsCommandTool NameFeaturesrswRepo ManagerSwitch VS Code projects instantly. Supports labels, search, and direct jumping.• rsw -a: Add current folder.• rsw core: Jump to repo tagged 'core'.gswBranch SwitcherScrollable list of branches. Highlights current branch. Auto-pulls after switching. Fixes VS Code git status lag.gppPush & PRSmart Push. Auto-sets upstream if missing. Asks to open the "Create PR" page in your browser immediately.gacSmart CommitInteractive wizard for Conventional Commits. Auto-stages files. Prompts for Type, Scope, and Message.gsySync/RebaseUpdates current branch with main/master via Rebase. Keeps history clean.gnrNPM RunnerReads package.json and lists all scripts. Select and run with one click.3. Maintenance ToolsCommandTool NameFeaturesgstStash ManagerVisual list of stashes. Create new stashes or select old ones to Apply/Drop.gbdBranch DeleteSafely delete local branches. Excludes main and current branch.grcRevert CommitView last 50 commits. Select one to revert safely (non-destructive).💡 Usage Examples⚡ Speed Switching Repos (rsw)Navigate to a project folder: cd ~/dev/my-projectAdd it: rsw -a (Give it a shortcut like mp)Later, from anywhere: rsw mp -> Instantly opens VS Code in that project.🚀 The Perfect Push Flow (gp)Make changes.Commit: gac (Select 'feat', enter message).Push: gp (or gpp).Tool asks: Create Pull Request? [Y/n] -> Press Enter.Browser opens exactly on the PR creation page.⚙️ CustomizationConfiguring gh FavoritesYou can add your own favorite shell commands to the dashboard:Bashgh -a "gclean" "Cleanup Branches" "~/.local/bin/gclean"
Configuring rsw RepositoriesYou can manage repositories directly inside the rsw menu:Press e to Edit a repo (rename or change shortcut).Press d to Delete a repo from the list.📂 File StructureTools: ~/.local/bin/ (gac, gsw, rsw, etc.)Aliases: ~/.git_functions.zshConfig: ~/.config/repos.json & ~/.config/gh_favoritesEnjoy your new high-performance terminal workflow! 🚀
### Kleiner Tipp: Damit der Link funktioniert
Damit Schritt 1 wirklich klappt, musst du den Ordner, in dem dein Installer liegt, einmalig zu GitHub pushen:

1.  Erstelle ein neues **leeres** Repo auf GitHub (z.B. `git-professional-suite`).
2.  Führe in deinem Ordner (wo `install_git_suite.sh` und `README.md` liegen) folgendes aus:

```bash
git init
git add .
gac  # (Dein neues Commit Tool nutzen!) -> "feat: initial release"
git branch -M main
git remote add origin https://github.com/DEIN-USER/git-professional-suite.git
gpp  # (Dein neues Push Tool nutzen!)
