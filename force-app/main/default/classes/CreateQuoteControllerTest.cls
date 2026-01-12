@isTest
public class CreateQuoteControllerTest {
    @isTest
    public static void CreateQuotetest(){
        
        // Create a User object that uses that Profile
        
        
        Project__c pjt = new Project__c();
        pjt.Name = 'Mantri Serenity';
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
        qc.Block_Lookup__c=bc.Id;
        qc.Payment_Type__c = 'Standard';
        insert qc;
       
        
        
         plot__c ut = new Plot__c();
        ut.Name='Test plot';
        ut.Status__c='Available';
        ut.Project__c = pjt.Id;
        
        insert ut;
       Master_payment_schedule__c mps = new Master_payment_schedule__c();
        mps.Project__c = pjt.id;
        mps.Name = 'test';
        mps.Payment_Percent__c = 20;
        mps.Status__c ='Completed';
        insert mps;
        
        Payment_schedule__c ps = new Payment_schedule__c();
         ps.Payment_percent__c =100;
        ps.Master_Payment_Schedule__c = mps.Id;
        ps.Is_Demanded__c = true;
        ps.Quote__c = qc.id;
         insert ps;
        List<Payment_schedule__c> PaymentList = new List<Payment_schedule__c>();
        
        PaymentList.add(ps);
        
      // CreateQuoteController.getPlots(ld.Id, pjt.Name); 
      //  CreateQuoteController.getvillasPlots( pjt.Name);
        CreateQuoteController.saveOppPlot(qc);
     // CreateQuoteController.callQuoteApproval(qc.id);
        
        CreateQuoteController.getPaymentTypePicklistValues();
        CreateQuoteController.getBlock(ld.id);
        CreateQuoteController.getPlots(bc.Name);
        CreateQuoteController.quotationqquery(ld.Id);
        CreateQuoteController.getPaymentSchedules('Standard','Mantri Serenity');
        CreateQuoteController.getPaymentSchedules('Custom','Mantri Serenity');
        CreateQuoteController.deleteSchedule(ps.id);
        String qid =qc.id;
       CreateQuoteController.insertSchedules(PaymentList,1000,qid);
       CreateQuoteController.QuoteCreate(ld.Id,qc.Id);
        
       // CreateQuoteController.getblocks('Mantri Serenity');
        //CreateQuoteController.getType(ld.Id);
       // CreateQuoteController.getPicklistValues('Lead','Allocated_Project__c');
        ///getQuoteData testclass
        PageReference pageRef = Page.MantriquotationVF;
        //Test.setCurrentPage(pageRef);
        
        pageRef.getParameters().put('Id', String.valueOf(qc.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(qc);
        //getQuoteData testp = new getQuoteData(sc);
        
      CreateQuoteController.deleteQuote(qc.id);

    }
}