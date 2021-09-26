
#!/usr/bin/env bash

set -eu

{copy_cmd}
{helm_path} repo index --debug {directory}/
{yq_path} -i e '(.generated = "1900-01-01T01:00:00.000000000Z") | ((.entries[] | .[]).created |= "1900-01-01T01:00:00.000000000Z")' {directory}/index.yaml
cp {directory}/index.yaml {output}