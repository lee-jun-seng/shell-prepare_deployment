# SFTP Download Files & Compare

This script is designed to check if files in a specified local directory are in sync with files on a remote SFTP server.

It connects to an SFTP server and attempt to download all files listed in the specified local directory into a temporary directory. Then, it compares the downloaded files in the temporary directory with the files in the specified local directory using `diff` command.

In the event of new files found in the local directory that do not exist on the remote server, the script will treat it as out of sync case. **It is developer responsibility to determine if this requires action.**

The script retrieves the files from remote server relative to the path specified in the `sftp.json` - `remoteDir` field.

## Usage

Make sure you have the necessary permissions to run the script.

Add execute permissions to the script if necessary:

```bash
chmod +x sftp_dl_cmp_files.sh
```

Copy the `sftp.json.example` to `sftp.json` and modify it to include your SFTP server details:

```json
{
  "host": "your.host.name",
  "port": 22,
  "user": "your_username",
  "sshKey": "/path/to/your/private/key",
  "remoteDir": "/path/to/remote/directory"
}
```

Sample command to run the script:

```bash
# Longhand version
./sftp_dl_cmp_files.sh \
  --sftp-json "sftp.json" \
  --directory "/path/to/local/directory" \
  [--remain-temp-dir]

# Shorthand version
./sftp_dl_cmp_files.sh \
  -s "sftp.json" \
  -d "/path/to/local/directory" \
  [--remain-temp-dir]
```

This script accept below options:

| Option              | Description                                                                              |
| ------------------- | ---------------------------------------------------------------------------------------- |
| `-s, --sftp-json`   | Path to a JSON file containing SFTP connection details.                                  |
| `-d, --directory`   | Path to the local directory containing files to compare.                                 |
| `--remain-temp-dir` | Retain the temporary directory after script completion for debugging purposes. Optional. |

## Dependencies

This script requires the following dependencies:

| Dependency | Description                                            |
| ---------- | ------------------------------------------------------ |
| diff       | Differential file and directory comparison tool        |
| jq         | A lightweight and flexible command-line JSON processor |
| sftp       | Secure File Transfer Protocol client                   |
| ssh        | OpenSSH remote login client                            |
| uuidgen    | Generate unique identifiers                            |

Please ensure these dependencies are installed and accessible in your system's PATH.

## Maintainers

| Maintainer | Email                     |
| ---------- | ------------------------- |
| Lee Jun    | <lee-jun_seng@mywave.biz> |
