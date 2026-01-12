trigger SiteVisitTrigger on Site_Visit__c (before insert,After Update, after insert) {
    
    if(Trigger.isBefore && Trigger.isInsert){
        SiteVisitController.checkSiteVisitForRoundRobin(Trigger.New);
        RoundRobinHandler.siteVisitRoundRobin(Trigger.New);
    }
    if(Trigger.IsAfter && Trigger.IsInsert){
        List<Site_Visit__c> listsitvist = new List<Site_Visit__c>();
        
        Map<Id, DateTime> leadToLatestVisitDate = new Map<Id, DateTime>();
        
        Set<Id> ldId = new Set<Id>();
        Set<Id> rsId = new Set<Id>();
        For(Site_Visit__c sv :Trigger.new){
            if(sv.Slead__c != null){
                ldId.add(sv.Slead__c);
                if (sv.Date__c != null) {
                    if (!leadToLatestVisitDate.containsKey(sv.Slead__c) ||sv.Date__c > leadToLatestVisitDate.get(sv.Slead__c)) {
                        leadToLatestVisitDate.put(sv.Slead__c, sv.Date__c);
                    }
                }
            }
            if(sv.OTP__c!='0000'){
                listsitvist.add(sv);
                
            }
            
        }
        For(Site_Visit__c sv :Trigger.new){
            if(sv.Related_Source__c != NULL){
                rsId.add(sv.Related_Source__c);
            }
        }
        WhatsAppTriggerHandler.processSitevisit(listsitvist);//Call the WhatsAppTriggerHandler
        
        Map<Id, Integer> CountSiteVisit = New Map<Id,Integer>();
        For(AggregateResult Ar : [Select Slead__c, Count(Id) couns From Site_Visit__c where Slead__C IN :ldId Group By Slead__c ]){
            CountSiteVisit.put((Id)Ar.get('Slead__c'), (Integer)Ar.Get('couns'));
        }
        
        // 📅 First & Last visit dates per Lead
        Map<Id, Datetime> firstVisitMap = new Map<Id, Datetime>();
        Map<Id, Datetime> lastVisitMap  = new Map<Id, Datetime>();
        for (AggregateResult ar : [ SELECT Slead__c leadId, MIN(Date__c) minDate, MAX(Date__c) maxDate FROM Site_Visit__c   WHERE Slead__c IN :ldId GROUP BY Slead__c ]) {
            Id leadId = (Id) ar.get('leadId');
            firstVisitMap.put(leadId, (Datetime) ar.get('minDate'));
            lastVisitMap.put(leadId, (Datetime) ar.get('maxDate'));
        }
        List<Lead> ldlst = new List<Lead>();
        
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Id leadId : ldId) {
            
            Lead ld = new Lead();
            ld.Id = leadId;
            
            if (CountSiteVisit.containsKey(leadId)) {
                ld.No_of_Site_Visit__c = CountSiteVisit.get(leadId);
            }
            
            if (leadToLatestVisitDate.containsKey(leadId)) {
                ld.Site_Visit_Schedule_Date__c = leadToLatestVisitDate.get(leadId);
            }
            if (firstVisitMap.containsKey(leadId)) {
                ld.First_Site_Visit_Date_Time__c = firstVisitMap.get(leadId);
            }
            if (lastVisitMap.containsKey(leadId)) {
                ld.Last_Site_Visit_Date_Time__c = lastVisitMap.get(leadId);
            }
            
            leadsToUpdate.add(ld);
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
        
        // Update the first & Last visit dates per related Source
        Map<Id, Datetime> rsfirstVisitMap = new Map<Id, Datetime>();
        Map<Id, Datetime> rslastVisitMap  = new Map<Id, Datetime>();
        
        for (AggregateResult ar : [ SELECT Related_Source__c leadId, MIN(Date__c) minDate, MAX(Date__c) maxDate FROM Site_Visit__c   WHERE Related_Source__c IN :rsId GROUP BY Related_Source__c ]) {
            Id leadId = (Id) ar.get('leadId');
            rsfirstVisitMap.put(leadId, (Datetime) ar.get('minDate'));
            rslastVisitMap.put(leadId, (Datetime) ar.get('maxDate'));
        }
        List<Related_Source__c> rslst = new List<Related_Source__c>();
        For(Id rsI : rsId){
            Related_Source__c rs = new Related_Source__c();
            rs.Id = rsI;
            
            if (rsfirstVisitMap.containsKey(rsI)) {
                rs.First_Site_Visit_Date_Time__c = rsfirstVisitMap.get(rsI);
            }
            if (rslastVisitMap.containsKey(rsI)) {
                rs.Last_Site_Visit_Date_Time__c = rslastVisitMap.get(rsI);
            }
            rslst.add(rs);
            
        }
        if(!rslst.IsEmpty()){
            Update rslst;
        }
        
    }
    
    
    if(Trigger.IsUpdate && Trigger.IsAfter){
    }
}