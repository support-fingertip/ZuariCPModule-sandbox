trigger BookingTrigger on Booking__c (before insert,before update,after insert, after update, after delete, after undelete) {
    
    if(Trigger.IsAfter && Trigger.isInsert){
        Map<Id, DateTime> leadToLatestVisitDate = new Map<Id, DateTime>();
        
        Set<Id> ldId = new Set<Id>();
        For(Booking__c bk : Trigger.New){
            if(bk.SLead__c != null && bk.Booking_Date__c != null){
                if ( !leadToLatestVisitDate.containsKey(bk.Slead__c) ||  bk.Booking_Date__c > leadToLatestVisitDate.get(bk.Slead__c) ) {
                    leadToLatestVisitDate.put(bk.Slead__c, bk.Booking_Date__c);
                    ldId.add(bk.Slead__c);
                }
            }
            
        }
        
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Id leadId : ldId) {
            
            Lead ld = new Lead();
            ld.Id = leadId;
            
            if (leadToLatestVisitDate.containsKey(leadId)) {
                ld.Booking_Date__c = leadToLatestVisitDate.get(leadId);
            }
            
            leadsToUpdate.add(ld);
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        } 
	  BookingTriggerHandler.afterInsert(Trigger.new);
        
    }
    if(Trigger.IsAfter && Trigger.isUpdate){
        BookingTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
}
    
}