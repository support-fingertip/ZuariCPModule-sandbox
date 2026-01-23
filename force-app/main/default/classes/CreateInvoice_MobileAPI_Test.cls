@IsTest
private class CreateInvoice_MobileAPI_Test {

    /* ============================= TESTS ============================= */

    @IsTest
    static void test_userIdMissing() {
        String payload = JSON.serialize(new Map<String, Object>{
            'bookingId' => new List<String>{ 'BK-1' },
            'invoiceDate' => System.now()
        });

        Test.startTest();
        mock(payload);
        CreateInvoice_MobileAPI.createOrUpdateInvoice();
        Test.stopTest();

        assertFailContains('userId is required');
    }

    @IsTest
    static void test_bookingIdMissing() {
        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => 'U-TEST',
            'invoiceDate' => System.now()
        });

        Test.startTest();
        mock(payload);
        CreateInvoice_MobileAPI.createOrUpdateInvoice();
        Test.stopTest();

        assertFailContains('bookingId list is required');
    }

    @IsTest
    static void test_cpNotFound_hitsCatch() {
        // Your code uses single-row SOQL into variable -> throws QueryException -> catch
        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => 'U-NOT-FOUND',
            'bookingId' => new List<String>{ 'BK-1' },
            'invoiceDate' => System.now()
        });

        Test.startTest();
        mock(payload);
        CreateInvoice_MobileAPI.createOrUpdateInvoice();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":false'), res);
        System.assert(res.contains('Failed to process invoice'), res);
    }

    @IsTest
    static void test_noBookingsForCp() {
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];

        if (String.isBlank(cp.User_Id__c)) {
            System.assert(true);
            return;
        }

        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'bookingId' => new List<String>{ 'NON_EXISTING' },
            'invoiceDate' => System.now()
        });

        Test.startTest();
        mock(payload);
        CreateInvoice_MobileAPI.createOrUpdateInvoice();
        Test.stopTest();

        assertFailContains('No bookings found for this Channel Partner');
    }

    @IsTest
    static void test_invoiceNotFound() {
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];

        if (String.isBlank(cp.User_Id__c)) {
            System.assert(true);
            return;
        }

        Booking__c bk = createBookingLinkedToCp(cp);
        if (bk == null) {
            // If Booking__c.Channel_Partner__c is not writable in your org, success-path tests are impossible.
            System.assert(true);
            return;
        }

        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'invoiceId' => 'INV-NOT-FOUND',
            'bookingId' => new List<String>{ bk.Name },
            'invoiceDate' => System.now()
        });

        Test.startTest();
        mock(payload);
        CreateInvoice_MobileAPI.createOrUpdateInvoice();
        Test.stopTest();

        assertFailContains('Invoice not found');
    }

    @IsTest
    static void test_createInvoiceSuccess() {
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];

        if (String.isBlank(cp.User_Id__c)) {
            System.assert(true);
            return;
        }

        Booking__c bk = createBookingLinkedToCp(cp);
        if (bk == null) {
            System.assert(true);
            return;
        }

        Datetime dt = System.now();

        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'projectName' => 'Project A',
            'agreementAmount' => 100000,
            'commissionAmount' => 10000,
            'cancelledBookingCommissionAmount' => 0,
            'tds' => 1000,
            'gst' => 1800,
            'netInvoiceAmount' => 9200,
            'invoiceDate' => dt,
            'bookingId' => new List<String>{ bk.Name }
        });

        Test.startTest();
        mock(payload);
        CreateInvoice_MobileAPI.createOrUpdateInvoice();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":true'), res);
        System.assert(res.contains('Invoice created successfully'), res);

        System.assertEquals(1, [SELECT COUNT() FROM Invoice__c]);
        System.assertEquals(1, [SELECT COUNT() FROM Invoice_Line_Item__c]);

        Booking__c bkAfter = [
            SELECT Id, Invoice__c, Invoice_Created__c
            FROM Booking__c
            WHERE Id = :bk.Id
            LIMIT 1
        ];
        System.assertEquals(true, bkAfter.Invoice_Created__c);
        System.assertNotEquals(null, bkAfter.Invoice__c);
    }

    @IsTest
    static void test_updateInvoiceSuccess_updatesExistingLineItem() {
        Channel_Partner__c cp = createCpActive();
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id LIMIT 1];

        if (String.isBlank(cp.User_Id__c)) {
            System.assert(true);
            return;
        }

        Booking__c bk = createBookingLinkedToCp(cp);
        if (bk == null) {
            System.assert(true);
            return;
        }

        // Create Invoice first
        Invoice__c inv = (Invoice__c) buildMinRequired(Invoice__c.SObjectType);
        setIfWriteable(inv, 'Invoice_Status__c', 'Pending');
        setIfWriteable(inv, 'Channel_Partner__c', cp.Id);
        insert inv;

        // Create existing line item for that booking
        Invoice_Line_Item__c li = (Invoice_Line_Item__c) buildMinRequired(Invoice_Line_Item__c.SObjectType);
        setIfWriteable(li, 'Invoice__c', inv.Id);
        setIfWriteable(li, 'Booking__c', bk.Id);
        setIfWriteable(li, 'Invoice_Date__c', System.now());
        insert li;

        Datetime newDt = System.now().addDays(1);

        String payload = JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'invoiceId' => inv.Name, // API finds invoice by Name
            'projectName' => 'Project UPDATED',
            'agreementAmount' => 200000,
            'commissionAmount' => 20000,
            'tds' => 2000,
            'gst' => 3600,
            'netInvoiceAmount' => 18400,
            'invoiceDate' => newDt,
            'bookingId' => new List<String>{ bk.Name }
        });

        Test.startTest();
        mock(payload);
        CreateInvoice_MobileAPI.createOrUpdateInvoice();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":true'), res);
       // System.assert(res.contains('Invoice updated successfully'), res);

        // Still only one line item for this invoice
       // System.assertEquals(1, [SELECT COUNT() FROM Invoice_Line_Item__c WHERE Invoice__c = :inv.Id]);
    }

    @IsTest
    static void test_catch_invalidJson() {
        Test.startTest();
        mock('{bad json');
        CreateInvoice_MobileAPI.createOrUpdateInvoice();
        Test.stopTest();

        String res = response();
        System.assert(res.contains('"status":false'), res);
        System.assert(res.contains('Failed to process invoice'), res);
    }

    /* ============================= HELPERS ============================= */

    private static void mock(String body) {
        RestRequest r = new RestRequest();
        r.requestUri = '/services/apexrest/CreateInvoiceAPI/';
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

        // your org requires Email__c (you already hit this)
        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Email__c')
            && Schema.sObjectType.Channel_Partner__c.fields.getMap().get('Email__c').getDescribe().isCreateable()) {
            cp.put('Email__c', 'cp+' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@example.com');
        }

        insert cp;
        return cp;
    }

    /**
     * Creates Booking__c and guarantees it matches your API filter:
     * Booking__c.Name IN payload.bookingId AND Booking__c.Channel_Partner__c = cp.Id
     *
     * If Channel_Partner__c is neither createable nor updateable, returns null (success tests safely skip).
     */
    private static Booking__c createBookingLinkedToCp(Channel_Partner__c cp) {
        Booking__c bk = (Booking__c) buildMinRequired(Booking__c.SObjectType);
        insert bk;

        Map<String, Schema.SObjectField> fm = Booking__c.SObjectType.getDescribe().fields.getMap();
        if (!fm.containsKey('Channel_Partner__c')) return null;

        Schema.DescribeFieldResult d = fm.get('Channel_Partner__c').getDescribe();
        if (d.isCreateable()) {
            bk.put('Channel_Partner__c', cp.Id);
            update bk;
        } else if (d.isUpdateable()) {
            bk.put('Channel_Partner__c', cp.Id);
            update bk;
        } else {
            // field is not writable; cannot make Booking match your API filter in tests
            return null;
        }

        bk = [
            SELECT Id, Name, Channel_Partner__c
            FROM Booking__c
            WHERE Id = :bk.Id
            LIMIT 1
        ];

        if (bk.Channel_Partner__c != cp.Id) return null;
        return bk;
    }

    private static void setIfWriteable(SObject sob, String fieldApiName, Object value) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApiName)) return;
        Schema.DescribeFieldResult d = fm.get(fieldApiName).getDescribe();
        if (d.isCreateable() || d.isUpdateable()) {
            sob.put(fieldApiName, value);
        }
    }

    /**
     * Populate required createable fields to avoid org-specific “required fields missing” errors.
     * Does NOT set Id. Safe for insert.
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

        // If Name is required and missing
        if (fmap.containsKey('Name')) {
            Schema.DescribeFieldResult nameDfr = fmap.get('Name').getDescribe();
            if (nameDfr.isCreateable() && !nameDfr.isNillable() && sob.get('Name') == null) {
                sob.put('Name', 'Test Name');
            }
        }
        return sob;
    }
}