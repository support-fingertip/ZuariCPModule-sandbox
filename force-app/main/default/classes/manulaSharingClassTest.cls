@isTest
public class manulaSharingClassTest {
    @isTest
    public static void sendOTO(){
        List<Lead> leadList = new List<Lead>();
        Lead ld11 = new Lead();
        ld11.LastName='Test lead';
        ld11.Lead_Assigned__c=true;
        ld11.Allocated_Project__c='Zuari Garden City';
        ld11.Reassigned_By__c=UserInfo.getUserId();
        ld11.Re_assigned_date__c = system.now();
        ld11.Lead_Status__c='New';
        ld11.Email='patil@gmail.com';
        ld11.Source_Type__c='Digital Marketing';
        ld11.Lead_source__c ='Website';
        ld11.Phone__c='9898767998';
        ld11.Company='test';
        leadList.add(ld11);
        insert leadList;
        
        
        Lead ld = new Lead();
        ld.LastName = 'Test Lead';
        ld.Allocated_Project__c='Zuari Garden City';
        ld.Country__c='India';
        ld.Phone__c='6362536253';
        ld.Company='Test';
        ld.Email='test@gmail.com';
        ld.OwnerId = UserInfo.getUserId();
        insert ld;
        
        Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Active__c = true;
        pjt.Finance_User__c = UserInfo.getUserId();
        insert pjt;
        
        
        
        Project__c p = new Project__c();
        p.Name='Zuari Garden City';
        p.Active__c=true;
        p.Project__c='Zuari Garden City';
        insert p;
        
        plot__c ut = new Plot__c();
        ut.Name='Test Unit';
        ut.Project__c=p.id;
        insert ut;
        
        Quote__c Qt = new Quote__c();
        Qt.Quote_status__c = 'Approved';
        Qt.SLead__c = ld.id;
        Qt.Project__c = 'Zuari Garden City';
        Qt.Unit__c = ut.id;
        Qt.Payment_Type__c = 'Standard';
        insert Qt;
        
       /* Payment_schedule__c ps=new Payment_schedule__c();
        ps.Name='installment';
        ps.Payment_percent__c=9.5;
        ps.Amount__c=50000.00;
        ps.S_No__c=20.00;
        ps.status__c='Scheduled';
        ps.Quote__c=Qt.Id;
        insert ps;
      */  
       // Booking__c b = new Booking__c();
       // b.SLead__c=ld.Id;
       // b.Quote__c = Qt.Id;
       // b.Project1__c=p.Id;
       // b.Project__c='Neopolis14';
       // b.Applicant_Name__c='TEst';
        //b.Email_id__c='test@gmail.com';
        //b.Email__c='test1@gmail.com';
       // b.Date_of_Booking__c= system.today();
       // b.First_Applicant_Name__c='chethan';
       // b.Sales_Manager__c = userInfo.getUserId();
       // b.Sales_User__c = userInfo.getUserId();
       // insert b;
        
        List<Booking__c> bookList = new List<Booking__c>();
        //bookList.add(b);
        Map<Id,Id> leadMap = new Map<Id,Id>();
        leadMap.put(ld11.id,ld11.Reassigned_By__c); 
        
        manulaSharingClass.manualShareSiteVisit(leadMap);
        manulaSharingClass.manualShareLeadVisit(leadMap);
        manulaSharingClass.shareAnyRecord(leadList,'Edit');
        manulaSharingClass.shareAnyRecordPreSales(leadList,'Read');
        manulaSharingClass.checkShared(leadList);
        
    }
    
}