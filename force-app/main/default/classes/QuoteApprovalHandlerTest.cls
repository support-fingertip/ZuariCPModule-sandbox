@isTest
public class QuoteApprovalHandlerTest {
@isTest
    public static void testquote(){
        
          Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden City';
        pjt.Active__c = true;
        insert pjt;
        
        Block__c bc = new Block__c();
        bc.Name='A';
        bc.Project__c=pjt.id;
        insert bc;
        
        Lead ld = new Lead();
        ld.LastName = 'Test';
        ld.Company = 'testcompany';
        ld.Phone__c = '8778987789';
        ld.Allocated_Project__c = 'Zuari Garden City';
        insert ld;
        
        Quote__c qc = new Quote__c();
        qc.Quote_status__c = 'Converted';
        qc.Block__c = ' ';
        //qc.Block_Lookup__c=bc.Id;
        qc.Payment_Type__c = 'Standard';
        qc.Project__c='Zuari Garden City';
        qc.OwnerId=UserInfo.getUserId();
        qc.Discount_in_Percentage__c=6;
        insert qc;
       
        
        
         plot__c ut = new Plot__c();
        ut.Name='Test plot';
        ut.Status__c='Available';
        ut.Project__c = pjt.Id;
        
        insert ut;
        
      List<Quote__c> qtl = new List<Quote__c>();
        qtl.add(qc);
        
        QuoteApprovalHandler.processQuotes(qtl);
    }
}