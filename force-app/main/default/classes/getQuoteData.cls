public class getQuoteData {
    public Quote__c qout{get;set;}
    public id recid{get;set;}
    
	    public decimal totalPercent {get;set;}
     public decimal totalAmount {get;set;}
     Public getQuoteData(ApexPages.StandardController controller){
           this.recId = ApexPages.currentPage().getParameters().get('id');
      
     //  string recordId = controller.getId();
       Quote__c qt = [select Id from Quote__c where Id=:recId limit 1];  
       AggregateResult agg = [select sum(Payment_percent__c) perc, sum(Amount1__c) amt,Quote__c from Payment_Schedule__c where Quote__c=:recId GROUP BY Quote__c LIMIT 1];
         totalPercent = (Decimal) agg.get('perc');
         totalAmount = (Decimal) agg.get('amt');
         
         qout =[select Id,(select id ,Name,Payment_percent__c,Amount1__c,S_No__c from Payment_Schedules__r order by S_No__c asc) from Quote__c where Id=:recId limit 1];
    }

}