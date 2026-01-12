@RestResource(urlMapping='/ChannelPartnerLeadAPI/*')
global without sharing class ChannelPartnerLead_MobileAPI {
    
    @HttpPost
    global static void getLeadData() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'Dashboard_MobileAPI';
        log.Request__c = requestBody;
        
        try {
            
            leadRequest wrapper =  (leadRequest) JSON.deserialize(requestBody, leadRequest.class);
            if (wrapper == null || String.isBlank(wrapper.userId)) {
                log.Response__c = 'UserId should not be blank';
                log.Status__c = 'FAIL';
                insert log;
                sendErrorResponse('UserId should not be blank');
                return;
            }
            
            String userId = wrapper.userId;
            
            List<Channel_Partner__c> cmList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                log.Response__c = 'User Not Found';
                log.Status__c = 'FAIL';
                insert log;
                sendErrorResponse('User Not Found in System');
                return;
            }
            
              DashboardResponse response = new DashboardResponse();
            response.status = true;
            response.message = 'leads list';
            response.data = new List<DashboardData>();
            
           List<Lead> ldlst = [Select id,Name,FirstName,LastName,Lead_ID__c from Lead Where Channel_Partner__c=:cmList[0].Id];
          for (Lead ld : ldlst) {
                DashboardData dd = new DashboardData();
                dd.id = ld.Lead_ID__c;
                dd.leadName = ld.Name;
                response.data.add(dd);
            }

            // ✅ SEND RESPONSE
            sendResponse(response); 
            
        }catch (Exception e) {
            log.Response__c = e.getStackTraceString();
            log.Error_Message__c = e.getMessage();
            log.Status__c = 'FAIL';
            insert log;
            sendErrorResponse(e.getMessage());
        }
    }
    public class leadRequest {
        public String userId;
    } 
    public class DashboardResponse {
        public Boolean status;
        public String message;
        public List<DashboardData> data;
    }

    public class DashboardData {
        public String id;
        public String leadName;
    }
    
    private static void sendResponse(Object resObj) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(resObj));
    }
    
    private static void sendErrorResponse(String message) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(
                new Map<String, Object>{
                    'status' => false,
                        'message' => message
                        }
            ));
    }
}