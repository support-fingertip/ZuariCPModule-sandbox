@isTest
public class RelatedSourceHandlerTest {
    @isTest
    public static  void testmech(){
        
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Pre Sales' LIMIT 1];

        User u = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm1ail.com',
            Username = 'RH@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma1n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = true,
            IsActive = true,
            is_working__c = true
        );
        insert u;

        User u1 = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm2ail.com',
            Username = 'RH2@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma2n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = false,
            IsActive = true,
            is_working__c = true
        );
        insert u1;

        // ✅ Separate context for non-setup objects
        System.runAs(u1) {
            Round_Robin__c r = new Round_Robin__c(
                Active__c = true,
                Project_Assigned__c = 'Zuari Garden City',
                Lead_Source_Type__c = 'Digital Marketing'
            );
            insert r;

            Round_Robin_member__c rrm = new Round_Robin_member__c(
                Round_Robin__c = r.Id,
                Active__c = true,
                User__c = u1.Id,
                User_Type__c = 'Pre Sales'
            );
            insert rrm;

            Round_Robin_member__c rrm1 = new Round_Robin_member__c(
                Round_Robin__c = r.Id,
                Active__c = true,
                User__c = u.Id,
                User_Type__c = 'Sales'
            );
            insert rrm1;
            
        list<Lead> ldlist = new  list<Lead>();
        list<Lead> ldlist21 = new  list<Lead>();
        list<Lead> Newlist = new  list<Lead>();
        Lead ld22 = new Lead();
        ld22.LastName ='test ld';
        ld22.Phone__c ='9908072233';
        ld22.Email='Test@gmai1l.com';
        ld22.allocated_project__c ='Zuari Garden City';
        ld22.Secondary_Phone__c='9922332246';
        ld22.Lead_status__c='Unqualified';
        ld22.Unqualified_Reason__c='Not Within Budget Range';
        ld22.Company='test';
        //ld22.Closed_Lost_Reason__c ='Junk Enquiry';
        insert ld22;
        ldlist.add(ld22);
        
        
        Lead ld221 = new Lead();
        ld221.LastName ='test ld';
        ld221.Phone__c ='9908072211';
        //ld221.Secondary_Phone__c='+919922332244';
        ld221.Email ='Test@gmai1l.com';
        ld221.Company='test';
        ld221.allocated_project__c ='Zuari Garden City';
        //ld22.Lead_status__c='Closed Lost';
        //insert ld221;
        ldlist21.add(ld221);
        
        Lead ld23 = new Lead();
        ld23.LastName ='test ld';
        ld23.Phone__c ='9908072233';
        ld23.Email ='Test3845784@gmai2l.com';
        ld23.Company='test';
        ld23.allocated_project__c ='Zuari Garden City';
        insert ld23;
        ldlist21.add(ld23);
        
        
        
        
        list<Lead> ldlist1 = new  list<Lead>();
        
        Lead c2= new Lead();
        c2.LastName ='test ld';
        c2.Phone__c ='9908072211';
        c2.Email ='Test@gmai2l.com';
        c2.allocated_project__c ='Zuari Garden City';
        c2.Company='Test';
        ldlist1.add(c2);
        
        
        
        list<lead> ldlist2 = new  list<lead>();
        
        Lead c22= new Lead();
        c22.LastName ='test ld';
        c22.Phone__c ='9908072209';
        c22.Email ='Test@gmai2l.com';
        c22.Company='Test';
        c22.allocated_project__c ='Zuari Garden City';
        
        insert c22;
        ldlist1.add(c22);
          List<RecordType> rts = [
            SELECT Id, DeveloperName, Name
            FROM RecordType
            WHERE SObjectType = 'Lead'
        ];
        
        Id rtPre;
        Id rtSales;
        
        for (RecordType rt : rts) {
            if (rt.Name == 'Pre Sales') rtPre = rt.Id;
            if (rt.Name == 'Sales') rtSales = rt.Id;
        }
        Lead lad= new Lead();
        lad.LastName='test';
        lad.Allocated_Project__c = 'Zuari Garden City';
        lad.Phone = '9182748516';
        lad.Lead_Status__c ='New';
         lad.RecordTypeId = rtPre;
        lad.Company='test';
        insert lad;
        Newlist.add(lad);
        Lead led= new Lead();
        led.LastName='test1';
        led.Allocated_Project__c = 'Zuari Garden City';
        led.Phone = '9182748511';
        led.Lead_Status__c ='New';
        led.Company='test';
         led.RecordTypeId = rtPre;
        insert led;
        Newlist.add(led);   
        
        
        related_source__c rs = new related_source__c();
        //rs.
       RelatedSourceHandler.checkMobileNumber2(ldlist);
        
        //RelatedSourceHandler.cpmethod(ldlist);
        RelatedSourceHandler.checkMobileNumber2(ldlist);
        // //RelatedSourceHandler.addCountryCode(ldlist);
        //// RelatedSourceHandler.duplicateCheck(ldlist);
        ////  RelatedSourceHandler.duplicateCheck(Newlist);
        //// RelatedSourceHandler.duplicateCheckOnUpdate(ldlist);
        RelatedSourceHandler.duplicateCheck2(ldlist);
        RelatedSourceHandler.duplicateCheck2(ldlist1 );
            try{
        RelatedSourceHandler.afterinsertLogic(Newlist);
            }catch(Exception e){
                system.debug('error');
                }
       // RelatedSourceHandler.afterinsertLogic2(Newlist);
        ////RelatedSourceHandler.afterinsertLogic2(ldlist2 );
        
        //RelatedSourceHandler.addRelatedSource(ld22);
        //RelatedSourceHandler.addRelatedSource(ld23);
       // RelatedSourceHandler.addRelatedSource2(ld22,ld23);
       // RelatedSourceHandler.reassignUnqualifiedLead(ldlist);
        
        
        
        }
        
        
    }
@isTest(SeeAllData=true)
static void test_reassignUnqualifiedLead1_CMDT() {

    Lead_Assignment_Config__mdt cfg = [
        SELECT User_Indentifier__c
        FROM Lead_Assignment_Config__mdt
        LIMIT 1
    ];

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    String safeAlias = cfg.User_Indentifier__c.length() > 8
        ? cfg.User_Indentifier__c.substring(0, 8)
        : cfg.User_Indentifier__c;

    // CMDT MATCH USER
    User u1 = new User(
        ProfileId = p.Id,
        LastName = 'CMDTUser',
        Email = 'cmdt@test.com',
        Username = 'cmdt+' + System.currentTimeMillis() + '@test.com', // UNIQUE
        Alias = safeAlias, // MATCHES CMDT
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
    );
    insert u1;

    // CURRENT OWNER
    User u2 = new User(
        ProfileId = p.Id,
        LastName = 'Owner',
        Email = 'own@test.com',
        Username = 'owner+' + System.currentTimeMillis() + '@test.com',
        Alias = 'owner1',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
    );
    insert u2;

    Related_Source__c rs = new Related_Source__c(
        OwnerId = u2.Id,
        No_Of_Times_Unqualified__c = 1,
        Lead_status1__c = 'New'
    );
    insert rs;

    Test.startTest();
    RelatedSourceHandler.reassignUnqualifiedLead1(
        new List<Related_Source__c>{ rs }
    );
    Test.stopTest();

}
}