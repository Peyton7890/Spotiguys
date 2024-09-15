# term-project-team-8
Spotiguys App

Pre-Setup:
1.	From your AWS Console, navigate to the AWS Certificate Manager
2.	Request a Public Certificate with 4 domain names:
    <br/> a.	spotiguys.tk
    <br/> b.	www.spotiguys.tk
    <br/> c.	api.spotiguys.tk
    <br/> d.	www.api.spotiguys.tk
3.	Keep everything else the same, and click “Request”
4.	Click “View Certificate” on the top bar to navigate to the certificate you created
5.	Navigate to the Hosted Zones tab in Route 53
6.	Click “Create Hosted Zone”
7.  Set Domain Name to "spotoiguys.tk", and click "Create Hosted Zone" at the bottom.
8.	Navigate back to certificate manager 
9.	Then click “Create Records in Route 53”
10.	Select all 4 records and click create records.
11.	Navigate back to Hosted Zones on Route 53
12.	Copt the Value for “spotiguys.tk”, type “NS”, and send it to the team via Slack.
13.	Wait for the certificates to validate.


Setup:
1. Open main.tf and modify:
  <br/> a.	line 3 and 4 - to input your aws “access-key” and “secret-key”
  <br/> b.	Line 8 – arn of the certificate from pre-setup
  <br/> c.	Line 14- zone_id – Navigate to the Hosted zone, expand the "Hosted Zone Details”, copy the zone Id 
2.	Run the Terraform code (all .zip and .yml files in this repo are required for Terraform)
  <br/> a.  `{ terraform init }`
  <br/> b.	`{ terraform validate }`
  <br/> c.	`{ terraform plan }`
  <br/> d.	`{ terraform apply }`
3.	On your AWS console, navigate to the Amplify App and click “Run Build”
4.	After the build is completed, click on the URL provided in the frontend environment or navigate to “spotiguys.tk” in your browser


Application Guideline:
1.	After logging into your Spotify Account, click on “Fetch User Data” and wait 15 sec.
2.	After your user data is pulled from Spotify, you can create your Group.
3.	*Only one group is supported at a time
4.	Create your group and join it.
5.	Once the group is ready, click “Process Data”, and wait for the success notification to pop-up
6.	Then click “Create Playlist”. The user who created the group should have a Playlist generated in their Spotify Library.


Teardown:
1. Run `{ terraform destroy }`
2. Go to Route 53 and navigate to the hosted zone you created.
3. Go to the records, and delete every 'CNAME' type record. There should be 4.
4. Go back to the Route 53 hosted zone page and delete the hosted zone you created.
5. Go to AWS Certificate Manager and delete the certificate you created.
6. Terminate EC2 instance attached to the provided AMI.

