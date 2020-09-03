# screenshot-service

My main goal in creating this service was to create a solution that allowed me to obtain valuable information from phishing emails that attempted to lure me to a malicious URL. This service will obtian a screenshot, as well as DNS records, associated with the domain.

The benefit of using a service like this was that I would not be making any of these requests from my home network IP, and I can even automate this by caling the API.

# Quick Start
Download [Terraform](https://www.terraform.io/downloads.html) and place the executable in the directory.  
```
git clone --branch v2.0.0 https://github.com/pendraggon87/screenshot-service.git
cd screenshot-service  
wget https://releases.hashicorp.com/terraform/0.12.12/terraform_0.12.12_windows_amd64.zip
unzip terraform_0.12.12_windows_amd64.zip && rm terraform_0.12.12_windows_amd64.zip
```

Configure the `provider.tf` file with your appropriate AWS access keys, or other mechanisms to ensure Terraform is able to operate. Terraform is currently configured to store state in an already existing S3 bucket - this must be created prior to running any Terraform commands. To store state locally, simply remove the Terraform backend declaration.
> There are many ways to handle granting Terraform AWS access. At this stage, the template is using access keys for ease of use

If you do not want to use a custom domain name, or you do not use [Cloudflare](https://cloudflare.com) as your DNS provider, remove the provider information from `provider.tf`.

After you have provided the appropriate credentials, review the `variables.tf` and configure the `terraform.tfvars` file to include any relevant variables.

Run `.\terraform.exe plan`, and if there are no errors, run `.\terraform.exe apply`.  The application will return the API endpoint and the API key for use - that's it!

## Generating those Screenshots
The API Gateway accepts only **GET** requests. If successful, a JSON response will be returned - the "screenshot_url" key will contain the URL to your newly generated image!
### GET Request
Simply pass the url (do NOT URL encode the string) to the gateway using the **url** query parameter, and you are good to go!  
`https://RANDOM.execute-api.us-east-1.amazonaws.com/prod/screenshot?url=http://caliburnsecurity.com`

## Obtaining DNS records
The API Gateway accepts only **GET** requests.  If successful, a JSON response will be returned containing the values for obtained DNS queries. By default, the following records will be queried:
* MX
* SOA
* NS
* SRV
* A
* AAAA
* CNAME
* TXT
### GET Request
Simply pass the FQDN to the gateway using the **FQDN** query parameter, and you are good to go!
`https://RANDOM.execute-api.us-east-1.amazonaws.com/prod/dns?FQDN=caliburnsecurity.com

# Notes
* If a URI scheme is not defined, or the scheme is not one of **https** or **http**, the default scheme selected will be ***http*** unless otherwise configured
* Non-standard ports must be explicitly added to the URL (e.g. *http://github.com:8080*) - otherwise, the default of 80 or 443 will be applied based on the provided scheme
* Only one URL can be passed at this time
* Version of headless chrome (1.0.0-54) found here: https://github.com/adieuadieu/serverless-chrome/releases/download/v1.0.0-54/stable-headless-chromium-amazonlinux-2017-03.zip
* Version of chromedriver used (2.41) can be found here: https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip