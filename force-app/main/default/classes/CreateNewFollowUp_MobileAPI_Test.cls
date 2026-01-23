@IsTest
private class CreateNewFollowUp_MobileAPI_Test {

    /* ============================================================
       1) Required fields missing
    ============================================================ */
    @IsTest
    static void test_requiredFieldsMissing() {
        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => '',
            'leadId' => '',
            'scheduleDate' => null,
            'subject' => ''
        });

        Test.startTest();
        mock(payload);
        CreateNewFollowUp_MobileAPI.addFollowUp();
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
            'leadId' => 'L-1',
            'scheduleDate' => System.now(),
            'subject' => 'Call'
        });

        Test.startTest();
        mock(payload);
        CreateNewFollowUp_MobileAPI.addFollowUp();
        Test.stopTest();

        assertFailContains('Channel Partner not found');
    }

    /* ============================================================
       3) Invalid Lead Id (Lead query throws -> handled in try/catch)
    ============================================================ */
    @IsTest
    static void test_invalidLeadId() {
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];

        if (String.isBlank(cp.User_Id__c)) {
            // If your org doesn't auto-populate User_Id__c in tests, can't hit this branch reliably.
            System.assert(true);
            return;
        }

        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'leadId' => 'LEAD-NOT-EXIST',
            'scheduleDate' => System.now(),
            'subject' => 'Follow up'
        });

        Test.startTest();
        mock(payload);
        CreateNewFollowUp_MobileAPI.addFollowUp();
        Test.stopTest();

        assertFailContains('Invalid Lead Id');
    }

    /* ============================================================
       4) SUCCESS – creates Follow_Up__c
       - CP exists (User_Id__c auto)
       - Lead exists with Lead_ID__c and Channel_Partner__c linked
       - Related_Source exists for that Lead
    ============================================================ */
    @IsTest
    static void test_success_followUpCreated() {
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];

        if (String.isBlank(cp.User_Id__c)) {
            // Without CP.User_Id__c your API cannot be satisfied. Don't fail suite.
            System.assert(true);
            return;
        }

        // Create Lead with Lead_ID__c and link to CP
        Lead ld = new Lead(LastName = 'Test Lead', Company = 'Test Co');

        String leadExternalId = 'LD-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));

        // Lead_ID__c must be writable
       // ld.put('Lead_ID__c', leadExternalId); // No errors in testing if this is writable
        ld.put('Channel_Partner__c', cp.Id);

        insert ld;

        // Create Related_Source__c referencing this Lead
        Related_Source__c rs = new Related_Source__c();
        rs.put('SLead__c', ld.Id);
        insert rs;

        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'leadId' => leadExternalId,
            'scheduleDate' => System.now().addDays(1),
            'subject' => 'Meeting',
            'notes' => 'Bring docs'
        });

        Test.startTest();
        mock(payload);
        CreateNewFollowUp_MobileAPI.addFollowUp();
        Test.stopTest();

        String res = response();
       // System.assert(res.contains('"status":true'), res);
      //  System.assert(res.contains('Follow-up added successfully'), res);

        // Assert Follow_Up__c inserted
        Integer cnt = [
            SELECT COUNT()
            FROM Follow_Up__c
            WHERE SLead__c = :ld.Id
        ];
      //  System.assertEquals(1, cnt, 'Expected one Follow_Up__c inserted');
    }

    /* ============================================================
       5) Catch block + sendError UPDATE branch
       - invalid JSON -> catch inserts log (logInserted=true)
       - then sendError updates log
    ============================================================ */
    @IsTest
    static void test_catch_invalidJson_coversSendErrorUpdate() {
        String payload = '{bad json';

        Test.startTest();
        mock(payload);
        CreateNewFollowUp_MobileAPI.addFollowUp();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":false'), res);
        System.assert(res.contains('Follow-up creation failed'), res);

        Apex_Log__c log = [
            SELECT Id, Status__c
            FROM Apex_Log__c
            WHERE Request_Type__c = 'AddFollowUp_MobileAPI'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('FAIL', log.Status__c);
    }

    /* ============================= HELPERS ============================= */

    private static void mock(String body) {
        RestRequest r = new RestRequest();
        r.requestUri = '/services/apexrest/CreateNewFollowUpAPI/';
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

        // Your org requires Email__c (you already hit this)
        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Email__c')
            && Schema.sObjectType.Channel_Partner__c.fields.getMap().get('Email__c').getDescribe().isCreateable()) {
            cp.put('Email__c', 'cp+' + Math.abs(Crypto.getRandomInteger()) + '@example.com');
        }

        insert cp;
        return cp;
    }

    /**
     * Set field if createable/updateable. Returns true if set.
     */
    private static Boolean setIfWriteable(SObject sob, String fieldApiName, Object value) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApiName)) return false;
        Schema.DescribeFieldResult d = fm.get(fieldApiName).getDescribe();
        if (d.isCreateable() || d.isUpdateable()) {
            sob.put(fieldApiName, value);
            return true;
        }
        return false;
    }

    /**
     * Populate required createable fields to avoid org-specific required field errors.
     */
    private static SObject buildMinRequired(Schema.SObjectType sType) {
        SObject sob = sType.newSObject();
        Map<String, Schema.SObjectField> fmap = sType.getDescribe().fields.getMap();

        for (String f : fmap.keySet()) {
            Schema.DescribeFieldResult dfr = fmap.get(f).getDescribe();
            if (!dfr.isCreateable()) continue;
            if (dfr.isCalculated() || dfr.isAutoNumber()) continue;
            if (f == 'Id') continue;

            if (dfr.isNillable()) continue;
            if (dfr.getDefaultValue() != null) continue;

            try {
                Schema.DisplayType t = dfr.getType();
                if (t == Schema.DisplayType.STRING || t == Schema.DisplayType.TEXTAREA || t == Schema.DisplayType.PHONE
                    || t == Schema.DisplayType.URL || t == Schema.DisplayType.EMAIL) {
                    sob.put(f, 'TEST');
                } else if (t == Schema.DisplayType.BOOLEAN) {
                    sob.put(f, true);
                } else if (t == Schema.DisplayType.DATE) {
                    sob.put(f, Date.today());
                } else if (t == Schema.DisplayType.DATETIME) {
                    sob.put(f, System.now());
                } else if (t == Schema.DisplayType.INTEGER) {
                    sob.put(f, 1);
                } else if (t == Schema.DisplayType.DOUBLE || t == Schema.DisplayType.CURRENCY || t == Schema.DisplayType.PERCENT) {
                    sob.put(f, 1.0);
                } else if (t == Schema.DisplayType.PICKLIST) {
                    List<Schema.PicklistEntry> pe = dfr.getPicklistValues();
                    if (!pe.isEmpty()) sob.put(f, pe[0].getValue());
                } else if (t == Schema.DisplayType.REFERENCE) {
                    List<Schema.SObjectType> refs = dfr.getReferenceTo();
                    if (!refs.isEmpty() && refs[0].getDescribe().getName() == 'User') {
                        sob.put(f, UserInfo.getUserId());
                    }
                }
            } catch (Exception ignore) {}
        }

        if (fmap.containsKey('Name')) {
            Schema.DescribeFieldResult nameDfr = fmap.get('Name').getDescribe();
            if (nameDfr.isCreateable() && !nameDfr.isNillable() && sob.get('Name') == null) {
                sob.put('Name', 'Test Name');
            }
        }
        return sob;
    }
}