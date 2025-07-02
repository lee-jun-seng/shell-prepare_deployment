---
author: Lee Jun <lee-jun_seng@mywave.biz> | MYwave Sdn Bhd
date: YYYY-MM-DD
paging: Slide %d / %d
---

# Automate Deployment Folder Preparation

Disclaimer:

To make this presentation more relatable, I may use some fictional scenarios.

Any resemblance to real persons, living or dead, is purely coincidental.

---

# The problem

1. You have a long running project. Lasted many moons.
2. Many changes. Add files, modify files, delete files.
3. Long and slow brew. 🍺
4. MULTITASK!
   - Hotfixes
   - Meetingsssss
   - Prepare gazillion proposals that eventually ended up in the bin anyway
5. Finally, judgement day.
    - Time to prepare the deployment folder.
6. Ee...?

```




┻━┻ ︵ ¯\(ツ)/¯ ︵ ┻━┻
```



---

# Your fix?

## Document everything

- Well. Document. What have you changed? Which files deleted? Document extensively.
- Still failed? Not document enough. Document **HARDER**.

---

# Your fix?

## Document everything

- Well. Document. What have you changed? Which files deleted? Document extensively.
- Still failed? Not document enough. Document **HARDER**.

## Blame

- Focus not given. Cannot split brain. Lead/manager's fault.
- Meh.

---

# Git?

- Wait a minute.
- Git can help you with this.
- Demo time.

```
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠈⢉⡉⠙⠛⠓⠒⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀
⠀⠀⠀⠀⣴⠞⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⣤⣤⣤⣀⣀⠀
⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠤⢤⣤⣤⣤⣤⡤⠤⠀
⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀
⠀⠀⠀⠀⢡⣶⡶⢶⣶⣶⣦⣄⡀⠀⠀⠀⠀⢀⣠⣴⣶⣶⡶⢶⣦⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣠⣤⣤⣤⣤⣤⡌⠉⠉⣀⣀⣀⣀⠉⠉⣠⣤⣤⣤⣤⣤⡄⠀⠀⠀⠀
⠀⠀⠀⠀⢿⣿⣿⣿⣿⠋⢀⣶⣿⣿⣿⣿⣿⣿⣦⡈⠻⣿⣿⣿⣿⡧⠀⠀⠀⠀
⠀⠀⠀⠀⡆⠀⠀⠉⠁⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠈⠉⠀⢠⡄⠀⠀⠀⠀
⠀⠀⠀⠀⡇⠀⠀⠀⢰⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢀⠀⠀⠀⢸⡇⠀⠀⠀⠀
⠀⠀⠀⢀⡇⠀⠀⠀⠈⣆⢻⣿⣿⣿⣿⣿⣿⣿⣿⠏⡼⠀⠀⠀⢸⣇⠀⠀⠀⠀
⠀⠀⢀⡾⣿⡀⠀⢰⣆⠘⣦⡙⠿⣿⣿⣿⡿⠟⣁⡼⠁⣼⡀⢠⡟⢻⡄⠀⠀⠀
⠀⢀⡾⠃⢸⣇⠀⣾⡟⠀⠈⠙⠳⠶⠶⠶⠶⠟⠋⠀⠀⣿⣇⠹⠀⠀⢿⡀⠀⠀
⠀⠈⠁⠀⠀⠉⠀⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠀⠀⠀⠈⠁⠀⠀
```

---

# How it works?

1. The script is intended to work with Git local.
1. The shell script will compare the latest state of the branches.
   - This give us the diff.
3. With reference to the diff, it then checkout the branches, and copy the files and prepare it MYwave way.

---

# All sunshine and rainbows?

- Well, not really.
- The script is local first.
    - Without a central repository, you will have to manual sync production codes into `main` branch.
- Busy modules. Conflicts will happen. Git-fu ready?

---

# What is next?

- You can get the script from [GitHub](https://github.com/lee-jun-seng/shell-prepare_deployment).
    - Welcome to fork and contribute.
- You decide if it facilitates your deployment process.
- You may need to tweak your code management process at organisation level.

