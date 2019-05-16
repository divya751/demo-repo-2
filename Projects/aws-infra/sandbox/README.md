# Sandbox account

This account is setup as the learning playground and sandbox environment for
developers. **This account allows for provisioning resources using the
console.**


To be able to assume the *Developer* role in the sandbox account, a role and policy is required to
be present. Run the following to install:

```
hf-stack-events -p cloudformation@husdyrfag-sandbox -f sandbox/iam/config.json
```
