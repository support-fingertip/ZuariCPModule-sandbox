trigger ChannelPartnertrigger on Channel_Partner__c (before update, after Update) {

    if(trigger.isBefore && trigger.isUpdate){
        for(Channel_Partner__c cp : trigger.New){
            if(cp.Approval_Status__c != Trigger.OldMap.get(cp.Id).Approval_Status__c && cp.Approval_Status__c == 'Approved'){
                cp.Password__c = SimplePasswordGenerator.generatePassword();
            }
        }
    }
    /*
     if (Trigger.isAfter && Trigger.isUpdate) {
         ChannelPartnerPDFHandler.process( Trigger.new, Trigger.oldMap);
    }
    */
}