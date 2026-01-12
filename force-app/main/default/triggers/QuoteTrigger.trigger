trigger QuoteTrigger on Quote__c (after update) {
    
    if (Trigger.isAfter &&  Trigger.isUpdate) {
         List<Quote__c> quotesToProcess = new List<Quote__c>();
        
        for (Quote__c newQuote : Trigger.new) {
            if (newQuote.Discount_Price__c != Trigger.oldMap.get(newQuote.Id).Discount_Price__c && newQuote.Discount_Price__c > 100) {
                quotesToProcess.add(newQuote);
            }
        }
        if (!quotesToProcess.isEmpty()) {
            system.debug('Called Approval Process');
        QuoteApprovalHandler.processQuotes(quotesToProcess);
        }
    }

}