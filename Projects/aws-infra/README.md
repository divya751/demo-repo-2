# aws-infra


CloudFormation stack templates, scripts, and documentation of AWS
infrastructure.

## Bootstrapping new accounts

Refer to the [bootstrapping instructions](./bootstrap/README.md) for detailed
instructions.

## Individual features

For most new accounts, it is suggested that the following stacks are set up as a
part of bootstrapping:

* [API resources](./api/Readme.md)
* [Cloudformation stack termination](./stack-termination/Readme.md)
* [Container infrastructure](./containers/Readme.md)
* [Frontend apps](./frontend/Readme.md)
* [Rollback stack](./rollback-stack/Readme.md)

The bastion stack is only ever set up if someone needs SSH access to EC2
instances (which should happen rarely, if ever):

* [Bastion server](./bastion/Readme.md)

Set up metrics and logs:

* [Metrics and logs resources](./metrics-logs/Readme.md)

## Ops resources

Some resources are only relevant for the [operations account](./ops):

* [Concourse](./ops/concourse/)
* [Nexus](./ops/nexus/)
* [Pact broker](./ops/pact-broker/)

## Prerequisites

Check out and set up the [Husdyrfag AWS tooling kit](https://github.com/TINE-SA/aws-tooling).

Refer to the [account and CLI config guide](https://confluence.tine.no/display/TDOC/Oppsett+av+bruker+og+aws-klient)
for information on the recommended profiles. The example profiles used in the
various Readmes are the same ones as in that document.
