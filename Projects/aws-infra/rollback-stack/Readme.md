# Rollback stack

The rollback stack lambda triggers on events described in `template.yml`. If a stack
is in "UPDATE_IN_PROGRESS" state. This lambda will cancel the update on this stack.
The motivation for this lambda was ECS stacks that got stuck, because the containers
would crash on startup, thus never reaching the desired number of running tasks.

```sh
hf-stack-deploy -p cloudformation@husdyrfag-dev -f rollback-stack/config.json
```
