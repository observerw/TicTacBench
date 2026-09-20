Execute bash commands in the sandbox environment.

WORKING DIRECTORY: `/home/user/project`
All commands execute from this directory. Use relative paths from here.

Available commands:

- File/navigation: `cat`, `cp`, `find`, `ls`, `mkdir`, `mv`, `pwd`, `rm`, `stat`, `tree`
- Text/search: `awk`, `cut`, `diff`, `grep`, `head`, `rg`, `sed`, `sort`, `tail`, `tr`, `uniq`, `wc`, `xargs`
- Environment/utilities: `basename`, `dirname`, `du`, `echo`, `env`, `export`, `printf`, `tee`, `which`
- Programming: `js-exec` for standard JavaScript execution.

Common operations:
- `ls -la              # List files with details`
- `find . -name '*.ts' # Find files by pattern`
- `grep -r 'pattern' . # Search file contents`
- `cat <file>          # View file contents`

Rules:

- **COMMAND NOT LISTED ABOVE ARE NOT AVAILABLE AND MUST NOT BE CALLED.**
- Call given tools instead of trying to run commands directly.
    - e.g. use iverilog tool instead of running `iverilog` in bash
    - e.g. use write tool instead of `echo "some content" > some_file`
- Tools are NOT bash commands. Use tool-call syntax instead of call them as bash commands.
- The sandbox DO NOT support `/tmp`. DO NOT lookup files in `/tmp`.