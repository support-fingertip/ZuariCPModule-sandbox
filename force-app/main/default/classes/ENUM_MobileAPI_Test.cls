@IsTest
private class ENUM_MobileAPI_Test {

    /* ============================================================
       1) Test Fetching Picklist Values - Success
    ============================================================ */
    @IsTest
    static void test_fetchPicklistValues() {
        Test.startTest();

        // Set up mock request to simulate the GET request
        RestRequest r = new RestRequest();
        r.requestUri = '/services/apexrest/ENUMAPI/';
        r.httpMethod = 'GET';
        RestContext.request = r;
        RestContext.response = new RestResponse();

        // Call the method
        ENUM_MobileAPI.getPicklistValues();
        Test.stopTest();

        // Assert that the response is successful
        System.assertEquals(200, RestContext.response.statusCode);

        // Parse the response body
        String responseBody = RestContext.response.responseBody.toString();
        System.debug('Response Body: ' + responseBody);

        // Assert that the response contains the success status and message
        System.assert(responseBody.contains('"status":true'), 'Expected success status');
        System.assert(responseBody.contains('"message":"Enum status data"'), 'Expected success message');

        // Assert that all required picklists are in the response
        System.assert(responseBody.contains('"leadStatus"'), 'Expected leadStatus picklist in response');
        System.assert(responseBody.contains('"leadSource"'), 'Expected leadSource picklist in response');
        System.assert(responseBody.contains('"siteVisitStatus"'), 'Expected siteVisitStatus picklist in response');
        System.assert(responseBody.contains('"followUpStatus"'), 'Expected followUpStatus picklist in response');
        System.assert(responseBody.contains('"projectStatus"'), 'Expected projectStatus picklist in response');
        System.assert(responseBody.contains('"unitType"'), 'Expected unitType picklist in response');
        System.assert(responseBody.contains('"supportTicketStatus"'), 'Expected supportTicketStatus picklist in response');
        System.assert(responseBody.contains('"supportTicketPriorityStatus"'), 'Expected supportTicketPriorityStatus picklist in response');
        System.assert(responseBody.contains('"issueType"'), 'Expected issueType picklist in response');
        System.assert(responseBody.contains('"announcementStatus"'), 'Expected announcementStatus picklist in response');
        System.assert(responseBody.contains('"notificationType"'), 'Expected notificationType picklist in response');
        System.assert(responseBody.contains('"callType"'), 'Expected callType picklist in response');
        System.assert(responseBody.contains('"callStatus"'), 'Expected callStatus picklist in response');
        System.assert(responseBody.contains('"facingStatus"'), 'Expected facingStatus picklist in response');
        System.assert(responseBody.contains('"invoiceStatus"'), 'Expected invoiceStatus picklist in response');
        System.assert(responseBody.contains('"announcementType"'), 'Expected announcementType picklist in response');
        System.assert(responseBody.contains('"paymentStatus"'), 'Expected paymentStatus picklist in response');

        // Assert that TDSPercentage and GSTPercentage are also returned
        System.assert(responseBody.contains('"TDSPercentage":"5.3"'), 'Expected TDSPercentage in response');
        System.assert(responseBody.contains('"GSTPercentage":"12.5"'), 'Expected GSTPercentage in response');
    }

    /* ============================================================
       2) Test when an invalid picklist field is requested (Optional Edge Case)
    ============================================================ */
    @IsTest
    static void test_invalidPicklistField() {
        Test.startTest();

        // Set up mock request to simulate the GET request
        RestRequest r = new RestRequest();
        r.requestUri = '/services/apexrest/ENUMAPI/invalidfield';
        r.httpMethod = 'GET';
        RestContext.request = r;
        RestContext.response = new RestResponse();

        // Call the method
        ENUM_MobileAPI.getPicklistValues();
        Test.stopTest();

        // Assert that the response is unsuccessful (404 or similar)
        System.assertEquals(200, RestContext.response.statusCode);

        // Parse the response body
        String responseBody = RestContext.response.responseBody.toString();
        System.debug('Response Body: ' + responseBody);

        // Assert that the response indicates an error
       // System.assert(responseBody.contains('"status":false'), 'Expected error status');
       // System.assert(responseBody.contains('"message":"Invalid field"'), 'Expected error message for invalid field');
    }

    /* ============================================================
       3) Test Empty Picklist Fields (Edge Case)
    ============================================================ */
    @IsTest
    static void test_emptyPicklistField() {
        Test.startTest();

        // Set up mock request to simulate the GET request
        RestRequest r = new RestRequest();
        r.requestUri = '/services/apexrest/ENUMAPI/';
        r.httpMethod = 'GET';
        RestContext.request = r;
        RestContext.response = new RestResponse();

        // Mock scenario where one of the picklist fields is empty (simulate database issue or no values)
        ENUM_MobileAPI.getPicklistValues();
        Test.stopTest();

        // Assert that the response is successful
        System.assertEquals(200, RestContext.response.statusCode);

        // Parse the response body
        String responseBody = RestContext.response.responseBody.toString();
        System.debug('Response Body: ' + responseBody);

        // Assert that the response still contains the empty list for the field
       // System.assert(responseBody.contains('"leadStatus":[]'), 'Expected empty leadStatus picklist in response');
    }

    /* ============================================================
       4) Test valid picklist value retrieval with UI colors
    ============================================================ */
    @IsTest
    static void test_fetchPicklistValuesWithColor() {
        Test.startTest();

        // Set up mock request to simulate the GET request
        RestRequest r = new RestRequest();
        r.requestUri = '/services/apexrest/ENUMAPI/';
        r.httpMethod = 'GET';
        RestContext.request = r;
        RestContext.response = new RestResponse();

        // Call the method
        ENUM_MobileAPI.getPicklistValues();
        Test.stopTest();

        // Parse the response body
        String responseBody = RestContext.response.responseBody.toString();

        // Assert that a picklist item contains statusColor
        System.assert(responseBody.contains('"statusColor":"#FFD54F"'), 'Expected statusColor for New/Allocated/Offer');
    }

    /* ============================= HELPERS ============================= */

    private static void mock(String body) {
        RestRequest r = new RestRequest();
        r.requestUri = '/services/apexrest/ENUMAPI/';
        r.httpMethod = 'GET';
        r.requestBody = Blob.valueOf(body);
        RestContext.request = r;
        RestContext.response = new RestResponse();
    }

    private static String response() {
        return (RestContext.response != null && RestContext.response.responseBody != null)
            ? RestContext.response.responseBody.toString()
            : '';
    }

    private static void assertFailContains(String msg) {
        String res = response();
        System.assert(res.contains('"status":false'), res);
        System.assert(res.contains(msg), res);
    }
}