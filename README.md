Twilio Video & DeepAR iOS SDK example

This application demonstrates how to use the DeepAR SDK to add face filters and masks to your video call using the Twilio iOS SDK.

To run example:

1. Sign up at DeepAR and create a project.
2. Copy the license key and paste it to ViewController.swift (instead of your_license_key_here string)
3. Download the DeepAR SDK from https://developer.deepar.ai and copy the DeepAR.framework into DeepAR-and-Twilio/Frameworks folder
4. Install TwilioVideo with CocoaPods
5. Register at https://www.twilio.com/
6. Type in an identity and click on "Generate Access Token" from the https://www.twilio.com/console/video/project/testing-tools, 
   If you enter the Room Name, then you can restrict this user's access to the specified Room only.
   Ideally, you want to implement and deploy an Access Token server to generate tokens. 
7. Paste Access Token to ViewController.swift (instead of TWILIO_ACCESS_TOKEN)
8. Run


