# screenshot-service

# Contents

# Quick Start
Download [Terraform](https://www.terraform.io/downloads.html) and place the executable in the directory.

`git clone https://github.com/pendraggon87/screenshot-service.git
cd screenshot-service
wget https://releases.hashicorp.com/terraform/0.12.12/terraform_0.12.12_windows_amd64.zip
unzip terraform_0.12.12_windows_amd64.zip && rm terraform_0.12.12_windows_amd64.zip`

Configure the `provider.tf` file with your appropriate AWS access keys, or other mechanisms to ensure Terraform is able to operate.
> There are many ways to handle granting Terraform AWS access. At this stage, the template is using access keys for ease of use

After you have provided the appropriate credentials, review the `variables.tf` file to ensure appropriate names are generated (S3 buckets will need a unique name, if nothing else)

Run `.\terraform.exe plan`, and if there are no errors, run `.\terraform.exe apply`.  That's it!

## Generating those Screenshots
The API Gateway accepts both **GET** and **POST** requests.  
### GET Request
Simply pass a URL-encoded url to the gateway, and you are good to go!
`https://RANDOM.execute-api.us-east-1.amazonaws.com/screenshot?url=http%3b%2f%2fgoogle.com`
### POST Request
Submit a JSON object within the request body as follows:

`{"url": "github.com"}` or `{"urls": ["google.com", "https://bing.com"]}`

# Notes
* If a URI scheme is not defined, or the scheme is not one of **https** or **http**, the default scheme selected will be ***http***.
* Non-standard ports must be explicitly added to the URL (e.g. *http://github.com:8080*)
* Only one URL can be passed via GET; multiple can be passed via POST