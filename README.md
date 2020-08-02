# screenshot-service

# Contents

# Quick Start
Download [Terraform](https://www.terraform.io/downloads.html) and place the executable in the directory.  
```
git clone https://github.com/pendraggon87/screenshot-service.git
cd screenshot-service  
wget https://releases.hashicorp.com/terraform/0.12.12/terraform_0.12.12_windows_amd64.zip
unzip terraform_0.12.12_windows_amd64.zip && rm terraform_0.12.12_windows_amd64.zip
```

Configure the `provider.tf` file with your appropriate AWS access keys, or other mechanisms to ensure Terraform is able to operate.
> There are many ways to handle granting Terraform AWS access. At this stage, the template is using access keys for ease of use

After you have provided the appropriate credentials, review the `variables.tf` file to ensure appropriate names are generated (S3 buckets will need a unique name, if nothing else)

Run `.\terraform.exe plan`, and if there are no errors, run `.\terraform.exe apply`.  The application will return the API endpoint and the API key for use - that's it!

## Generating those Screenshots
The API Gateway accepts both **GET** and **POST** requests. If successful, a JSON response will be returned - the "screenshot_url" key will contain the URL to your newly generated image!
### GET Request
Simply pass the url (do NOT URL encode the string) to the gateway using the **url** query parameter, and you are good to go!  
`https://RANDOM.execute-api.us-east-1.amazonaws.com/screenshot?url=http://google.com`
### POST Request
Send the following JSON body to the API endpoint (note that it is not necessary to url encode the URL):  
`{"url": "http://google.com"}`

# Notes
* If a URI scheme is not defined, or the scheme is not one of **https** or **http**, the default scheme selected will be ***http***.
* Non-standard ports must be explicitly added to the URL (e.g. *http://github.com:8080*) - otherwise, the default of 80 or 443 will be applied based on the provided scheme
* Only one URL can be passed at this time
* Version of headless chrome (1.0.0-54) found here: https://github.com/adieuadieu/serverless-chrome/releases/download/v1.0.0-54/stable-headless-chromium-amazonlinux-2017-03.zip
* Version of chromedriver used (2.41) can be found here: https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip