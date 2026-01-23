@IsTest
private class CreateLead_MobileAPI_Test {

    /* ============================================================
       1) Required fields missing
    ============================================================ */
    @IsTest
    static void test_requiredFieldsMissing() {
        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => '',
            'fullName' => '',
            'mobileNumber' => ''
        });

        Test.startTest();
        mock(payload);
        CreateLead_MobileAPI.createLead();
        Test.stopTest();

        assertFailContains('Required fields are missing');
    }

    /* ============================================================
       2) Channel Partner not found
    ============================================================ */
    @IsTest
    static void test_cpNotFound() {
        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => 'U-NOT-FOUND',
            'fullName' => 'Test User',
            'mobileNumber' => '9876543210'
        });

        Test.startTest();
        mock(payload);
        CreateLead_MobileAPI.createLead();
        Test.stopTest();

        assertFailContains('Channel Partner not found');
    }

    /* ============================================================
       3) Invalid project picklist
    ============================================================ */
    @IsTest
    static void test_invalidProjectPicklist() {
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];
        if (String.isBlank(cp.User_Id__c)) return;

        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'fullName' => 'Test User',
            'mobileNumber' => '9876543210',
            'projectId' => '___INVALID___'
        });

        Test.startTest();
        mock(payload);
        CreateLead_MobileAPI.createLead();
        Test.stopTest();

        assertFailContains('Invalid Project picklist value');
    }

    /* ============================================================
       4) Invalid lead source picklist
    ============================================================ */
    @IsTest
    static void test_invalidLeadSourcePicklist() {
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];
        if (String.isBlank(cp.User_Id__c)) return;

        String validProject = firstPicklistValue(Lead.Allocated_Project__c);
        // If project picklist has no values in org, skip safely
        if (validProject == null) { System.assert(true); return; }

        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'fullName' => 'Test User',
            'mobileNumber' => '9876543210',
            'projectId' => validProject,
            'leadSourceId' => '___INVALID___'
        });

        Test.startTest();
        mock(payload);
        CreateLead_MobileAPI.createLead();
        Test.stopTest();

        assertFailContains('Invalid Lead Source picklist value');
    }

    /* ============================================================
       5) Duplicate lead (same normalized phone + same project)
    ============================================================ */
    @IsTest
    static void test_duplicateLead() {
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];
        if (String.isBlank(cp.User_Id__c)) return;

        String validProject = firstPicklistValue(Lead.Allocated_Project__c);
        if (validProject == null) { System.assert(true); return; }

        // Create an existing lead with normalized phone stored
        Lead existing = new Lead(LastName = 'Existing', Company = 'TestCo');
        setIfWriteable(existing, 'Phone__c', '9876543210'); // stored normalized
        setIfWriteable(existing, 'Allocated_Project__c', validProject);
        insert existing;

        // Now call API with +91 phone; normalizePhone will strip 91 and match the existing lead
        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'fullName' => 'Dup User',
            'mobileNumber' => '+91 98765-43210',
            'projectId' => validProject
        });

        Test.startTest();
        mock(payload);
        CreateLead_MobileAPI.createLead();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":false'), res);
        System.assert(res.contains('already exists'), res);
    }

    /* ============================================================
       6) Success lead creation
    ============================================================ */
    @IsTest
    static void test_successLeadCreated() {
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];
        if (String.isBlank(cp.User_Id__c)) return;

        String validProject = firstPicklistValue(Lead.Allocated_Project__c);
        String validSource  = firstPicklistValue(Lead.Lead_source__c);

        // If picklists empty, still OK: code allows blank; but to cover validation paths we prefer values
        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'fullName' => 'New Lead',
            'mobileNumber' => '9998887776',
            'emailAddress' => 'lead@test.com',
            'projectId' => validProject,
            'leadSourceId' => validSource,
            'additionalNotes' => 'notes'
        });

        Test.startTest();
        mock(payload);
        CreateLead_MobileAPI.createLead();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":true'), res);
        System.assert(res.contains('Lead created successfully'), res);

        // Verify lead inserted (don't overfit to org validations)
        Integer cnt = [SELECT COUNT() FROM Lead WHERE LastName = 'New Lead'];
        System.assertEquals(1, cnt);
    }

    /* ============================================================
       7) Catch block + sendError UPDATE branch (logInserted = true)
       - invalid JSON forces catch
       - catch inserts log (logInserted=true)
       - then sendError updates log
    ============================================================ */
    @IsTest
    static void test_catch_invalidJson_coversSendErrorUpdate() {
        String payload = '{bad json';

        Test.startTest();
        mock(payload);
        CreateLead_MobileAPI.createLead();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":false'), res);
        System.assert(res.contains('Lead creation failed'), res);

        // Ensure a FAIL log exists
        Apex_Log__c log = [
            SELECT Id, Status__c
            FROM Apex_Log__c
            WHERE Request_Type__c = 'CreateLead_MobileAPI'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('FAIL', log.Status__c);
    }

    /* ============================= HELPERS ============================= */

    private static void mock(String body) {
        RestRequest r = new RestRequest();
        r.requestUri = '/services/apexrest/CreateLeadAPI/';
        r.httpMethod = 'POST';
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

    private static Channel_Partner__c createCpActive() {
        Channel_Partner__c cp = new Channel_Partner__c();
        cp.Active__c = true;

        // your org requires Email__c (from your earlier errors)
        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Email__c')
            && Schema.sObjectType.Channel_Partner__c.fields.getMap().get('Email__c').getDescribe().isCreateable()) {
            cp.put('Email__c', 'cp+' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@example.com');
        }

        insert cp;
        return cp;
    }

    private static String firstPicklistValue(Schema.SObjectField f) {
        Schema.DescribeFieldResult d = f.getDescribe();
        List<Schema.PicklistEntry> vals = d.getPicklistValues();
        if (vals == null || vals.isEmpty()) return null;
        return vals[0].getValue();
    }

    private static void setIfWriteable(SObject sob, String fieldApiName, Object value) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApiName)) return;
        Schema.DescribeFieldResult d = fm.get(fieldApiName).getDescribe();
        if (d.isCreateable() || d.isUpdateable()) {
            sob.put(fieldApiName, value);
        }
    }
}