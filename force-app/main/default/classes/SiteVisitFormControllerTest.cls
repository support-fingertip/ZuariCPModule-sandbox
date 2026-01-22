@IsTest
private class SiteVisitFormControllerTest {
    
    @isTest
    public static void testmethod1(){
        User testUser = new User(
            LastName = 'TestUser',
            Email = 'testuser' + System.currentTimeMillis() + '@test.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        SiteVisitFormController.getProjectPicklistValues();
        SiteVisitFormController.getProjectPicklistValues1();
        SiteVisitFormController.getCountryAndCode();
        Id salesRecordTypeId = Schema.SObjectType.Related_Source__c.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
          Id salesRecordTypeId1 = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Id preSalesRecordTypeId = Schema.SObjectType.Related_Source__c.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
         Lead lad2 = new Lead( LastName = 'test', Allocated_Project__c = 'Zuari Garden City', Phone__c = '9182748512',Secondary_Phone__c = '9182748514', Lead_Status__c = 'Sales Follow Up', RecordTypeId = salesRecordTypeId1,Source_Type__c='Digital Marketing');
        insert lad2;
        Related_Source__c lad = new Related_Source__c( Allocated_Project__c = 'Zuari Garden City', Phone__c = '9182748514',Secondary_Phone__c = '9182748513', Lead_Status1__c = 'New',OwnerId = testUser.Id,Source_Type__c='Digital Marketing',SLead__c=lad2.id);
        insert lad;
        Related_Source__c lad1 = new Related_Source__c( Allocated_Project__c = 'Zuari Garden City', Phone__c = '9182748512',Secondary_Phone__c = '9182748514', Lead_Status1__c = 'Sales Follow Up', RecordTypeId = salesRecordTypeId,Source_Type__c='Digital Marketing',SLead__c=lad2.id );
        insert lad1;
        
        
        Related_Source__c lad5 = new Related_Source__c( Allocated_Project__c = 'Zuari Garden City', Phone__c = '9182741123',Secondary_Phone__c = '9182749990', Lead_Status1__c = 'New', RecordTypeId = preSalesRecordTypeId,Source_Type__c='Digital Marketing',SLead__c=lad2.id );
        insert lad5;
        
        
        
        /*Related_Source__c rc = new Related_Source__c();
        rc.SLead__c=lad.Id;
        rc.Allocated_Project__c= lad.Allocated_Project__c;
        rc.Phone__c = lad.Phone__c;
        insert rc;*/
        Site_Visit__c sv = new Site_Visit__c(Date__c = System.now() + 3,Status__c = 'Scheduled', Project__c = 'Zuari Garden City', OTP__c='0001', Related_Source__c = lad.Id,Source_Type__c='Digital Marketing' );
        insert sv;
        
        sv.Status__c='Verified by GRE';
        update sv;
        
        
        Site_Visit__c svs = new Site_Visit__c(Date__c = System.now() + 3,Status__c = 'Scheduled', Project__c = 'Zuari Garden City', OTP__c='0001', Related_Source__c = lad.Id,Source_Type__c='Digital Marketing');
        insert svs;
         
        Site_Visit__c sv1 = [Select Id,Name,OTP__c from Site_Visit__c where Id =: svs.id];
         Site_Visit__c sv2 = [Select Id,Name,OTP__c from Site_Visit__c where Id =: sv.id];
        SiteVisitFormController.checkLeadWithPhoneProject(lad.Allocated_Project__c,lad.Phone__c);
        
        SiteVisitFormController.checkLeadWithPhoneProject(lad1.Allocated_Project__c,sv1.OTP__c);
         SiteVisitFormController.checkLeadWithPhoneProject(lad2.Allocated_Project__c,sv2.OTP__c);
         SiteVisitFormController.checkLeadWithPhoneProject(lad5.Allocated_Project__c,'645637');
        SiteVisitFormController.getLead(lad.Id);
        SiteVisitFormController.leadNotExists(lad.Id);
        //SiteVisitFormController.duplicateLeadExists(lad);
        SiteVisitFormController.duplicateLeadExists(lad5);
        DateTime dt = system.Now();
        SiteVisitFormController.leadExists('0000',lad.Phone__c,lad.Allocated_Project__c,dt,'First',lad);
        SiteVisitFormController.leadExists('0000',lad.Phone__c,lad.Allocated_Project__c,dt,'First',lad);
        SiteVisitFormController.leadExists('0001',lad.Phone__c,lad.Allocated_Project__c,dt,'First',lad);
        SiteVisitFormController.leadExists('0002',lad.Phone__c,lad.Allocated_Project__c,dt,'First',lad);
        
        SiteVisitFormController.leadExists(sv1.OTP__c,lad.Phone__c,lad.Allocated_Project__c,dt,'First',lad);
    }
    /*  static void makeData() {
// Dynamically get a valid picklist value for Allocated_Project__c
String allocatedProjectValue;
Schema.DescribeFieldResult fieldResult = Lead.Allocated_Project__c.getDescribe();
List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
if (!ple.isEmpty()) {
allocatedProjectValue = ple[0].getValue();
} else {
allocatedProjectValue = 'Default Project'; 
}

// Dynamically get a valid picklist value for Closed_Lost_Reason__c
String closedLostReasonValue;
Schema.DescribeFieldResult closedLostFieldResult = Lead.Closed_Lost_Reason__c.getDescribe();
List<Schema.PicklistEntry> closedLostPle = closedLostFieldResult.getPicklistValues();
if (!closedLostPle.isEmpty()) {
closedLostReasonValue = closedLostPle[0].getValue();
} else {
closedLostReasonValue = 'Default Reason';
}

User testUser = new User(
LastName = 'TestUser',
Email = 'testuser' + System.currentTimeMillis() + '@example.com',
Username = 'testuser' + System.currentTimeMillis() + '@test.com',
Alias = 'tuser',
TimeZoneSidKey = 'America/Los_Angeles',
LocaleSidKey = 'en_US',
EmailEncodingKey = 'UTF-8',
ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
LanguageLocaleKey = 'en_US'
);
insert testUser;

Id salesRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
Id preSalesRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();

Lead testLead = new Lead(
LastName = 'TestLead',
Company = 'Test Company',
Phone = '9876543210',
Allocated_Project__c = allocatedProjectValue,
Lead_Status__c = 'New',
RecordTypeId = preSalesRecordTypeId
);
insert testLead;

// Corrected Lead record with the required Closed Lost Reason field
Lead closedLead = new Lead(
LastName = 'ClosedLead',
Company = 'Test Company 2',
Phone = '9999999999',
Allocated_Project__c = allocatedProjectValue,
Lead_Status__c = 'Closed Lost',
Closed_Lost_Reason__c = closedLostReasonValue, // Added this line
RecordTypeId = salesRecordTypeId
);
insert closedLead;

Lead relatedLead = new Lead(
LastName = 'RelatedLead',
Company = 'Related Company',
Phone = '1234567890',
Allocated_Project__c = allocatedProjectValue,
Lead_Status__c = 'New',
RecordTypeId = preSalesRecordTypeId
);
insert relatedLead;

Related_Source__c relatedSource = new Related_Source__c(
SLead__c = relatedLead.Id
);
insert relatedSource;

Site_Visit__c scheduledSV = new Site_Visit__c(
SLead__c = testLead.Id,
OTP__c = '1234',
Status__c = 'Scheduled',
OwnerId = testUser.Id
);
insert scheduledSV;
}

//----------------------------------------------------------------------------------

// Test `getProjectPicklistValues`
@IsTest
static void testGetProjectPicklistValues() {
Test.startTest();
List<Map<String, String>> picklistValues = SiteVisitFormController.getProjectPicklistValues();
Test.stopTest();

System.assertNotEquals(null, picklistValues, 'Picklist values list should not be null.');
System.assert(picklistValues.size() > 0, 'Picklist values list should not be empty.');
}

//----------------------------------------------------------------------------------

// Test `checkLeadWithPhoneProject`
@IsTest
static void testCheckLeadWithPhoneProject() {
Lead testLead = [SELECT Allocated_Project__c, Phone FROM Lead WHERE LastName = 'TestLead' LIMIT 1];
Lead closedLead = [SELECT Allocated_Project__c, Phone FROM Lead WHERE LastName = 'ClosedLead' LIMIT 1];

Test.startTest();

String jsonResponse1 = SiteVisitFormController.checkLeadWithPhoneProject(testLead.Allocated_Project__c, testLead.Phone);
Map<String, Object> responseMap1 = (Map<String, Object>) JSON.deserialize(jsonResponse1, Map<String, Object>.class);
System.assertEquals('Lead Exist In Active Status', responseMap1.get('OTPStatus'), 'Active Lead status check failed.');

String jsonResponse2 = SiteVisitFormController.checkLeadWithPhoneProject(closedLead.Allocated_Project__c, closedLead.Phone);
Map<String, Object> responseMap2 = (Map<String, Object>) JSON.deserialize(jsonResponse2, Map<String, Object>.class);
System.assertEquals('Lead Exists And Not Active', responseMap2.get('OTPStatus'), 'Closed Lost Lead status check failed.');

String jsonResponse3 = SiteVisitFormController.checkLeadWithPhoneProject([SELECT Allocated_Project__c FROM Lead WHERE LastName = 'RelatedLead' LIMIT 1].Allocated_Project__c, '1234567890');
Map<String, Object> responseMap3 = (Map<String, Object>) JSON.deserialize(jsonResponse3, Map<String, Object>.class);
System.assertEquals('Lead Exist In Active Status', responseMap3.get('OTPStatus'), 'Related Source Lead status check failed.');

String jsonResponse4 = SiteVisitFormController.checkLeadWithPhoneProject('NonExistentProject', '1111111111');
Map<String, Object> responseMap4 = (Map<String, Object>) JSON.deserialize(jsonResponse4, Map<String, Object>.class);
System.assertEquals('No Lead Exists', responseMap4.get('OTPStatus'), 'Non-existent Lead status check failed.');

Test.stopTest();
}

//----------------------------------------------------------------------------------

// Test `getCountryAndCode`
@IsTest
static void testGetCountryAndCode() {
Test.startTest();
Map<String, String> countryMap = SiteVisitFormController.getCountryAndCode();
Test.stopTest();

System.assertNotEquals(null, countryMap, 'Country map should not be null.');
}

//----------------------------------------------------------------------------------

// Test `getLead`
@IsTest
static void testGetLead() {
Id leadId = [SELECT Id FROM Lead WHERE LastName = 'TestLead' LIMIT 1].Id;

Test.startTest();
Lead retrievedLead = SiteVisitFormController.getLead(leadId);
Test.stopTest();

System.assertNotEquals(null, retrievedLead, 'Retrieved lead should not be null.');
System.assertEquals(leadId, retrievedLead.Id, 'Retrieved lead ID should match the original ID.');
}

//----------------------------------------------------------------------------------

// Test `leadNotExists`
@IsTest
static void testLeadNotExists() {
Lead newLead = new Lead(
LastName = 'NewLead',
Company = 'New Company',
Phone = '7777777777'
);
insert newLead;

Test.startTest();
SiteVisitFormController.leadNotExists(newLead.Id);
Test.stopTest();

List<Site_Visit__c> svList = [SELECT Id, SLead__c, Status__c FROM Site_Visit__c WHERE SLead__c = :newLead.Id];

System.assertNotEquals(0, svList.size(), 'A new Site Visit record should be created.');
System.assertEquals('Verified by GRE', svList[0].Status__c, 'Status should be "Verified by GRE".');
}

//----------------------------------------------------------------------------------

// Test `leadExists`
@IsTest
static void testLeadExists() {
Lead testLead = [SELECT Id, Phone, Allocated_Project__c FROM Lead WHERE LastName = 'TestLead' LIMIT 1];
Site_Visit__c scheduledSV = [SELECT OTP__c, OwnerId FROM Site_Visit__c WHERE SLead__c = :testLead.Id LIMIT 1];

Test.startTest();

String result1 = SiteVisitFormController.leadExists(scheduledSV.OTP__c, testLead.Phone, testLead.Allocated_Project__c, System.now(), 'Site Visit', testLead);
System.assertEquals('OTP Matched', result1, 'Result should indicate OTP was matched.');

Lead walkinLead = [SELECT Id, Phone, Allocated_Project__c FROM Lead WHERE LastName = 'RelatedLead' LIMIT 1];
String result2 = SiteVisitFormController.leadExists('0000', walkinLead.Phone, walkinLead.Allocated_Project__c, System.now(), 'Site Visit', walkinLead);
System.assertEquals('OTP Validated', result2, 'Result should indicate OTP was validated for walk-in.');

String result3 = SiteVisitFormController.leadExists('9999', testLead.Phone, testLead.Allocated_Project__c, System.now(), 'Site Visit', testLead);
System.assertEquals('OTP Not Matched', result3, 'Result should indicate OTP was not matched.');

String result4 = SiteVisitFormController.leadExists('0000', testLead.Phone, testLead.Allocated_Project__c, System.now(), 'Site Visit', testLead);
System.assertEquals('OTP Not Matched', result4, 'Result should be "OTP Not Matched" if a scheduled SV exists for a walk-in.');

Test.stopTest();
}

*/
}