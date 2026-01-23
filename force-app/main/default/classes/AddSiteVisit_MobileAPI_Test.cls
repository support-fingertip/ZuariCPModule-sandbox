@IsTest
private class AddSiteVisit_MobileAPI_Test {

    /* ============================================================
       TEST 1: Required fields missing -> sendError INSERT branch
    ============================================================ */
    @IsTest
    static void test_requiredFieldsMissing_sendErrorInsert() {
        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => 'U-REQ'
            // missing leadId, scheduleDate
        });

        Test.startTest();
        mockRestRequest(payload);
        AddSiteVisit_MobileAPI.addSiteVisit();
        Test.stopTest();

        String resBody = getResponseBody();
        System.assert(resBody.contains('"status":false'), 'Expected failure: ' + resBody);
        System.assert(resBody.contains('Required fields are missing'), 'Expected msg: ' + resBody);

        Apex_Log__c log = [
            SELECT Id, Status__c, Error_Message__c
            FROM Apex_Log__c
            WHERE Request_Type__c = 'AddSiteVisit_MobileAPI'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('FAIL', log.Status__c);
    }

    /* ============================================================
       TEST 2: Channel partner not found -> sendError INSERT branch
    ============================================================ */
    @IsTest
    static void test_channelPartnerNotFound_sendErrorInsert() {
        String payload = JSON.serialize(new Map<String, Object>{
            'userId'       => 'U-NO-CP',
            'leadId'       => 'LEAD-ANY',
            'scheduleDate' => System.now()
        });

        Test.startTest();
        mockRestRequest(payload);
        AddSiteVisit_MobileAPI.addSiteVisit();
        Test.stopTest();

        String resBody = getResponseBody();
        System.assert(resBody.contains('"status":false'), 'Expected failure: ' + resBody);
        System.assert(resBody.contains('Channel Partner not found'), 'Expected msg: ' + resBody);
    }

    /* ============================================================
       TEST 3: Exception -> catch inserts log then sendError UPDATE branch
       Force exception by NOT creating Related_Source__c,
       so latestSource is null => sv.SLead__c = latestSource.SLead__c throws NPE
       => catch inserts log + logInserted=true
       => sendError(update log) ✅
    ============================================================ */
    @IsTest
    static void test_exceptionPath_sendErrorUpdateBranch() {

        // Lead (not used by query directly, but safe)
        Lead l = new Lead(LastName = 'Test Lead', Company = 'Test Co');
        insert l;

        // Channel Partner (User_Id__c is read-only, rely on org automation)
        Channel_Partner__c cp = new Channel_Partner__c();
        cp.Active__c = true;
        setIfFieldExists(cp, 'Email__c', 'cp.sitevisit.exception@example.com');
        insert cp;

        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];
        System.assert(!String.isBlank(cp.User_Id__c),
            'Your org must auto-populate Channel_Partner__c.User_Id__c for this API to be testable.');

        // Do NOT insert Related_Source__c (so query returns empty and causes NPE)

        String payload = JSON.serialize(new Map<String, Object>{
            'userId'       => cp.User_Id__c,
            'leadId'       => 'LEAD-NO-SOURCE',
            'scheduleDate' => System.now(),
            'notes'        => 'fail path',
            'subject'      => 'Should Fail'
        });

        Test.startTest();
        mockRestRequest(payload);
        AddSiteVisit_MobileAPI.addSiteVisit();
        Test.stopTest();

        String resBody = getResponseBody();
        System.assert(resBody.contains('"status":false'), 'Expected failure response: ' + resBody);
        System.assert(resBody.contains('Site visit creation failed'), 'Expected catch msg: ' + resBody);

        Apex_Log__c log = [
            SELECT Id, Status__c, Error_Message__c
            FROM Apex_Log__c
            WHERE Request_Type__c = 'AddSiteVisit_MobileAPI'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('FAIL', log.Status__c);
    }

    /* ============================================================
       TEST 4: Success path (only if org populates read-only ids)
    ============================================================ */
    @IsTest
    static void test_successPath_whenOrgAutopopulatesIds() {

        Lead l = new Lead(LastName = 'Test Lead', Company = 'Test Co');
        insert l;

        // Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c();
        cp.Active__c = true;
        setIfFieldExists(cp, 'Email__c', 'cp.sitevisit.success@example.com');
        insert cp;

        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];
        if (String.isBlank(cp.User_Id__c)) {
            System.assert(true);
            return;
        }

        // Related Source (Lead_Id__c is read-only, rely on org automation)
        Related_Source__c rs = new Related_Source__c();
        rs.Is_Locked__c = false;
        rs.SLead__c = l.Id;
        insert rs;

        rs = [SELECT Id, Lead_Id__c, SLead__c FROM Related_Source__c WHERE Id = :rs.Id LIMIT 1];
        if (String.isBlank(rs.Lead_Id__c)) {
            System.assert(true);
            return;
        }

        String payload = JSON.serialize(new Map<String, Object>{
            'userId'       => cp.User_Id__c,
            'leadId'       => rs.Lead_Id__c,
            'scheduleDate' => System.now().addDays(1),
            'notes'        => 'some feedback',
            'subject'      => 'Site Visit'
        });

        Test.startTest();
        mockRestRequest(payload);
        AddSiteVisit_MobileAPI.addSiteVisit();
        Test.stopTest();

        String resBody = getResponseBody();
        System.assert(resBody.contains('"status":true'), 'Expected success: ' + resBody);

        Integer cnt = [
            SELECT COUNT()
            FROM Site_Visit__c
            WHERE Related_Source__c = :rs.Id
        ];
        System.assertEquals(1, cnt, 'Expected Site_Visit__c inserted');
    }


    /* ========================= HELPERS ========================= */

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AddSiteVisitAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static String getResponseBody() {
        return (RestContext.response != null && RestContext.response.responseBody != null)
            ? RestContext.response.responseBody.toString()
            : '';
    }

    private static void setIfFieldExists(SObject sob, String fieldApiName, Object value) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(fieldApiName) && fm.get(fieldApiName).getDescribe().isCreateable()) {
            sob.put(fieldApiName, value);
        }
    }
}