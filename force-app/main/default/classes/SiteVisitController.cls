public without sharing class SiteVisitController {
    
    public static void checkSiteVisitForRoundRobin(List<Site_Visit__c> svList) {
        
        Set<Id> leadIds = new Set<Id>();
        Set<Id> relatedSourceIds = new Set<Id>();
        
        // Collect all IDs - Related_Source gets priority if both exist
        for (Site_Visit__c sv : svList) {
            if (sv.Related_Source__c != null) {
                relatedSourceIds.add(sv.Related_Source__c);
            } else if (sv.SLead__c != null) {
                leadIds.add(sv.SLead__c);
            }
        }
        
        system.debug('Lead Ids: ' + leadIds);
        system.debug('Related Source Ids: ' + relatedSourceIds);
        
        // Fetch Related_Source__c records with all needed fields
        Map<Id, Related_Source__c> relatedSourceMap = new Map<Id, Related_Source__c>();
        if (!relatedSourceIds.isEmpty()) {
            relatedSourceMap = new Map<Id, Related_Source__c>(
                [SELECT Id, Name, RecordType.Name, Allocated_Project__c, Source_Type__c 
                 FROM Related_Source__c 
                 WHERE Id IN :relatedSourceIds]
            );
        }
        
        // Fetch Leads with all needed fields
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        if (!leadIds.isEmpty()) {
            leadMap = new Map<Id, Lead>(
                [SELECT Id, Name, RecordType.Name, Allocated_Project__c, Source_Type__c 
                 FROM Lead 
                 WHERE Id IN :leadIds]
            );
        }
        
        system.debug('Lead Map: ' + leadMap);
        system.debug('Related Source Map: ' + relatedSourceMap);
        
        // Process Site Visits with priority: Related_Source > Lead
        for (Site_Visit__c sv : svList) {
            system.debug('SV In Loop');
            
            sv.Go_For_Round_Robin__c = true;
            
            // Generate OTP if not '0000'
            if (sv.OTP__c != '0000') {
                sv.OTP__c = GenerateOTP.generateUniqueOTP();
            }
            
            // Set Source_Type__c with priority logic
            if (sv.Source_Type__c == null) {
                // Priority 1: Related_Source__c
                if (sv.Related_Source__c != null && relatedSourceMap.containsKey(sv.Related_Source__c)) {
                    sv.Source_Type__c = relatedSourceMap.get(sv.Related_Source__c).Source_Type__c;
                } 
                // Priority 2: SLead__c (fallback)
                else if (sv.SLead__c != null && leadMap.containsKey(sv.SLead__c)) {
                    sv.Source_Type__c = leadMap.get(sv.SLead__c).Source_Type__c;
                }
            }
        }
    }
}