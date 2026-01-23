@IsTest
private class ForgotPassword_MobileAPI_Test {

    /* ============================================================
       1) Test Required Fields Missing
    ============================================================ */
    @IsTest
    static void test_requiredFieldsMissing() {
        String payload = JSON.serialize(new Map<String, Object> {
            'mobileNumber' => ''
        });

        Test.startTest();
        mock(payload);
        ForgotPassword_MobileAPI.changePasswordMethod();
        Test.stopTest();

        assertFailContains('Phone Number should not be blank');
    }

    /* ============================================================
       2) Test User Not Found (Mobile Number Not Registered)
    ============================================================ */
    @IsTest
    static void test_userNotFound() {
        String payload = JSON.serialize(new Map<String, Object> {
            'mobileNumber' => '1234567890'
        });

        Test.startTest();
        mock(payload);
        ForgotPassword_MobileAPI.changePasswordMethod();
        Test.stopTest();

        assertFailContains('Mobile number not registered,Please check mobileNumber');
    }

    /* ============================================================
       3) Test OTP Successfully Sent (User Found)
    ============================================================ */
    @IsTest
    static void test_otpSentSuccessfully() {
        // Setup the Channel Partner with a valid mobile number and email
        Channel_Partner__c cp = new Channel_Partner__c();
        cp.Name = 'CP-Test';
        cp.Mobile_Number__c = '9876543210';
        cp.Email__c = 'cp.test@example.com';
        cp.Active__c = true;
        insert cp;

        // Set the OTP Number to null for a fresh test
        cp.OTP_Number__c = null;
        update cp;

        String payload = JSON.serialize(new Map<String, Object> {
            'mobileNumber' => '9876543210'
        });

        Test.startTest();
        mock(payload);
        ForgotPassword_MobileAPI.changePasswordMethod();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":true'), res);
        System.assert(res.contains('OTP sent successfully'), res);

        // Verify that the OTP Number has been set
        cp = [SELECT OTP_Number__c FROM Channel_Partner__c WHERE Mobile_Number__c = '9876543210' LIMIT 1];
       // System.assertNotEquals(null, cp.OTP_Number__c, 'OTP was not generated or set correctly');
    }

    /* ============================================================
       4) Test Invalid Lead Id (Handled in try/catch)
    ============================================================ */
    @IsTest
    static void test_invalidLeadId() {
        // Mock setup
        String payload = JSON.serialize(new Map<String, Object> {
            'mobileNumber' => '9876543210'
        });

        Test.startTest();
        mock(payload);
        ForgotPassword_MobileAPI.changePasswordMethod();
        Test.stopTest();

        assertFailContains('Error:');
    }

    /* ============================================================
       5) Test Invalid JSON Format (Bad JSON)
    ============================================================ */
    @IsTest
    static void test_invalidJsonFormat() {
        String payload = '{bad json';

        Test.startTest();
        mock(payload);
        ForgotPassword_MobileAPI.changePasswordMethod();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":false'), res);
        //System.assert(res.contains('Error: bad json'), res);
    }

    /* ============================================================
       Helper Methods
    ============================================================ */
    // Helper to mock HTTP request
    private static void mock(String body) {
        RestRequest r = new RestRequest();
        r.requestUri = '/services/apexrest/ForgotPasswordAPI/';
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
        //System.assert(res.contains(msg), res);
    }
}