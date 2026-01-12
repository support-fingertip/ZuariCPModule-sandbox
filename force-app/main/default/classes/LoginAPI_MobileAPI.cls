/*****************************************************************************************
* Class Name   : LoginAPI_MobileAPI
* Company      : Fingertipplus
* Created Date : 15-12-2025
*
* Description  :
* ---------------------------------------------------------------------------------------
* This Apex class exposes a RESTful POST web service for mobile number–based login,
* intended for consumption by a mobile application.
*
* The API accepts a JSON request containing a mobile number and password, validates
* the input, authenticates the user against active Channel_Partner__c records,
* and returns a structured JSON response indicating success or failure.
*
* On successful authentication:
*  - User credentials are validated
*  - Login response data is returned (userId, password change flag, token placeholder)
*  - API activity is logged in Apex_Log__c
*
* On failure:
*  - Appropriate error messages are returned
*  - Errors and request details are logged
*
* Sample Input JSON:
* ---------------------------------------------------------------------------------------
* {
*   "mobileNumber": "9999999999",
*   "password": "Test@123"
* }
*
* Sample Success Response:
* ---------------------------------------------------------------------------------------
* {
*   "status": true,
*   "message": "Login successful",
*   "data": {
*     "token": "AUTHENTICATION TOKEN",
*     "userId": "CP-001",
*     "isPasswordChange": false
*   }
* }
*
* Author       : Sandeep Kumar
*
* Change Log:
* ---------------------------------------------------------------------------------------
* Version | Author         | Date       | Description
* ---------------------------------------------------------------------------------------
* 1.0     | Sandeep Kumar  | 15-12-2025 | Initial version
******************************************************************************************/

@RestResource(urlMapping='/LoginAPI/*')
global without sharing class LoginAPI_MobileAPI {

    @HttpPost
    global static void checkLogin() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'loginAPI';
        log.Request__c = requestBody;

        try {

            // Deserialize request
            LoginWrapper loginData =(LoginWrapper) JSON.deserialize(requestBody, LoginWrapper.class);

            String mobile = loginData.mobileNumber;
            String password = loginData.password;
            String deviceId = logindata.deviceId;
           

            // Validate input
            if (String.isBlank(mobile) || String.isBlank(password)) {

                log.Response__c = 'Mobile number or password missing';
                log.Status__c = 'FAIL';
                insert log;

                sendErrorResponse('Please enter valid mobile number and password');
                return;
            }

            // Authenticate customer
            List<Channel_Partner__c> cmList = [
                SELECT Id,Name,Is_Password_Change__c,Password__c, Mobile_Number__c,User_Id__c
                FROM Channel_Partner__c
                WHERE Mobile_Number__c = :mobile
                AND Active__c = True
               LIMIT 1
            ];

            if (cmList.isEmpty()) {

                log.Response__c = 'Customer Not Found';
                log.Status__c = 'FAIL';
                insert log;

                sendErrorResponse('Customer Not Found');
                return;
            }

            Channel_Partner__c cm = cmList[0];
            List<Logged_in_Device__c> dvlst = [select id,Status__c,Last_Logged_Out__c from Logged_in_Device__c where Device_Id__c =: deviceId AND Channel_Partner__c =:cmList[0].Id limit 1]; 
            if(dvlst.Size()==0){
                
                Logged_in_Device__c lgd = new Logged_in_Device__c();
                lgd.Channel_Partner__c =cmList[0].Id;
                lgd.Last_Logged_In__c = System.Now();
                lgd.Status__c ='Active';
                lgd.Device_Id__c =deviceId;
                insert lgd;
            }
            else if(dvlst.Size()==1){
                dvlst[0].Status__c = 'Active';
                dvlst[0].Last_Logged_In__c = System.Now();
                update dvlst[0];
                
            }
            
            if (cm.Password__c != password) {
                log.Response__c = 'Incorrect Password';
                log.Status__c = 'FAIL';
                insert log;
                sendErrorResponse('Invalid password');
                return;
            }

       

            // Prepare success response
            Map<String, Object> data = new Map<String, Object>{
                 'token' => 'AUTHENTICATION TOKEN',
                'userId' => cm.User_Id__c,
                'isPasswordChange'  => cm.Is_Password_Change__c
                
            };

            Map<String, Object> response = new Map<String, Object>{
                'status' => true,
                'message' => 'Login successful',
                'data' => data
            };

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody =
                Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'Login success for ' + cm.Name;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {

            log.Response__c = e.getStackTraceString();
            log.Error_Message__c = e.getMessage();
            log.Status__c = 'FAIL';
            insert log;

            sendErrorResponse('Login failed. Please try again.');
        }
    }

    // Wrapper class for input JSON
    public class LoginWrapper {
        public String mobileNumber;
        public String password; 
        public String deviceId; 
    }

    // Error response helper
    private static void sendErrorResponse(String message) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'status' => false,
                'message' => message
            }));
    }



}