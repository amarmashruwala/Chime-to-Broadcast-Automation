# chime-to-rtmp

This repository contains a Docker container that, when started, will join an Amazon Chime meeting by PIN and broadcast the meeting's audio and video in high definition (1080p at 30fps) to an RTMP endpoint you specify. The broadcast participant joins the meeting in the muted state. The meeting PIN must be unlocked in order for the broadcast participant to join the meeting.

## EC2 Deployment:

## Prerequisites

You will need Docker and `make` installed on your system. As this container is running a Firefox browser instance and transcoding audio and video in real time, it is recommended to use a host system with at least 8GB RAM and 4 CPU cores, such as an m5.xlarge EC2 instance running Ubuntu Linux 18.04 LTS.
 
## Configuration

The input for the container is a file called `container.env`. You create this file by copying the `container.env.template` to `container.env` and filling in the following variables:
 
 
* `MEETING_URL`: Chime Meeting URL (without any spaces in it)
  * Example(If you want to record Chime): `https://app.chime.aws/meetings/<meetingID>`
  * Example(Hosted [Chime SDK Serverless Demo](https://github.com/aws/amazon-chime-sdk-js/tree/master/demos/serverless) URL): `<Hosted Chime URL>/?m=<Meeting ID>&broadcast=true`
* `RTMP_URL`: the URL of the RTMP endpoint,
  * Twitch example: `rtmp://live.twitch.tv/app/<stream key>`
  * YouTube Live example: `rtmp://a.rtmp.youtube.com/live2/<stream key>`

## Running

To build the Docker image, run:
 
```
$ make
```
 
Once you have configured the `container.env` file, run the container:
 
```
$ make run
```
 
The container will start up and join the given Amazon Chime meeting as the `<Broadcast>` attendee and start streaming H.264/AAC in FLV format to the given RTMP endpoint.

When your broadcast has finished, stop the stream by killing the container:

```
$ docker kill bcast
```

If you launched an EC2 instance to host the Docker container, you may also want to stop the instance to avoid incurring cost.


## ECS Deplyoment:

## Prerequisites using Windows 10

You will need the following on your local Machine
* Download and Install Copilot. check if copilot is properly installed
Run:
 ``` 
 New-Alias -Name “copilot” copilot-windows 
 ``` 
 Next enter:
 ```
 copilot
 ```
 This should return with copilot commands  
* Download and install Docker Desktop for Windows. Run Docker. Make sure WSL2 Linux kernal package 64 bit is installed on your Windows PC. (this is needed to run docker on Windows)   
* Install Git for Windows  
* Install AWS CLI - check if aws clie is properly installed by running aws in powershell. It should return with some commands  
* Windows Powershell  

## Configuration

* Create a new folder on your local drive
* Clone this Github repository into the newly created folder. Example "GithubRepos"
* Go to your AWS Account, IAM -> users -> security credentials, create and access key, and download the .csv file in a known location on your local Machine. (if not done already) you will need your account credentials at a later stage.
* Open Windows Powershell 
* Run:
 ``` 
 New-Alias -Name “copilot” copilot-windows 
 ``` 
 This is to give the copilot application an alias.   
 * Next we need to configure aws with our credentials. 
 run:
 ```
 aws configure
 ```
 You will be prompted to enter your aws credentials. Copy your access key ID from the .svc file and enter it into the powershell prompt.  
 Next copy the secret key from the .svc file and again enter it into the powershell prompt.  
 * Enter the default region name where you plan to deploy in your account.  
 * skip default output format.    
 
 Check your aws credentials.  
 * You should now return to your C:\users\username folder. 
 * check the contents of the folder to be sure you have an .aws folder within it. 
 * check the contents of the .aws folder using ```ls ~/.aws``` You should see 2 files: Config, Credentials
 *  Next run ```cat ~/.aws/credentials``` and press Tab. You should see access key ID and Secret Access key output on the screen.  
 
 Next go to the folder where you cloned this Github repository. In my case it is GithubRepos.  
 This where we start out deployment process. 
 
 ## Initialize Application  
 
 Make sure you have provided copilot with an Alias 
 ```
 New-Alias -Name “copilot” copilot-windows
 copilot init 
 ```
 * Enter the name of your application.  
 * Workload type: Backend service  
 * Enter the name of your service  
 * Type: Choose ./Dockerfile  

Now copilot will:   
* Write a manifest file - this will be placed into the service folder within the copilot folder. Open the Manifest file in notepad++ and change the default CPU and RAM to:
```
cpu: 8192    
memory: 16384
```
* Save the manifest file. 
* Copilot will create the infrastructure for your service. 
* Would you like to deploy a Test Environment? (y/n) N  


## Initialize the Environment

To innitialize the invironment:
```
copilot env init 
```
* What is your environment name? Give it a name (in my case uit is Prod) 
* Which credentials would you like to use to create Prod: select [profile default]
* Enter on yes, use default  
Next run: 

```
copilot app ls
```
This is to check if your environment was successfully created

## Deploy your environment

Next run:
```
copilot env deploy --name Prod 
copilot env ls
```  
Copilot will create the infrastructure for your environment. 

## Create your secrets (you need to create 2 secrets for MEETING_URL and RTMP_URL)  

Next run:
```
copilot secret init
```
* What would you like to name this secret? MEETING_URL
* What is the value of secret MEETING_URL in environment Prod? Provide the chime meeting URL
* Copilot will output the first secret. Copy that output, go to your manifest.yml file, uncomment secrets, replace the 1st default secret with this secret you have just copied and save the manifest.  

Do this Process again for the 2nd secret. 

## EOL conversion of the Manifest.yml file and run.sh file

* In Notepad++ go to edit > EOL Conversion > make sure it is set to Unix(LF) and save for both files. 

## Deploy the application 
Run:
```
copilot deploy  
```   
* Copilot will start building the docker image and push it to ECS.  
* Next copilot will prose infrastructure changes for the stack and the application will be deployed.  
* once deployed, the broadcast client will join your chime meeting ID and stream the output to the RTMP URL 

## Deleting the application using Copilot  

To delete an application and environment:
* check your application: this should display your app
```
copilot app ls
```
* next delete your application
```
copilot app delete 
```
* Select the name of the application you want to delete. 
* Next check if everything is deleted
```
copilot app ls
```
* this should return without the application name in powershell 
* Next check if the environment is deleted
```
copilot env ls
```
* This should return an error: Could not find any application in this region and account. Try initiating one with ‘copilot app init’
* If you are deleting a deployment, ensure you also delete the Secrets from the Parameter store otherwise they will not connect to your redeployment. 

## Deployment a new service in the same Cluster

* When you start this process, instead of using ```copilot init``` use:
```
copilot svc init
```
* Next create new secrets for the new service 
```
copilot secret init
```
* create new secrets called MEETING_URL2, RTMP_URL2
* Next change the secret labels in the newly created Manifest.yml, run.sh, and container.env example 
* Deploy the new service
```
copilot svc deploy
```
* this will deploy another service under the same cluster. 

## Delete a service (not an entire cluster) 

To delete only a specific service run:
```
copilot svc delete
```
* select the name of the service to delete. this will delete just that service. Remember to delete the Secrets for that service from the Systems Manager Parameter Store. 





 
 
 
 
 
 

