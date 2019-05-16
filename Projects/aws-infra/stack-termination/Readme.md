# Stack termination

The stack termination lambda runs on a regular schedule. It looks for
Cloudformation stacks with a `DeleteAfter` tag with a value that is a timestamp
in the past and terminates them. It is used for temporary stacks such as the
bastion servers.

```sh
hf-stack-deploy -p cloudformation@husdyrfag-staging -f stack-termination/config.json
```
