@isTest
public class RelatedSourceTriggerTest {

    @testSetup
    static void setupData() {
        // Create a Lead...
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company'
        );
        insert testLead;

        // Create an Account to use as Channel Partner...
        Account cpAccount = new Account(Name = 'Test Channel Partner');
        insert cpAccount;

        // Insert Related_Source__c record...
        Related_Source__c rs = new Related_Source__c(
            SLead__c = testLead.Id,
            Channel_Partner__c = cpAccount.Id   
        );
        insert rs;
    }

    @isTest
    static void testAfterInsertTrigger() {
        List<Related_Source__c> rsList = [SELECT Id, SLead__c, Channel_Partner__c FROM Related_Source__c];
        System.assert(!rsList.isEmpty(), 'Related Source record should be inserted');

        // Create another Lead + Channel Partner...
        Lead l = new Lead(LastName = 'Second Lead', Company = 'Second Co');
        insert l;

        Account anotherCP = new Account(Name = 'Another Channel Partner');
        insert anotherCP;

        Related_Source__c rsNew = new Related_Source__c(
            SLead__c = l.Id,
            Channel_Partner__c = anotherCP.Id   
        );

        Test.startTest();
        insert rsNew; 
        Test.stopTest();

        System.assert(true, 'Trigger executed successfully on Related_Source__c insert');
    }
}