# chime-to-rtmp

This repository contains a Docker container that, when started, will join an Amazon Chime meeting by PIN and broadcast the meeting's audio and video in high definition (1080p at 30fps) to an RTMP endpoint you specify. The broadcast participant joins the meeting in the muted state. The meeting PIN must be unlocked in order for the broadcast participant to join the meeting.

## EC2 Deployment:

## Prerequisites

You will need Docker and `make` installed on your system. As this container is running a Firefox browser instance and transcoding audio and video in real time, it is recommended to use a host system with at least 8GB RAM and 4 CPU cores, such as an m5.xlarge EC2 instance running Ubuntu Linux 18.04 LTS.
 
## Configuration

The input for the container is a file called `container.env`. You create this file by copying the `container.env.template` to `container.env` and filling in the following variables:
 
 
* `MEETING_URL`: Chime Meeting URL (without any spaces in it)
  * Example(If you want to record Chime): `https://app.chime.aws/portal/<your Meeting ID here>`
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
 
 
 
 
 
 
 

