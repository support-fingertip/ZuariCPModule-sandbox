@isTest
public class SiteVisitControllerTest {
@isTest
    public static void testmethodst(){
        Lead ld = new Lead(
            LastName = 'Test Lead 1',
            Company = 'Company A'
        );
        insert ld;
        List<Site_Visit__c> sv = New List<Site_Visit__c>();
        
          Site_Visit__c sv1 = new Site_Visit__c(
            Slead__c = ld.Id,
            OTP__c = '0000'
        );
        insert sv1;
        sv.add(sv1);
        SiteVisitController.checkSiteVisitForRoundRobin(sv);

    }
}