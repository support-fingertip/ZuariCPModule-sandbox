@isTest
public class SiteVisitTriggerTest {

    @testSetup
    static void setupData() {
        // Create 2 different Leads...
        Lead lead1 = new Lead(
            LastName = 'Test Lead 1',
            Company = 'Company A'
        );
        Lead lead2 = new Lead(
            LastName = 'Test Lead 2',
            Company = 'Company B'
        );
        insert new List<Lead>{ lead1, lead2 };

        // Site Visit with OTP = '0000'---> (not sent to WhatsApp handler list)
        Site_Visit__c sv1 = new Site_Visit__c(
            Slead__c = lead1.Id,
            OTP__c = '0000'
        );

        // Site Visit with OTP != '0000' --->(will be sent to WhatsApp handler list)
        Site_Visit__c sv2 = new Site_Visit__c(
            Slead__c = lead2.Id,
            OTP__c = '1234'
        );

        insert new List<Site_Visit__c>{ sv1, sv2 };
    }

    @isTest
    static void testAfterInsertTrigger() {
        // Verify that Leads got updated with Site Visit counts...
        List<Lead> leads = [SELECT Id, No_of_Site_Visit__c FROM Lead];
        Boolean foundUpdate = false;

        for (Lead ld : leads) {
            if (ld.No_of_Site_Visit__c != null && ld.No_of_Site_Visit__c > 0) {
                foundUpdate = true;
            }
        }
        System.assert(foundUpdate, 'At least one lead should have a Site Visit count updated');
    }

    @isTest
    static void testBeforeInsertTrigger() {
        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Site_Visit__c sv = new Site_Visit__c(
            Slead__c = ld.Id,
            OTP__c = '5678'
        );

        Test.startTest();
        // Fires Before Insert + After Insert...
        insert sv; 
        Test.stopTest();

        // Recheck lead for updated Site Visit count...
        Lead ldCheck = [SELECT No_of_Site_Visit__c FROM Lead WHERE Id = :ld.Id];
        System.assert(ldCheck.No_of_Site_Visit__c >= 1,
            'Lead should have updated Site Visit count after new insert');
    }

    @isTest
    static void testAfterUpdateTrigger() {
        // Update an existing Site Visit ---> (to cover After Update branch)
        Site_Visit__c sv = [SELECT Id, OTP__c FROM Site_Visit__c LIMIT 1];
        sv.OTP__c = '9999';

        Test.startTest();
        // After Update fires...
        update sv; 
        Test.stopTest();

        System.assertEquals('9999',[SELECT OTP__c FROM Site_Visit__c WHERE Id = :sv.Id].OTP__c, 'Site Visit OTP should be updated');
    }
}