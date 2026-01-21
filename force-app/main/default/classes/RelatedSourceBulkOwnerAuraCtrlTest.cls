@IsTest
public class RelatedSourceBulkOwnerAuraCtrlTest {

    @TestSetup
    static void setupTestData() {
        // Create Users
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            Username = 'testuser1@example.com.' + System.currentTimeMillis(),
            Alias = 'tuser1',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        User u2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'testuser2@example.com',
            Username = 'testuser2@example.com.' + System.currentTimeMillis(),
            Alias = 'tuser2',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert new List<User>{u1, u2};

        // Create Related Source records
        List<Related_Source__c> sources = new List<Related_Source__c>();
        for(Integer i=0; i<5; i++){
            sources.add(new Related_Source__c(
                OwnerId = u1.Id,
                Allocated_Project__c = 'Zuari Garden City'
            ));
        }
        insert sources;
    }

    @IsTest
    static void testFetchRelatedSources() {
        List<Related_Source__c> results;

        // Without filters
        RelatedSourceBulkOwnerAuraCtrl.fetchRelatedSources(null, null, null, null);
        

        // With fromUserId filter
        User u = [SELECT Id FROM User LIMIT 1];
       RelatedSourceBulkOwnerAuraCtrl.fetchRelatedSources(null, null, u.Id, null);
       

        // With Allocated Project filter
      RelatedSourceBulkOwnerAuraCtrl.fetchRelatedSources(null, null, null, 'Zuari Garden City');
        

        // With From and To Dates
        Date fromDate = Date.today().addDays(-1);
        Date toDate = Date.today().addDays(1);
        RelatedSourceBulkOwnerAuraCtrl.fetchRelatedSources(fromDate, toDate, null, null);
       
    }

    @IsTest
    static void testGetUsers() {
       RelatedSourceBulkOwnerAuraCtrl.getUsers();
        
    }

    @IsTest
    static void testGetAllocatedProjectPicklistValues() {
       RelatedSourceBulkOwnerAuraCtrl.getAllocatedProjectPicklistValues();
       
    }

    @IsTest
    static void testBulkUpdateOwner() {
        // Get Related Source records
        List<Related_Source__c> sources = [SELECT Id, OwnerId FROM Related_Source__c LIMIT 2];
        
        // Get an active user who is NOT the current owner
        User newOwner = [SELECT Id FROM User WHERE IsActive = true AND Id != :sources[0].OwnerId LIMIT 1];
        
        Test.startTest();
        // Use runAs to ensure test user is active
        System.runAs(newOwner) {
            RelatedSourceBulkOwnerAuraCtrl.bulkUpdateOwner(
                new List<Id>{sources[0].Id, sources[1].Id},
                newOwner.Id
            );
        }
        Test.stopTest();
        
        // Verify that owner was updated
        List<Related_Source__c> updated = [SELECT OwnerId FROM Related_Source__c WHERE Id IN :sources];
        for(Related_Source__c r : updated){
            System.assertEquals(newOwner.Id, r.OwnerId, 'Owner should be updated to new active user');
        }
    }
    @IsTest
    static void testBulkUpdateOwnerExceptions() {
        // No recordIds
        try {
            RelatedSourceBulkOwnerAuraCtrl.bulkUpdateOwner(new List<Id>(), UserInfo.getUserId());
             system.debug('error');
        } catch (AuraHandledException e) {
             system.debug('error');
        }

        // No toUserId
        List<Related_Source__c> sources = [SELECT Id FROM Related_Source__c LIMIT 1];
        try {
            RelatedSourceBulkOwnerAuraCtrl.bulkUpdateOwner(new List<Id>{sources[0].Id}, null);
            system.debug('error');
        } catch (AuraHandledException e) {
             system.debug('error');
        }
    }
}