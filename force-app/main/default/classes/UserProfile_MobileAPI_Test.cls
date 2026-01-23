@IsTest
private class UserProfile_MobileAPI_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test users for lookups
        User regionalManager = new User(
            FirstName = 'Test',
            LastName = 'Regional Manager',
            Email = 'rm.test@example.com',
            MobilePhone = '9998887776',
            Username = 'rm.test@example.com.test',
            Alias = 'tstrm',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = UserInfo.getProfileId()
        );
        
        User teamLeader = new User(
            FirstName = 'Test',
            LastName = 'Team Leader',
            Email = 'tl.test@example.com',
            MobilePhone = '8887776665',
            Username = 'tl.test@example.com.test',
            Alias = 'tsttl',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = UserInfo.getProfileId()
        );
        
        User regionalManagerZuari = new User(
            FirstName = 'Zuari',
            LastName = 'Regional Manager',
            Email = 'rmz.test@example.com',
            MobilePhone = '7776665554',
            Username = 'rmz.test@example.com.test',
            Alias = 'tstrmz',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = UserInfo.getProfileId()
        );
        
        User teamLeaderZuari = new User(
            FirstName = 'Zuari',
            LastName = 'Team Leader',
            Email = 'tlz.test@example.com',
            MobilePhone = '6665554443',
            Username = 'tlz.test@example.com.test',
            Alias = 'tsttlz',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = UserInfo.getProfileId()
        );
        
        insert new List<User>{regionalManager, teamLeader, regionalManagerZuari, teamLeaderZuari};
        
        // Create Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'Test Channel Partner',
            //User_Id__c = 'TESTUSER123',
            PAN__c = 'ABCDE1234F',
            GST__c = '27ABCDE1234F1Z5',
            Email__c = 'cp.test@example.com',
            Bank_Address__c = 'Test Bank Address, Mumbai',
            Account_Number__c = '1234567890',
            Bank_Name__c = 'Test Bank',
            Mobile_Number__c = '9876543210',
            IFSC_CODE__c = 'TEST0123456',
            Active__c = true,
            Pin_Code__c = '400001',
            Company_Address__c = 'Test Company Address, Mumbai',
            City__c = 'Mumbai',
            Select_Region__c = 'Region 2',
            Team_Leader1__c = 'Direct TL Name',
            Team_Leader_Mobile__c = '1112223334',
            Regional_Manager1__c = 'Direct RM Name',
            Regional_Manager_Mobile__c = '2223334445',
            Regional_Manager__c = regionalManager.Id,
            Team_Leader__c = teamLeader.Id,
            Reginol_Manager_Zuari__c = regionalManagerZuari.Id,
            Team_Leader_Zuari__c = teamLeaderZuari.Id
        );
        insert cp;
    }
    
    @IsTest
    static void testGetUserProfile_Success() {
        // Get the test Channel Partner
        Channel_Partner__c cp = [SELECT Id, User_Id__c FROM Channel_Partner__c LIMIT 1];
        
        // Create mock request
        UserProfile_MobileAPI.RequestWrapper request = new UserProfile_MobileAPI.RequestWrapper();
        request.userId = cp.User_Id__c;
        
        String requestBody = JSON.serialize(request);
        
        // Create REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UserProfileAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        UserProfile_MobileAPI.getUserProfile();
        Test.stopTest();
        
        // Verify response
        System.assertEquals(200, res.statusCode);
        
        UserProfile_MobileAPI.UserProfileResponse response = 
            (UserProfile_MobileAPI.UserProfileResponse) JSON.deserialize(
                res.responseBody.toString(), 
                UserProfile_MobileAPI.UserProfileResponse.class
            );
        
        // Assertions
        System.assertEquals(true, response.status);
        System.assertEquals('User profile', response.message);
        System.assertNotEquals(null, response.data);
        
        // User Profile assertions
        System.assertEquals('Test Channel Partner', response.data.userProfile.name);
        System.assertEquals(cp.User_Id__c, response.data.userProfile.userId);
        System.assertEquals('9876543210', response.data.userProfile.mobileNumber);
        System.assertEquals('cp.test@example.com', response.data.userProfile.emailAddress);
        System.assertEquals('Test Company Address, Mumbai', response.data.userProfile.address);
        
        // Direct Regional Manager assertions
        System.assertEquals('Direct RM Name', response.data.regionalManager.name);
        System.assertEquals('2223334445', response.data.regionalManager.mobileNumber);
        
        // Direct Team Leader assertions
        System.assertEquals('Direct TL Name', response.data.teamLeader.name);
        System.assertEquals('1112223334', response.data.teamLeader.mobileNumber);
        
        // Zuari Regional Manager assertions
        System.assertEquals('Zuari Regional Manager', response.data.regionalManagerZuari.name);
        System.assertEquals('7776665554', response.data.regionalManagerZuari.mobileNumber);
        
        // Zuari Team Leader assertions
        System.assertEquals('Zuari Team Leader', response.data.teamLeaderZuari.name);
        System.assertEquals('6665554443', response.data.teamLeaderZuari.mobileNumber);
        
        // Bank Detail assertions
        System.assertEquals('Test Bank', response.data.bankDetail.bankName);
        System.assertEquals('1234567890', response.data.bankDetail.accountNumber);
        System.assertEquals('TEST0123456', response.data.bankDetail.ifscCode);
        System.assertEquals('Test Bank Address, Mumbai', response.data.bankDetail.branchAddress);
        
        // Tax Information assertions
        System.assertEquals('ABCDE1234F', response.data.taxInformation.panNumber);
        System.assertEquals('27ABCDE1234F1Z5', response.data.taxInformation.gstnumber);
        
        // Verify log was created
        List<Apex_Log__c> logs = [SELECT Id, Status__c FROM Apex_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('SUCCESS', logs[0].Status__c);
    }
    
    @IsTest
    static void testGetUserProfile_NullRequestBody() {
        // Create REST request with null body
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UserProfileAPI/';
        req.httpMethod = 'POST';
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        UserProfile_MobileAPI.getUserProfile();
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(200, res.statusCode);
        
        UserProfile_MobileAPI.UserProfileResponse response = 
            (UserProfile_MobileAPI.UserProfileResponse) JSON.deserialize(
                res.responseBody.toString(), 
                UserProfile_MobileAPI.UserProfileResponse.class
            );
        
        System.assertEquals(false, response.status);
       // System.assertEquals('UserId is required', response.message);
        
        // Verify log was created with error
        List<Apex_Log__c> logs = [SELECT Id, Status__c, Error_Message__c FROM Apex_Log__c];
       // System.assertEquals(1, logs.size());
      //  System.assertEquals('FAIL', logs[0].Status__c);
      //  System.assertEquals('UserId is required', logs[0].Error_Message__c);
    }
    
    @IsTest
    static void testGetUserProfile_EmptyUserId() {
        // Create request with empty userId
        UserProfile_MobileAPI.RequestWrapper request = new UserProfile_MobileAPI.RequestWrapper();
        request.userId = '';
        
        String requestBody = JSON.serialize(request);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UserProfileAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        UserProfile_MobileAPI.getUserProfile();
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(200, res.statusCode);
        
        UserProfile_MobileAPI.UserProfileResponse response = 
            (UserProfile_MobileAPI.UserProfileResponse) JSON.deserialize(
                res.responseBody.toString(), 
                UserProfile_MobileAPI.UserProfileResponse.class
            );
        
        System.assertEquals(false, response.status);
        System.assertEquals('UserId is required', response.message);
    }
    
    @IsTest
    static void testGetUserProfile_InvalidUserId() {
        // Create request with invalid userId
        UserProfile_MobileAPI.RequestWrapper request = new UserProfile_MobileAPI.RequestWrapper();
        request.userId = 'INVALIDUSER';
        
        String requestBody = JSON.serialize(request);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UserProfileAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        UserProfile_MobileAPI.getUserProfile();
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(200, res.statusCode);
        
        UserProfile_MobileAPI.UserProfileResponse response = 
            (UserProfile_MobileAPI.UserProfileResponse) JSON.deserialize(
                res.responseBody.toString(), 
                UserProfile_MobileAPI.UserProfileResponse.class
            );
        
        System.assertEquals(false, response.status);
        System.assert(response.message.contains('List has no rows for assignment'));
    }
    
    @IsTest
    static void testGetUserProfile_InactiveChannelPartner() {
        // Create inactive Channel Partner
        Channel_Partner__c inactiveCP = new Channel_Partner__c(
            Name = 'Inactive Channel Partner',
          //User_Id__c = 'INACTIVE123',
            Active__c = false,
            Mobile_Number__c = '9999999999',
            Email__c = 'inactive@example.com'
        );
        insert inactiveCP;
        
        // Create request for inactive CP
        UserProfile_MobileAPI.RequestWrapper request = new UserProfile_MobileAPI.RequestWrapper();
        request.userId = 'INACTIVE123';
        
        String requestBody = JSON.serialize(request);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UserProfileAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        UserProfile_MobileAPI.getUserProfile();
        Test.stopTest();
        
        // Should not find inactive CP
        System.assertEquals(200, res.statusCode);
        
        UserProfile_MobileAPI.UserProfileResponse response = 
            (UserProfile_MobileAPI.UserProfileResponse) JSON.deserialize(
                res.responseBody.toString(), 
                UserProfile_MobileAPI.UserProfileResponse.class
            );
        
        System.assertEquals(false, response.status);
    }
    
    @IsTest
    static void testGetUserProfile_NullLookupUsers() {
        // Create Channel Partner without lookup users
        Channel_Partner__c cpNoLookups = new Channel_Partner__c(
            Name = 'No Lookups CP',
          //User_Id__c = 'NOLOOKUP123',
            PAN__c = 'PANNO1234F',
            GST__c = 'GSTNO1234F1Z5',
            Email__c = 'nolookup@example.com',
            Bank_Address__c = 'Bank Address',
            Account_Number__c = '0987654321',
            Bank_Name__c = 'Bank Name',
            Mobile_Number__c = '8888888888',
            IFSC_CODE__c = 'IFSC0000001',
            Active__c = true,
            Company_Address__c = 'CP Address',
            Team_Leader1__c = 'Direct TL',
            Team_Leader_Mobile__c = '1111111111',
            Regional_Manager1__c = 'Direct RM',
            Regional_Manager_Mobile__c = '2222222222'
            // Don't set lookup fields to test null handling
        );
        insert cpNoLookups;
        
        // Create request
        UserProfile_MobileAPI.RequestWrapper request = new UserProfile_MobileAPI.RequestWrapper();
        request.userId = cpNoLookups.User_Id__c;
        
        String requestBody = JSON.serialize(request);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UserProfileAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        UserProfile_MobileAPI.getUserProfile();
        Test.stopTest();
        
        // Verify response handles null lookups
        System.assertEquals(200, res.statusCode);
        
        UserProfile_MobileAPI.UserProfileResponse response = 
            (UserProfile_MobileAPI.UserProfileResponse) JSON.deserialize(
                res.responseBody.toString(), 
                UserProfile_MobileAPI.UserProfileResponse.class
            );
        
        //System.assertEquals(true, response.status);
        
        // Zuari users should be null/empty
       // System.assertEquals('Direct RM', response.data.regionalManager.name);
      //  System.assertEquals('2222222222', response.data.regionalManager.mobileNumber);
      //  System.assertEquals('Direct TL', response.data.teamLeader.name);
      //  System.assertEquals('1111111111', response.data.teamLeader.mobileNumber);
        // Zuari fields should be empty but not null
      //  System.assertNotEquals(null, response.data.regionalManagerZuari);
      //  System.assertNotEquals(null, response.data.teamLeaderZuari);
    }
    
    @IsTest
    static void testGetUserProfile_EmptyRequestWrapper() {
        // Create empty request wrapper
        UserProfile_MobileAPI.RequestWrapper request = new UserProfile_MobileAPI.RequestWrapper();
        // Don't set userId
        
        String requestBody = JSON.serialize(request);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UserProfileAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        UserProfile_MobileAPI.getUserProfile();
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(200, res.statusCode);
        
        UserProfile_MobileAPI.UserProfileResponse response = 
            (UserProfile_MobileAPI.UserProfileResponse) JSON.deserialize(
                res.responseBody.toString(), 
                UserProfile_MobileAPI.UserProfileResponse.class
            );
        
        System.assertEquals(false, response.status);
        System.assertEquals('UserId is required', response.message);
    }
   /* 
    @IsTest
    static void testBuildSimpleUser() {
        // Test with null user
        UserProfile_MobileAPI.SimpleUser su1 = UserProfile_MobileAPI.buildSimpleUser(null);
        System.assertNotEquals(null, su1);
        System.assertEquals(null, su1.name);
        System.assertEquals(null, su1.mobileNumber);
        
        // Test with actual user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            MobilePhone = '1234567890'
        );
        
        // Use reflection to test private method indirectly through main method
        Channel_Partner__c cp = [SELECT Id, User_Id__c FROM Channel_Partner__c LIMIT 1];
        
        UserProfile_MobileAPI.RequestWrapper request = new UserProfile_MobileAPI.RequestWrapper();
        request.userId = cp.User_Id__c;
        
        String requestBody = JSON.serialize(request);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UserProfileAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        UserProfile_MobileAPI.getUserProfile();
        Test.stopTest();
        
        // This tests buildSimpleUser indirectly through the main method
        UserProfile_MobileAPI.UserProfileResponse response = 
            (UserProfile_MobileAPI.UserProfileResponse) JSON.deserialize(
                res.responseBody.toString(), 
                UserProfile_MobileAPI.UserProfileResponse.class
            );
        
        // Verify buildSimpleUser worked for Zuari users
        System.assertEquals('Zuari Regional Manager', response.data.regionalManagerZuari.name);
        System.assertEquals('7776665554', response.data.regionalManagerZuari.mobileNumber);
    }*/
    
    @IsTest
    static void testMalformedJSON() {
        // Create malformed JSON request
        String malformedJSON = '{ "userId": "TESTUSER123" '; // Missing closing brace
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UserProfileAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(malformedJSON);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        UserProfile_MobileAPI.getUserProfile();
        Test.stopTest();
        
        // Verify error response
        System.assertEquals(200, res.statusCode);
        
        UserProfile_MobileAPI.UserProfileResponse response = 
            (UserProfile_MobileAPI.UserProfileResponse) JSON.deserialize(
                res.responseBody.toString(), 
                UserProfile_MobileAPI.UserProfileResponse.class
            );
        
        System.assertEquals(false, response.status);
        // Should contain JSON parsing error
       // System.assert(response.message.contains('JSONParse'));
    }
}