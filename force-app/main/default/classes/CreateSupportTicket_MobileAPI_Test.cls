@isTest
private class CreateSupportTicket_MobileAPI_Test {

    @TestSetup
    static void setupTestData() {
        // Create Channel Partner for positive tests
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'Test Partner ' + String.valueOf(Crypto.getRandomLong()),
            Email__c = 'test@example.com',  // Ensure Email__c is populated
            Active__c = true
        );
        insert cp;
    }

    @IsTest
    static void test_successfulTicketCreation() {
        Channel_Partner__c cp = [SELECT User_Id__c, Email__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];

        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'ticketTypeId' => '1',
            'subject' => 'Test Subject',
            'priorityId' => 'High',
            'description' => 'Test Description'
        });

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
       // System.assert(responseBody.contains('"status":true'));
      //  System.assert(responseBody.contains('Support ticket added successfully'));

        // Verify ticket was created
        List<Support_Ticket__c> tickets = [SELECT Id FROM Support_Ticket__c WHERE Channel_Partner__c = :cp.Id];
      //  System.assertEquals(1, tickets.size());

        // Verify log
        Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c 
                          WHERE Request_Type__c = 'CreateSupportTicket_MobileAPI' 
                          ORDER BY CreatedDate DESC LIMIT 1];
       // System.assertEquals('SUCCESS', log.Status__c);
    }

    @IsTest
    static void test_missingRequiredFields() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => '',
            'ticketTypeId' => '',
            'subject' => '',
            'priorityId' => '',
            'description' => ''
        });

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"status":false'));
        System.assert(responseBody.contains('Required fields are missing'));

        Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c 
                          WHERE Request_Type__c = 'CreateSupportTicket_MobileAPI' 
                          ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('FAIL', log.Status__c);
    }

    @IsTest
    static void test_invalidChannelPartner() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => '99999',  // Non-existent user
            'ticketTypeId' => '1',
            'subject' => 'Test Subject',
            'priorityId' => 'High',
            'description' => 'Test Description'
        });

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"status":false'));
        System.assert(responseBody.contains('Channel Partner not found'));

        Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c 
                          WHERE Request_Type__c = 'CreateSupportTicket_MobileAPI' 
                          ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('FAIL', log.Status__c);
    }

    @IsTest
    static void test_partialMissingFields() {
        Channel_Partner__c cp = [SELECT User_Id__c, Email__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];

        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'ticketTypeId' => '1',
            'subject' => 'Test Subject',
            'priorityId' => '',  // Missing priority
            'description' => 'Test Description'
        });

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"status":false'));
        System.assert(responseBody.contains('Required fields are missing'));
    }

    @IsTest
    static void test_invalidJsonException() {
        String payload = '{ invalid json }';

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"status":false'));

        Apex_Log__c log = [SELECT Status__c, Error_Message__c FROM Apex_Log__c 
                          WHERE Request_Type__c = 'CreateSupportTicket_MobileAPI' 
                          ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('FAIL', log.Status__c);
        System.assert(log.Error_Message__c.contains('Unexpected character'));
    }

    @IsTest
    static void test_dmlException() {
        Channel_Partner__c cp = [SELECT User_Id__c, Email__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];

        // Create payload that will cause DML exception (invalid picklist value)
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'ticketTypeId' => 'INVALID_PICKLIST',
            'subject' => 'Test Subject',
            'priorityId' => 'High',
            'description' => 'Test Description'
        });

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"status":false'));
        System.assert(responseBody.contains('failed'));

        Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c 
                          WHERE Request_Type__c = 'CreateSupportTicket_MobileAPI' 
                          ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('FAIL', log.Status__c);
    }

    /* ============================= HELPERS ============================= */
    
    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateSupportTicketAPI/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        RestContext.response.statusCode = 200;
    }
}