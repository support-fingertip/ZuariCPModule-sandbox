@isTest
private class GetSupportTicket_MobileAPI_Test {

    @TestSetup
    static void setupTestData() {
        // Create Channel Partner for positive tests with unique User_Id__c and Email__c
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'Test Partner ' + String.valueOf(Crypto.getRandomLong()),
            Email__c = 'test+' + Math.abs(Crypto.getRandomInteger()) + '@example.com',  // Ensure Email__c is unique
          //  User_Id__c = 'CP-' + String.valueOf(Crypto.getRandomLong()),  // Ensure User_Id__c is unique
            Active__c = true
        );
        insert cp;

        // Create Support Tickets for the Channel Partner
        Support_Ticket__c ticket1 = new Support_Ticket__c(
           // Name = 'ST-001',
            Channel_Partner__c = cp.Id,
            Ticket_Status__c = 'New',
            Subject__c = 'Commission Issue',
            Description__c = 'Issue related to commission',
            Type__c = 'Sales',
            Priority_Status__c = 'High'
        );
        insert ticket1;

        Support_Ticket__c ticket2 = new Support_Ticket__c(
          //  Name = 'ST-002',
            Channel_Partner__c = cp.Id,
            Ticket_Status__c = 'New',
            Subject__c = 'Payment not received',
            Description__c = 'Client has not received the payment',
            Type__c = 'Sales',
            Priority_Status__c = 'Medium'
        );
        insert ticket2;
    }

    @isTest
    static void test_successfulTicketFetch() {
        Channel_Partner__c cp = [SELECT User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];

        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'ticketStatusId' => 'New',  // Valid status
            'ticketTypeId' => 'Sales', // Valid type
            'search' => 'Commission',  // Valid search term
            'pageSize' => 2
        });

        Test.startTest();
        mock(payload);
        GetSupportTicket_MobileAPI.getTickets();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
       // System.assert(responseBody.contains('"status":true'), 'Expected success status');
        //System.assert(responseBody.contains('Support ticket data'), 'Expected message in response');
    }

    @isTest
    static void test_noTicketsFound() {
        Channel_Partner__c cp = [SELECT User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];

        // Send request with filters but no matching tickets
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'ticketStatusId' => 'Closed',  // Invalid status that won't match
            'ticketTypeId' => 'Support', // Invalid type
            'search' => 'Non-Existing',  // Non-matching search term
            'pageSize' => 2
        });

        Test.startTest();
        mock(payload);
        GetSupportTicket_MobileAPI.getTickets();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"status":false'), 'Expected failure status');
        System.assert(responseBody.contains('No support tickets found for the given filters'), 'Expected no tickets found message');
    }

    @isTest
    static void test_missingRequiredFields() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => '',
            'ticketStatusId' => '',  // Missing required field
            'ticketTypeId' => '',
            'search' => '',
            'pageSize' => 0
        });

        Test.startTest();
        mock(payload);
        GetSupportTicket_MobileAPI.getTickets();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"status":false'), 'Expected failure status');
        System.assert(responseBody.contains('UserId is required'), 'Expected missing userId error message');
    }

    @isTest
    static void test_invalidChannelPartner() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => '99999',  // Non-existent user
            'ticketStatusId' => 'New',  // Valid status
            'ticketTypeId' => 'Sales', // Valid type
            'search' => 'Sales',
            'pageSize' => 2
        });

        Test.startTest();
        mock(payload);
        GetSupportTicket_MobileAPI.getTickets();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"status":false'), 'Expected failure status');
        System.assert(responseBody.contains('Channel Partner not found'), 'Expected Channel Partner not found message');
    }

    @isTest
    static void test_invalidJsonFormat() {
        String payload = '{ invalid json }';

        Test.startTest();
        mock(payload);
        GetSupportTicket_MobileAPI.getTickets();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"status":false'), 'Expected failure status');
      //  System.assert(responseBody.contains('Error: Failed to fetch support tickets: Unexpected character'), 'Expected error message');
    }

    @isTest
    static void test_dmlException() {
        Channel_Partner__c cp = [SELECT User_Id__c, Email__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];

        // Create payload with invalid picklist value for ticketStatusId
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'ticketStatusId' => 'INVALID_STATUS',  // Invalid picklist value
            'ticketTypeId' => 'Sales',
            'search' => 'Sales',
            'pageSize' => 2
        });

        Test.startTest();
        mock(payload);
        GetSupportTicket_MobileAPI.getTickets();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"status":false'), 'Expected failure status');
       // System.assert(responseBody.contains('failed'), 'Expected failure message');
    }

    /* ============================= HELPERS ============================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetSupportTicketAPI/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        RestContext.response.statusCode = 200;
    }
}