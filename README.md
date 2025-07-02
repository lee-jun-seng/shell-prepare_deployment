# Prepare Deployment in accordance to MYwave Deployment SOP

This script prepares the deployment of the MYwave application in accordance with the MYwave Deployment Standard Operating Procedure (SOP).

- Current production codes will be parked in the `suite1` directory.
- Development codes will be parked in the `azureDev` directory.
- `_sql` directory will be created. It is used to store SQL migration scripts.
- `_readme` directory will be created. It is used to store the deployment related documentation. i.e.
  - Deployment instructions for the deployment can be stored here.
    - Recommended filename for the deployment instructions is `_readme/deployment_instructions.md`.
    - The script will automatically create this file and remind release manager to delete files from server if necessary.
  - Git diffs will be stored in the `_readme/diff_files.txt`. The script use this file to prepare the deployment folder.
  - Any deployment logs can be stored here.

## Usage

Make sure you have the necessary permissions to run the script and that you have Git installed on your system.

Add execute permissions to the script if necessary:

```bash
chmod +x prep_deploy.sh
```

Sample command to run the script:

```bash
# Longhand version
./prep_deploy.sh \
    --source /path/to/source/ \
    --out /path/to/out/ \
    --git-target target_branch \
    --git-incoming incoming_branch \
    [--module module_name]

# Shorthand version
./prep_deploy.sh \
    -s /path/to/source/ \
    -o /path/to/out/ \
    -t target_branch \
    -i incoming_branch \
    [-m module_name]
```

This script accept below options:

| Option               | Description                                                                                                                      |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `-s, --source`       | The source directory to copy files from. Must be a Git repository. Must be an absolute path. Mandatory.                          |
| `-o, --out`          | The output directory to copy files to (aka deployment folder). Must be an absolute path. Mandatory.                              |
| `-t, --git-target`   | The target branch name for the Git repository. Mandatory.                                                                        |
| `-i, --git-incoming` | The incoming branch name for the Git repository. Mandatory.                                                                      |
| `-m, --module`       | The module name to be used in the output directory. Optional. If not provided, the script will guess it from the Git remote URL. |

Additional notes on guessing the module name from the Git remote URL:

- The script will attempt to extract the module name from the Git remote URL if the `-m ` and `--module` option is not provided.
- The script currently will treat `-` as directory separator.
  - Example: the remote URL is `git@github.com:{account}/payroll-formula_setup.git`, the module name will be guessed as `payroll/formula_setup`.

## Maintainers

| Maintainer | Email                     |
| ---------- | ------------------------- |
| Lee Jun    | <lee-jun_seng@mywave.biz> |
