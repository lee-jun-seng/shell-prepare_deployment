# Prepare Deployment in accordance to MYwave Deployment SOP

This script prepares the deployment of the MYwave application in accordance with the MYwave Deployment Standard Operating Procedure (SOP).

- Current production codes will be parked in the `suite1` directory.
- Development codes will be parked in the `azureDev` directory.
- `_sql` directory will be created. It is used to store SQL migration scripts.
- `_README` directory will be created. It is used to store the deployment related documentation.
  - Git diffs will be stored in the `_README/diff_files.txt`.
  - Any special instructions for the deployment can be stored here. Recommended filename for the deployment instructions is `_README/deployment_instructions.txt`.
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

