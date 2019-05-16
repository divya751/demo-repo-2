# API Resources

Resources to use with Api Gateway APIs

<a id="dns"></a>
## Domain Name and DNS

The Api Gateway domain name resources and related Route 53 record set are
deployed like so:

```sh
hf-stack-deploy -y -p cloudformation@husdyrfag-staging -f api/domain-name/husdyrfag-api.json
```

The domain name uses Cloudfront under the hood, which means that the template
takes a small eternity to deploy.

The domain name can be referenced in `BasePathMapping` resources in API stacks
using the `ApiDomainName` export:

```yml
Resources:
  # ...

  BasePathMapping:
    Type: 'AWS::ApiGateway::BasePathMapping'
    Properties:
      BasePath: 'ndx'
      DomainName: !ImportValue ApiDomainName
      RestApiId: !Ref RestApi
      Stage: Dev
```

<a id="swagger"></a>
## Swagger UI

The Swagger UI website consists of two pieces of infrastructure: the S3 bucket
that houses the static files, and the Swagger UI deployment.

Before you attempt to deploy Swagger UI for the first time in a new account,
make sure that the Swagger UI zip bundle is in place in the infrastructure
bucket. The source for the zip itself is unfortunately not available to anyone
other than Kenneth Schulstad right now. This will be mitigated in the close
future.

```sh
aws s3 cp \
    --profile cloudformation@husdyrfag-staging \
    api/swagger/swagger-3_4_2_hf1.zip \
    s3://$(hf-get-infra-bucket -p cloudformation@husdyrfag-staging)/swagger/swagger-3_4_2_hf1.zip
```

Then bring up the stack:

```sh
hf-stack-deploy -y -p cloudformation@husdyrfag-staging -f api/swagger/husdyrfag-swagger-ui.json
```

If the Swagger UI bucket already exists you probably don't need to deploy this
stack again.

With the Swagger UI bucket in place, you can deploy Swagger UI. The
configuration file ensures that this is performed automatically after
`hf-stack-deploy` successfully completes.

```sh
./api/swagger/deploy.sh -p cloudformation@husdyrfag-staging -f api/swagger/husdyrfag-swagger-ui.json
```

Note: Files in `src` will be copied into the unzipped Swagger UI source before
being deployed to S3. This effectively allows you to override defaults from the
`src` directory.

### Adding API docs

You add API docs by defining `AWS::ApiGateway::DocumentationPart` resources for
your API, and then using
(`hf-docs-deploy`)[https://github.com/TINE-SA/aws-tooling/#hf-docs-deploy]. This
tool will export your API documentation and upload it to the bucket, as well as
add it to the list of APIs for the Swagger UI site to display.

<a id="cors"></a>
## CORS

Api Gateway has built-in CORS support, but unfortunately it is a little limited.
Specifically, the built-in CORS support only supports a single
`Access-Control-Allow-Origin` header value, which makes it hard to test against
an API from multiple sources (e.g. localhost, dev environment, production)
without specifying `*` as the value, which isn't desired for security reasons.

The whitelist CORS lambda matches `Origin` headers against a whitelist of
origins (and/or regular expressions), and echoes it as the CORS origin if it's
on the list.

### Test it

```sh
cd api/cors/lambda
yarn
npm test
```

### Deploy it

There is configuration to spin up the lambda:

```sh
hf-stack-deploy -y -p cloudformation@husdyrfag-staging -f api/cors/config.json
```

### CORS-enable an API

To CORS-enable and API, you need two pieces of configuration. First, you need to
grant your `AWS::ApiGateway::RestApi` access to invoke the CORS lambda. Second,
you need to specify the CORS preflight `OPTIONS` method _for each endpoint you
need to call from a browser_.

The following example sets up an API, grants it access to invoke the CORS
lambda, and CORS-enables two different resources:

```yml
Resources:
  Api:
    Type: 'AWS::ApiGateway::RestApi'
    Properties:
      Name: TestCorsApi

  CorsPermissions:
    Type: 'AWS::Lambda::Permission'
    Properties:
      FunctionName:
        Fn::ImportValue: CorsLambdaArn
      Action: 'lambda:InvokeFunction'
      Principal: apigateway.amazonaws.com
      SourceArn: !Sub "arn:aws:execute-api:${AWS::Region}:${AWS::AccountId}:${Api}/*/*"

  BlogResource:
    Type: 'AWS::ApiGateway::Resource'
    Properties:
      ParentId: !Get Api.RootResourceId
      PathPart: blog
      RestApiId: !Ref Api

  RootResourceCorsPreflight:
    Type: 'AWS::ApiGateway::Method'
    Properties:
      HttpMethod: OPTIONS
      ResourceId: !GetAtt Api.RootResourceId
      RestApiId: !Ref Api
      AuthorizationType: NONE
      Integration:
        IntegrationHttpMethod: POST
        Type: AWS_PROXY
        Uri: !ImportValue CorsIntegrationUri

  BlogResourceCorsPreflight:
    Type: 'AWS::ApiGateway::Method'
    Properties:
      HttpMethod: OPTIONS
      ResourceId: !Ref BlogResource
      RestApiId: !Ref Api
      AuthorizationType: NONE
      Integration:
        IntegrationHttpMethod: POST
        Type: AWS_PROXY
        Uri: !ImportValue CorsIntegrationUri
```

There is an example stack that you can run to test CORS requests:

```sh
hf-stack-deploy -y -p cloudformation@husdyrfag-staging -f api/cors/example.json
```
