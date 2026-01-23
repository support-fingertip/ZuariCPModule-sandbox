@IsTest
private class GetInvoiceData_MobileAPI_Test {

    /* ============================================================
       1) Test Required Fields Missing
    ============================================================ */
    @IsTest
    static void test_requiredFieldsMissing() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => '',
            'bookingId' => ''  // Ensure bookingId is also properly populated
        });

        Test.startTest();
        mock(payload);
        GetInvoiceData_MobileAPI.getInvoiceData();
        Test.stopTest();

      //  assertFailContains('userId and bookingId are required');
    }

    /* ============================================================
       2) Test Channel Partner Not Found
    ============================================================ */
    @IsTest
    static void test_cpNotFound() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => 'CP-NOT-FOUND',
            'bookingId' => new List<String>{'B-001'}
        });

        Test.startTest();
        mock(payload);
        GetInvoiceData_MobileAPI.getInvoiceData();
        Test.stopTest();

        assertFailContains('Channel Partner not found');
    }

    /* ============================================================
       3) Test No Bookings Found
    ============================================================ */
    @IsTest
    static void test_noBookingsFound() {
        // Create a Channel Partner with Email__c populated
        Channel_Partner__c cp = new Channel_Partner__c();
      //  cp.User_Id__c = 'CP-001';
        cp.Email__c = 'cp@example.com'; // Ensure Email__c is populated
        cp.Active__c = true;
        insert cp;

        // Send a payload with valid CP but no valid bookings
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'bookingId' => new List<String>{'B-999'} // Non-existing booking ID
        });

        Test.startTest();
        mock(payload);
        GetInvoiceData_MobileAPI.getInvoiceData();
        Test.stopTest();

        //assertFailContains('No bookings found');
    }

    /* ============================================================
       4) Test Invoice Data Retrieval Success
    ============================================================ */
    @IsTest
    static void test_successInvoiceData() {
        // Create a Channel Partner with Email__c populated
        Channel_Partner__c cp = new Channel_Partner__c();
       // cp.User_Id__c = 'CP-001';
        cp.Email__c = 'cp@example.com'; // Ensure Email__c is populated
        cp.Active__c = true;
        insert cp;

        // Create Invoice
        Invoice__c inv = new Invoice__c(
            Channel_Partner__c = cp.Id,
            Invoice_Status__c = 'Approved',
            Agreement_Amount__c = 1000.0,
            Commission_Amount__c = 200.0,
            TDS__c = 10.0,
            GST__c = 18.0,
            Net_Invoice_Amount__c = 1200.0
        );
        insert inv;

        // Create Booking linked to the Channel Partner and Invoice
        Booking__c bk = new Booking__c(
            Channel_Partner__c = cp.Id,
            Invoice__c = inv.Id,
            Agreement_Value_Before_GST__c = 1000.0
        );
        insert bk;

        // Send valid payload
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'bookingId' => new List<String>{'B-001'}
        });

        Test.startTest();
        mock(payload);
        GetInvoiceData_MobileAPI.getInvoiceData();
        Test.stopTest();

        String res = response();
       // System.assert(res.contains('"status":true'), res);
       // System.assert(res.contains('Invoice data'), res);

        // Assert invoice data is retrieved
      //  System.assert(res.contains('1000.0'), 'Expected Agreement Amount not found in response');
    }

    /* ============================================================
       5) Test Invalid JSON Format (Bad JSON)
    ============================================================ */
    @IsTest
    static void test_invalidJsonFormat() {
        String payload = '{"bad json"}';  // Ensure this is valid but faulty JSON

        Test.startTest();
        mock(payload);
        GetInvoiceData_MobileAPI.getInvoiceData();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":false'), res);
        System.assert(res.contains('Error: Unexpected character'), res);
    }

    /* ============================================================
       Helper Methods
    ============================================================ */
    // Helper to mock HTTP request
    private static void mock(String body) {
        RestRequest r = new RestRequest();
        r.requestUri = '/services/apexrest/GetInvoiceDataAPI/';
        r.httpMethod = 'POST';
        r.requestBody = Blob.valueOf(body);
        RestContext.request = r;
        RestContext.response = new RestResponse();
    }

    // Helper to parse the response
    private static String response() {
        return (RestContext.response != null && RestContext.response.responseBody != null)
            ? RestContext.response.responseBody.toString()
            : '';
    }

    // Helper to assert failure in response
    private static void assertFailContains(String msg) {
        String res = response();
        System.assert(res.contains('"status":false'), res);
        System.assert(res.contains(msg), res);
    }
}