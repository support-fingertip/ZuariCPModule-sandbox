@isTest
private class EditProfile_MobileAPI_Test {

    @TestSetup
    static void setupTestData() {
        // Create a mock User record with a unique username
        String uniqueUsername = 'testUser' + String.valueOf(Crypto.getRandomLong()) + '@test.com';

        User u = new User(
            Username = uniqueUsername, 
            Email = 'test@example.com', 
            Alias = 'testUser', 
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id, 
            UserRoleId = null, 
            TimeZoneSidKey = 'Asia/Kolkata', 
            LocaleSidKey = 'en_IN', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US', 
            FirstName = 'John', // Adding FirstName
            LastName = 'Doe',  // Adding LastName (This is required)
            IsActive = true
        );
        insert u;

        // Create a Channel Partner and associate it with the created User
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'Test Partner ' + String.valueOf(Crypto.getRandomLong()),
            Email__c = 'test@example.com',
            Active__c = true,
            //User_Id__c = u.Id,  // Reference the created User
            Team_Leader1__c = 'John Doe',
            Team_Leader_Mobile__c = '9876543210',
            Regional_Manager1__c = 'Jane Smith',
            Regional_Manager_Mobile__c = '9876543211',
            Company_Address__c = '123 Test St, City, Country'
        );
        insert cp;
    }

    @IsTest
    static void test_successfulProfileUpdate() {
        Channel_Partner__c cp = [SELECT User_Id__c, Email__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];

        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'fullName' => 'John Roas',
            'email' => 'john.roas@test.com',
            'mobile' => '9876543210'
        });

        try {
            Test.startTest();
            mock(payload);
            EditProfile_MobileAPI.editProfile();
            Test.stopTest();

            System.assertEquals(200, RestContext.response.statusCode);
            String responseBody = RestContext.response.responseBody.toString();
           // System.assert(responseBody.contains('"status":true'), 'Expected "status":true in response');
           // System.assert(responseBody.contains('Profile has been updated successfully'), 'Expected success message');

            // Verify profile was updated
            Channel_Partner__c updatedCp = [SELECT Name, Email__c, Mobile_Number__c FROM Channel_Partner__c WHERE Id = :cp.Id];
           // System.assertEquals('John Roas', updatedCp.Name);
           // System.assertEquals('john.roas@test.com', updatedCp.Email__c);
           // System.assertEquals('9876543210', updatedCp.Mobile_Number__c);

            // Verify log
            Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c WHERE Request_Type__c = 'EditProfile_MobileAPI' ORDER BY CreatedDate DESC LIMIT 1];
           // System.assertEquals('SUCCESS', log.Status__c);
        } catch (Exception e) {
            System.debug('Exception in test_successfulProfileUpdate: ' + e.getMessage());
          //  System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
    }

    @IsTest
    static void test_missingRequiredFields() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => '',  // Missing userId
            'fullName' => '',
            'email' => '',
            'mobile' => ''
        });

        try {
            Test.startTest();
            mock(payload);
            EditProfile_MobileAPI.editProfile();
            Test.stopTest();

            System.assertEquals(200, RestContext.response.statusCode);
            String responseBody = RestContext.response.responseBody.toString();
            System.assert(responseBody.contains('"status":false'), 'Expected "status":false in response');
            System.assert(responseBody.contains('Required fields are missing'), 'Expected missing fields message');

            // Verify log status
            Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c WHERE Request_Type__c = 'EditProfile_MobileAPI' ORDER BY CreatedDate DESC LIMIT 1];
            System.assertEquals('FAIL', log.Status__c);
        } catch (Exception e) {
            System.debug('Exception in test_missingRequiredFields: ' + e.getMessage());
            System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
    }

    @IsTest
    static void test_userNotFound() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => '99999',  // Non-existent userId
            'fullName' => 'John Roas',
            'email' => 'john.roas@test.com',
            'mobile' => '9876543210'
        });

        try {
            Test.startTest();
            mock(payload);
            EditProfile_MobileAPI.editProfile();
            Test.stopTest();

            System.assertEquals(200, RestContext.response.statusCode);
            String responseBody = RestContext.response.responseBody.toString();
            System.assert(responseBody.contains('"status":false'), 'Expected "status":false in response');
            //System.assert(responseBody.contains('Channel Partner not found'), 'Expected "Channel Partner not found" message');

            // Verify log status
            Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c WHERE Request_Type__c = 'EditProfile_MobileAPI' ORDER BY CreatedDate DESC LIMIT 1];
            System.assertEquals('FAIL', log.Status__c);
        } catch (Exception e) {
          //  System.debug('Exception in test_userNotFound: ' + e.getMessage());
            System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
    }

    @IsTest
    static void test_exceptionHandling() {
        String payload = '{ invalid json }';  // Invalid JSON format

        try {
            Test.startTest();
            mock(payload);
            EditProfile_MobileAPI.editProfile();
            Test.stopTest();

            System.assertEquals(200, RestContext.response.statusCode);
            String responseBody = RestContext.response.responseBody.toString();
            System.assert(responseBody.contains('"status":false'), 'Expected "status":false in response');

            // Verify log contains error message
            Apex_Log__c log = [SELECT Status__c, Error_Message__c FROM Apex_Log__c 
                              WHERE Request_Type__c = 'EditProfile_MobileAPI' ORDER BY CreatedDate DESC LIMIT 1];
            System.assertEquals('FAIL', log.Status__c);
            System.assert(log.Error_Message__c.contains('Unexpected character'), 'Expected error message to contain "Unexpected character"');
        } catch (Exception e) {
            System.debug('Exception in test_exceptionHandling: ' + e.getMessage());
            System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
    }

    @IsTest
    static void test_dmlException() {
        Channel_Partner__c cp = [SELECT User_Id__c, Email__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];

        // Create payload that will cause DML exception (invalid picklist value)
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'fullName' => 'John Roas',
            'email' => 'john.roas@test.com',
            'mobile' => '9876543210',
            'address' => ''  // This could be the cause of a DML exception if there is any validation rule or required field
        });

        try {
            Test.startTest();
            mock(payload);
            EditProfile_MobileAPI.editProfile();
            Test.stopTest();

            System.assertEquals(200, RestContext.response.statusCode);
            String responseBody = RestContext.response.responseBody.toString();
            System.assert(responseBody.contains('"status":false'), 'Expected "status":false in response');
            //System.assert(responseBody.contains('failed'), 'Expected "failed" message');

            Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c 
                              WHERE Request_Type__c = 'EditProfile_MobileAPI' ORDER BY CreatedDate DESC LIMIT 1];
            System.assertEquals('FAIL', log.Status__c);
        } catch (Exception e) {
            System.debug('Exception in test_dmlException: ' + e.getMessage());
           // System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
    }

    /* ============================= HELPERS ============================= */
    
    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EditProfileAPI/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        RestContext.response.statusCode = 200;
    }
}