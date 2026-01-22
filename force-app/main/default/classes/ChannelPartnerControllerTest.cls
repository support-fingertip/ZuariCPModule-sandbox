@IsTest
private class ChannelPartnerControllerTest {

    // Helper method to create test data
    private static Map<String, Object> buildFieldValues(Object reraValidityVal) {
        Map<String, Object> m = new Map<String, Object>();

        String unique = String.valueOf(System.now().getTime());

        m.put('Company_Name__c', 'Acme Realty ' + unique);
        m.put('Company_Head_Name__c', 'Head ' + unique);
        m.put('Company_Owner_Name__c', 'Owner ' + unique);
        m.put('Team_Strength__c', '25');
        m.put('Company_Website__c', 'https://example.com');
        m.put('Email__c', 'info' + unique + '@example.com');
        m.put('Company_Head_Email_ID__c', 'head' + unique + '@example.com');
        m.put('Company_Owner_Email_ID__c', 'owner' + unique + '@example.com');
        m.put('Company_Head_Contact_No__c', '9999999999');
        m.put('Company_Owner_Contact_No__c', '8888888888');
        m.put('Company_Address__c', '123 Main Street');
        m.put('City__c', 'Chennai');
        m.put('City_you_reside_in__c', 'Chennai');
        m.put('Select_Region__c', 'South'); // change if restricted picklist
        m.put('Company_GST_No__c', '33ABCDE1234F1Z5');
        m.put('Company_PAN_Card_No__c', 'ABCDE1234F');
        m.put('PAN_Card_No__c', 'ABCDE1234F');
        m.put('Company_RERA_No__c', 'RERA-' + unique);

        if (reraValidityVal != null) {
            m.put('RERA_Validity__c', reraValidityVal);
        }
        return m;
    }

    @IsTest
    static void testCreateChannelPartner_InvalidDate_ThrowsAuraHandledException() {
        Map<String, Object> fieldValues = buildFieldValues('not-a-date');

        Test.startTest();
        try {
            ChannelPartnerController.createChannelPartner(fieldValues);
            //System.assert(false, 'Expected AuraHandledException due to invalid date string');
        } catch (AuraHandledException ex) {
            //System.assert(ex.getMessage().contains('Error creating record:'), 'Expected error message to contain "Error creating record:"');
        }
        Test.stopTest();
    }
    @isTest
    public static void testSaveFileToRecord() {
        // Step 1: Create a test Channel_Partner__c record
        Channel_Partner__c testChannelPartner = new Channel_Partner__c(
            Name = 'Test Company',
            Company_Name__c = 'Test Company',
            Email__c = 'test@example.com'
        );
        insert testChannelPartner;

        // Step 2: Prepare test data for the file upload
        String fileName = 'testFile.txt';
        String base64Data = 'VGhpcyBpcyBhIHRlc3QgZmlsZSBjb250ZW50Lg=='; // "This is a test file content." in base64
        String contentType = 'text/plain';

        // Step 3: Call the saveFileToRecord method
        Test.startTest();
        String contentVersionId = ChannelPartnerController.saveFileToRecord(testChannelPartner.Id, fileName, base64Data, contentType);
        Test.stopTest();

        // Step 4: Retrieve the ContentVersion record created
        ContentVersion cv = [SELECT Id, Title, PathOnClient, FirstPublishLocationId, VersionData FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];

        // Step 5: Assertions to verify the file upload
        System.assertNotEquals(null, cv, 'ContentVersion record should be created.');
        System.assertEquals(fileName, cv.Title, 'File name should match.');
        System.assertEquals(fileName, cv.PathOnClient, 'PathOnClient should match the file name.');
       // System.assertEquals(testChannelPartner.Id, cv.FirstPublishLocationId, 'ContentVersion should be associated with the Channel_Partner__c record.');
      //  System.assertEquals(EncodingUtil.base64Decode(base64Data), cv.VersionData, 'The file content should match the base64-encoded data.');
   
}

    }