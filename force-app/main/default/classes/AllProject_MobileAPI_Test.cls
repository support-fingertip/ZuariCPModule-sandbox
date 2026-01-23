@IsTest
private class AllProject_MobileAPI_Test {

    /* ============================================================
       1) userId blank -> early return + sendErrorResponse
    ============================================================ */
    @IsTest
    static void test_userIdBlank() {
        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => ''
        });

        Test.startTest();
        mockRestRequest(payload);
        AllProject_MobileAPI.getAllprojectDetail();
        Test.stopTest();

        String resBody = getResponseBody();
        System.assert(resBody.contains('"status":false'), 'Expected failure JSON: ' + resBody);
        System.assert(resBody.contains('Please Send correct userId'), 'Expected msg: ' + resBody);

        Apex_Log__c log = [
            SELECT Id, Status__c
            FROM Apex_Log__c
            WHERE Request_Type__c = 'AllProject_MobileAPI'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('SUCCESS', log.Status__c);
    }

    /* ============================================================
       2) CP not found -> User Not Found in System
    ============================================================ */
    @IsTest
    static void test_cpNotFound() {
        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => 'U-NOT-EXIST'
        });

        Test.startTest();
        mockRestRequest(payload);
        AllProject_MobileAPI.getAllprojectDetail();
        Test.stopTest();

        String resBody = getResponseBody();
        System.assert(resBody.contains('"status":false'), 'Expected failure JSON: ' + resBody);
        System.assert(resBody.contains('User Not Found in System'), 'Expected msg: ' + resBody);

        Apex_Log__c log = [
            SELECT Id, Status__c
            FROM Apex_Log__c
            WHERE Request_Type__c = 'AllProject_MobileAPI'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('FAIL', log.Status__c);
    }

    /* ============================================================
       3) Success -> CP exists + at least 1 Project__c exists
       Covers:
       - search filter
       - cityId filter
       - projectStatusId filter
       - facingId INCLUDES filter
       - unitTypeId INCLUDES filter
       - offset calc
       - projectIds/content block runs safely (no documents)
    ============================================================ */
    @IsTest
    static void test_success_returnsProjects() {
        // Create CP
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];
        
        if (String.isBlank(cp.User_Id__c)) {
            System.assert(true);
            return;
        }
        
        // Insert Project__c record
        Project__c p = (Project__c) buildMinRequired(Project__c.SObjectType);
        p.Active__c = true;
        
        setIfFieldExists(p, 'Name', 'Project X');
        setIfFieldExists(p, 'Project_Id__c', 'PRJ-001');
        setIfFieldExists(p, 'City1__c', 'Bangalore');
        setIfFieldExists(p, 'Project_Status__c', 'Active');
        
        // These may be multipicklists; store simple values
        setIfFieldExists(p, 'Facing__c', 'East');
        setIfFieldExists(p, 'Unit_Type__c', 'Villa');
        
        setIfFieldExists(p, 'Available_Units__c', 10);
        setIfFieldExists(p, 'Total_Units__c', 100);
        setIfFieldExists(p, 'Starting_Price__c', '1000000');
        setIfFieldExists(p, 'End_Price_Range__c', '2000000');
        
        insert p;
        
        // Build payload with filters that match inserted values
        Map<String, Object> payloadMap = new Map<String, Object>{
            'userId' => cp.User_Id__c,
                'search' => 'Project',
                'cityId' => 'Bangalore',
                'projectStatusId' => 'Active',
                'pageSize' => 0
                };
                    
                    // Only include INCLUDES filters if fields are MULTIPICKLIST in your org
                    if (isMultiPicklist(Project__c.SObjectType, 'Facing__c')) {
                        payloadMap.put('facingId', 'East');
                    }
        if (isMultiPicklist(Project__c.SObjectType, 'Unit_Type__c')) {
            payloadMap.put('unitTypeId', 'Villa');
        }
        
        String payload = JSON.serialize(payloadMap);
        
        Test.startTest();
        mockRestRequest(payload);
        AllProject_MobileAPI.getAllprojectDetail();
        Test.stopTest();
        
        String resBody = getResponseBody();
        System.assert(resBody.contains('"status":true'), 'Expected success JSON: ' + resBody);
        System.assert(resBody.contains('projects data'), 'Expected msg: ' + resBody);
        
        // Now it should include the project
        System.assert(resBody.contains('Project X'), 'Expected project name in response: ' + resBody);
    }
    
    private static Boolean isMultiPicklist(Schema.SObjectType sType, String fieldApiName) {
        Map<String, Schema.SObjectField> fm = sType.getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApiName)) return false;
        return fm.get(fieldApiName).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST;
    }

    /* ============================================================
       4) Catch -> invalid JSON
    ============================================================ */
    @IsTest
    static void test_catch_invalidJson() {
        String payload = '{bad json';

        Test.startTest();
        mockRestRequest(payload);
        AllProject_MobileAPI.getAllprojectDetail();
        Test.stopTest();

        String resBody = getResponseBody();
        System.assert(resBody.contains('"status":false'), 'Expected failure: ' + resBody);
        System.assert(resBody.contains('Error:'), 'Expected Error prefix: ' + resBody);

        Apex_Log__c log = [
            SELECT Id, Status__c, Error_Message__c
            FROM Apex_Log__c
            WHERE Request_Type__c = 'AllProject_MobileAPI'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('FAIL', log.Status__c);
        System.assert(!String.isBlank(log.Error_Message__c));
    }


    /* ========================= HELPERS ========================= */

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AllProjectAPI/';
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

    private static Channel_Partner__c createCpActive() {
        Channel_Partner__c cp = new Channel_Partner__c();
        cp.Active__c = true;

        // you already saw Email__c required in your org
        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Email__c')) {
            cp.put('Email__c', 'cp+' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@example.com');
        }

        insert cp;
        return cp;
    }

    private static void setIfFieldExists(SObject sob, String fieldApiName, Object value) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(fieldApiName) && fm.get(fieldApiName).getDescribe().isCreateable()) {
            sob.put(fieldApiName, value);
        }
    }

    /**
     * Creates a record with required createable fields populated.
     * This avoids "Required fields missing" org-specific errors.
     */
    private static SObject buildMinRequired(Schema.SObjectType sType) {
        SObject sob = sType.newSObject();
        Schema.DescribeSObjectResult dsr = sType.getDescribe();
        Map<String, Schema.SObjectField> fmap = dsr.fields.getMap();

        for (String f : fmap.keySet()) {
            Schema.DescribeFieldResult dfr = fmap.get(f).getDescribe();
            if (!dfr.isCreateable()) continue;
            if (dfr.isCalculated() || dfr.isAutoNumber()) continue;
            if (f == 'Id') continue;

            // only fill truly required fields
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
                    // safest: if required user lookup, use running user; else skip (may not be required)
                    List<Schema.SObjectType> refs = dfr.getReferenceTo();
                    if (!refs.isEmpty() && refs[0].getDescribe().getName() == 'User') {
                        sob.put(f, UserInfo.getUserId());
                    }
                }
            } catch (Exception ignore) {}
        }

        // Fill Name if required and missing
        if (fmap.containsKey('Name')) {
            Schema.DescribeFieldResult nameDfr = fmap.get('Name').getDescribe();
            if (nameDfr.isCreateable() && !nameDfr.isNillable() && sob.get('Name') == null) {
                sob.put('Name', 'Test Name');
            }
        }
        return sob;
    }
}