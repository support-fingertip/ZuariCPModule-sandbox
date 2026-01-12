@isTest
public class QuoteTriggerTest {
	
    public static  testMethod void testm(){
          Quote__c qc = new Quote__c();
        qc.Payment_Type__c = 'Standard';
        qc.Discount_Price__c =100;
        insert qc;
       
        qc.Discount_Price__c=106;
            update qc;
      
    }
}