# Frontend apps

* Static files reside in an S3 bucket
* The S3 bucket is configured as a website with public read access
* CloudFront sits in front of the bucket, serving a custom SSL certificate
* A Lambda@Edge function is attached to the CloudFront distribution to handle
  URL rewrites (and eventually also manage OAuth tokens)
* DNS is configured in Route 53

Bring up the distribution:

```sh
hf-stack-deploy -p cloudformation@husdyrfag-staging -f frontend/distribution/config.json
```

**NB!** Creating or updating the CloudFront Distribution takes *a long time*, in
the 15+ minutes range. Stay patient!

When the distribution is created, copy it's ID to a configuration file, and
install the Lambda stack:

```sh
hf-stack-deploy -p cloudformation@husdyrfag-staging -f frontend/lambda/husdyrfag-staging.json
```

NB! The Lambda is deployed in `us-east-1`, which is a requirement for
[Lambda@Edge](http://docs.aws.amazon.com/lambda/latest/dg/lambda-edge.html).
Because the Lambda is deployed in a different region from most other resources,
the configuration file contains some hard-coded values. Beware if redoing this
setup, or somehow changing the infrastructure bucket etc.

Setting up the Lambda trigger on the Cloudfront distribution needs to happen
after the Cloudfront distribution is ready:

```sh
./frontend/connect-lambda.sh -p cloudformation@husdyrfag-staging -f frontend/lambda/husdyrfag-staging.json
```
