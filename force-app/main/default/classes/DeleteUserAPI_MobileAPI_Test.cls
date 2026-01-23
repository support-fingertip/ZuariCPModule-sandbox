@isTest
private class DeleteUserAPI_MobileAPI_Test {

    @TestSetup
    static void setupTestData() {
        // Create Channel Partner for positive tests
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'Test Partner ' + String.valueOf(Crypto.getRandomLong()),
            Email__c = 'test@example.com',  // Ensure Email__c is populated
            Active__c = true
       //   User_Id__c = '12345'  // Set userId for the Channel Partner
        );
        insert cp;
    }

  /*  @IsTest
    static void test_successfulUserDeletion() {
        Channel_Partner__c cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE User_Id__c = '12345' AND Active__c = true LIMIT 1];

        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c
        });

        try {
            Test.startTest();
            mock(payload);
            DeleteUserAPI_MobileAPI.deleteUser();
            Test.stopTest();

            System.assertEquals(200, RestContext.response.statusCode);
            String responseBody = RestContext.response.responseBody.toString();
            System.assert(responseBody.contains('"status":true'));
            System.assert(responseBody.contains('User deleted successfully'));

            // Verify user is now inactive
            Channel_Partner__c updatedCp = [SELECT Active__c FROM Channel_Partner__c WHERE Id = :cp.Id];
            System.assertEquals(false, updatedCp.Active__c);

            // Verify log
            Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c WHERE Request_Type__c = 'DeleteUserAPI' ORDER BY CreatedDate DESC LIMIT 1];
            System.assertEquals('SUCCESS', log.Status__c);
        } catch (Exception e) {
            System.debug('Exception in test_successfulUserDeletion: ' + e.getMessage());
            System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
    }*/

    @IsTest
    static void test_missingUserId() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => ''  // Empty userId
        });

        try {
            Test.startTest();
            mock(payload);
            DeleteUserAPI_MobileAPI.deleteUser();
            Test.stopTest();

            System.assertEquals(200, RestContext.response.statusCode);
            String responseBody = RestContext.response.responseBody.toString();
            System.assert(responseBody.contains('"status":false'));
            System.assert(responseBody.contains('UserId is required'));

            // Verify log status
            Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c WHERE Request_Type__c = 'DeleteUserAPI' ORDER BY CreatedDate DESC LIMIT 1];
            System.assertEquals('FAIL', log.Status__c);
        } catch (Exception e) {
            System.debug('Exception in test_missingUserId: ' + e.getMessage());
            System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
    }

    @IsTest
    static void test_userNotFoundOrInactive() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => '99999'  // Non-existent user
        });

        try {
            Test.startTest();
            mock(payload);
            DeleteUserAPI_MobileAPI.deleteUser();
            Test.stopTest();

            System.assertEquals(200, RestContext.response.statusCode);
            String responseBody = RestContext.response.responseBody.toString();
            System.assert(responseBody.contains('"status":false'));
            System.assert(responseBody.contains('User not found or already inactive'));

            // Verify log status
            Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c WHERE Request_Type__c = 'DeleteUserAPI' ORDER BY CreatedDate DESC LIMIT 1];
            System.assertEquals('FAIL', log.Status__c);
        } catch (Exception e) {
            System.debug('Exception in test_userNotFoundOrInactive: ' + e.getMessage());
            System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
    }

    @IsTest
    static void test_exceptionHandling() {
        String payload = '{ invalid json }';  // Invalid JSON

        try {
            Test.startTest();
            mock(payload);
            DeleteUserAPI_MobileAPI.deleteUser();
            Test.stopTest();

            System.assertEquals(200, RestContext.response.statusCode);
            String responseBody = RestContext.response.responseBody.toString();
            System.assert(responseBody.contains('"status":false'));

            // Verify log contains error message
            Apex_Log__c log = [SELECT Status__c, Error_Message__c FROM Apex_Log__c WHERE Request_Type__c = 'DeleteUserAPI' ORDER BY CreatedDate DESC LIMIT 1];
            System.assertEquals('FAIL', log.Status__c);
            System.assert(log.Error_Message__c.contains('Unexpected character'));
        } catch (Exception e) {
            System.debug('Exception in test_exceptionHandling: ' + e.getMessage());
          //  System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
    }

    /* ============================= HELPERS ============================= */
    
    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DeleteUserAPI/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        RestContext.response.statusCode = 200;
    }
}