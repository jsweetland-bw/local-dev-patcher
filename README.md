# Local Development Patcher (local-dev-patcher)

Tools to patch a repo for use in local development and to keep those patches up to date.

## Conventions

### Glossary

- **dev path** - The path under which the repositories and patch files are stored
- **repo directory name** - The base name of the directory containing the repository files
- **repo path** - The full path to the directory containing the repository files
- **patch path** - The full path to the directory containing the patch files
- **patch path suffix** - The string appended to the repo directory name to calulate the name of the directory containing the patch files

### Default Values

The following default values are specified in the `default-values.sh` file.

- `dev_path`: `${HOME}/Dev`
- `patch_path_suffix`: `.local-changes`

### Calculated Values

- `repo_dirname`: Assumed to be the first child directory of the dev path within the current path. For example, if the current path is `/Users/jsweetland/Dev/insights-alerting/insights-alerting-config-api` and the dev path is `/Users/jsweetland/Dev`, the `repo_dirname` value will be set to `insights-alerting`.
- `repo_path`: Set to `${dev_path}/${repo_dirname}`. For example, if the dev path is `/Users/jsweetland/Dev` and the repo directory name is `insights-alerting`, the repo path will be set to `/Users/jsweetland/Dev/insights-alerting`.
- `patch_path`: Set to `${dev_path}/${repo_dirname}${patch_path_suffix}`. For example, if the dev path is `/Users/jsweetland/Dev`, the repo directory name is `insights-alerting`, and the patch path suffix is `.local-changes`, the patch path will be set to `/Users/jsweetland/Dev/insights-alerting.local-changes`.

### Shared Parameters

Each of the scripts in this package accept these shared parameters, all of which are optional.

- `-r repo_dirname`: Sets the name of the repo to the value of `repo_dirname`. If this option is omitted, the calculated value will be used as described above.
- `-f file_to_patch`: Specifies a single file at `file_to_patch` to patch. This path can be a relative path as long as the current directory is within a directory under the dev path. If this option is omitted, it will attempt to patch all the files available in the patch path.
- `-d dev_path`: Sets the path to the dev directory to the value of `dev_path`. If this option is omitted, the default value will be used as described above.
- `-p patch_path`: Sets the path to the patch files to the value of `patch_path`. If this options is omitted, the calculated value will be used as described above.
- `-s patch_path_suffix`: Sets the suffix to append to the repo path when calculating the patch path to the value of `patch_path_suffix`. If this option is omitted, the default value will be used as described above.
- `-h`: Prints the help message.

## How to Update a Patch File

Run the `update-local-patch.sh -f file_to_update` script to update the patch file specified by `file_to_update`. The `-f file_to_update` parameter is required.

### Required Parameters

- `-f file_to_update`: Sets the name of the file to update to the value of `file_to_update`.

## How to Apply a Patch

Run the `patch-for-local.sh` script to apply a patch to a repository. This script does not take any parameters other than the shared parameters.

### General Flow

The following is the generalized flow the script follows:

1. Determine the name of the repository if one is not specified.
2. Determine the full paths for both the repository and the patch files.
3. Identify the files included in the patch and determine whether they are different from the files in the repository.
4. Prompt for whether to continue or abort.
5. If continuing, copy the files from the patch path into the repo path, skipping any files for which the md5sum of the patch file matches the md5sum of the repo file.
6. Print lists of the copied and skipped files.
