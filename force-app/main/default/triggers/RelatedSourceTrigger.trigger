trigger RelatedSourceTrigger on Related_Source__c (before insert, after insert, before update, after update) {
    private static List<Id> oldDirectInactiveRSIds = new List<Id>();
    // Static variables to pass data between before and after triggers
    private static Map<String, Id> compositeKeyToNewOwnerMap;
    private static Map<String, Set<Id>> leadTypeToOldAdminRecordsMap;
    
    if (Trigger.isBefore && Trigger.isInsert) {
        System.debug('=== TRIGGER START: Before Insert ===');
        System.debug('Total records in trigger: ' + Trigger.new.size());
        
        RelatedSourceHandler.cpRelatedSourcemethod(trigger.new);
        RelatedSourceHandler.SourceHandlingMethod(trigger.new);
        
        List<User> usersList = [SELECT Id, Profile.Name FROM User WHERE IsActive = true];
        Map<Id,User> userIdToProfile = new Map<Id,User>();
        for(User us : usersList){
            userIdToProfile.put(us.Id,us);
        }
        
        System.debug('Current User ID: ' + UserInfo.getUserId());
        System.debug('Current User Profile: ' + userIdToProfile.get(UserInfo.getUserId()).Profile.Name);
        
        if (userIdToProfile.get(UserInfo.getUserId()).Profile.Name == 'System Administrator' || 
            userIdToProfile.get(UserInfo.getUserId()).Profile.Name == 'WebsiteLead Profile' || 
            userIdToProfile.get(UserInfo.getUserId()).Profile.Name == 'API MCube Profile') {
            
            System.debug('=== PROFILE MATCH: Entering main logic ===');
            
            Set<String> sourceValues = new Set<String>();
            Set<Id> leadIds = new Set<Id>();
            for (Related_Source__c r : Trigger.new) {
                System.debug('Processing record - Source_Type__c: ' + r.Source_Type__c + ', SLead__c: ' + r.SLead__c);
                if (r.Source_Type__c != null) {
                    sourceValues.add(r.Source_Type__c);
                }
                if (r.SLead__c != null) {
                    leadIds.add(r.SLead__c);
                }
            }
            System.debug('Collected Source Values: ' + sourceValues);
            System.debug('Collected Lead IDs: ' + leadIds);
            
            Map<String, String> sourceToTypeMap = new Map<String, String>();
                for (Source_Bifurcation__c sb : [SELECT Id, source__c, Type__c FROM Source_Bifurcation__c WHERE source__c != null AND Type__c != null]) {
                if (sb.source__c != null) {
                    List<String> sources = sb.source__c.split(';');
                    for (String src : sources) {
                        String trimmedSource = src.trim();
                        if (!sourceToTypeMap.containsKey(trimmedSource)) {
                            sourceToTypeMap.put(trimmedSource, sb.Type__c);
                        }
                    }
                }
            }
            System.debug('=== SOURCE TO TYPE MAPPING ===');
            System.debug('Source to Type Map: ' + sourceToTypeMap);
            
            Map<Id, String> newRecordToTypeMap = new Map<Id, String>();
            Set<String> typesNeeded = new Set<String>();
            for (Related_Source__c r : Trigger.new) {
                if (r.Source_Type__c != null && sourceToTypeMap.containsKey(r.Source_Type__c)) {
                    String sourceType = sourceToTypeMap.get(r.Source_Type__c);
                    newRecordToTypeMap.put(r.Id, sourceType);
                    typesNeeded.add(sourceType);
                    System.debug('Record ID: ' + r.Id + ' mapped to Type: ' + sourceType);
                }
            }
            System.debug('=== NEW RECORD TYPE MAPPING ===');
            System.debug('New Record to Type Map: ' + newRecordToTypeMap);
            System.debug('Types Needed: ' + typesNeeded);
            
            // Enhanced query to get ALL existing records with their status and owner
            Map<String, List<Related_Source__c>> leadTypeToAllRecordsMap = new Map<String, List<Related_Source__c>>();
            Map<String, List<Related_Source__c>> leadTypeCPToAllRecordsMap = new Map<String, List<Related_Source__c>>();
            
            if (!leadIds.isEmpty() && !typesNeeded.isEmpty()) {
                System.debug('=== QUERYING EXISTING RELATED SOURCES ===');
                System.debug('Query conditions - Lead IDs: ' + leadIds);
                
                List<Related_Source__c> existingRSList = [
                    SELECT Id, SLead__c, Source_Type__c, Channel_Partner1__c, OwnerId, 
                           CreatedDate, Lead_status1__c, Is_Locked__c
                    FROM Related_Source__c 
                    WHERE SLead__c IN :leadIds
                    AND Source_Type__c != null
                    ORDER BY CreatedDate ASC
                ];
                
                System.debug('Found ' + existingRSList.size() + ' existing Related Source records');
                
                for (Related_Source__c existingRS : existingRSList) {
                    System.debug('--- Existing Record ---');
                    System.debug('Record ID: ' + existingRS.Id);
                    System.debug('Lead ID: ' + existingRS.SLead__c);
                    System.debug('Source Type: ' + existingRS.Source_Type__c);
                    System.debug('Owner ID: ' + existingRS.OwnerId);
                    System.debug('Owner Profile: ' + (userIdToProfile.containsKey(existingRS.OwnerId) ? userIdToProfile.get(existingRS.OwnerId).Profile.Name : 'Unknown'));
                    System.debug('Lead Status: ' + existingRS.Lead_status1__c);
                    System.debug('Channel Partner: ' + existingRS.Channel_Partner1__c);
                    System.debug('Is Locked: ' + existingRS.Is_Locked__c);
                    
                    if (sourceToTypeMap.containsKey(existingRS.Source_Type__c)) {
                        String existingType = sourceToTypeMap.get(existingRS.Source_Type__c);
                        
                        // For Channel Partner type with specific partner
                        if (existingType == 'Channel Partner' && existingRS.Channel_Partner1__c != null) {
                            String cpCompositeKey = existingRS.SLead__c + '_' + existingType + '_' + existingRS.Channel_Partner1__c;
                            if (!leadTypeCPToAllRecordsMap.containsKey(cpCompositeKey)) {
                                leadTypeCPToAllRecordsMap.put(cpCompositeKey, new List<Related_Source__c>());
                            }
                            leadTypeCPToAllRecordsMap.get(cpCompositeKey).add(existingRS);
                            System.debug('Added to leadTypeCPToAllRecordsMap - Key: ' + cpCompositeKey);
                        }
                        
                        // For all types (including CP without partner or other types)
                        String compositeKey = existingRS.SLead__c + '_' + existingType;
                        if (!leadTypeToAllRecordsMap.containsKey(compositeKey)) {
                            leadTypeToAllRecordsMap.put(compositeKey, new List<Related_Source__c>());
                        }
                        leadTypeToAllRecordsMap.get(compositeKey).add(existingRS);
                        System.debug('Added to leadTypeToAllRecordsMap - Key: ' + compositeKey);
                    }
                }
            }
            
            System.debug('=== FINAL MAPS FROM EXISTING RECORDS ===');
            System.debug('leadTypeToAllRecordsMap keys: ' + leadTypeToAllRecordsMap.keySet());
            System.debug('leadTypeCPToAllRecordsMap keys: ' + leadTypeCPToAllRecordsMap.keySet());
            
            Map<String, Related_Source__c> batchLeadTypeMap = new Map<String, Related_Source__c>();
            Map<String, Related_Source__c> batchLeadTypeCPMap = new Map<String, Related_Source__c>();
            
            List<Related_Source__c> newSourceRSList = new List<Related_Source__c>();
            List<Related_Source__c> existingSourceRSList = new List<Related_Source__c>();
            leadTypeToOldAdminRecordsMap = new Map<String, Set<Id>>();
            
            System.debug('=== PROCESSING NEW RECORDS ===');
            
            for (Related_Source__c r : Trigger.new) {
                System.debug('--- Processing New Record ---');
                System.debug('Record Temp ID: ' + r.Id);
                System.debug('Lead ID: ' + r.SLead__c);
                System.debug('Source Type: ' + r.Source_Type__c);
                
                if (r.SLead__c != null && newRecordToTypeMap.containsKey(r.Id)) {
                    String recordType = newRecordToTypeMap.get(r.Id);
                    System.debug('Record Type from Map: ' + recordType);
                    
                    Boolean isDuplicate = false;
                    Id existingOwnerId = null;
                    Boolean hasActiveRecord = false;
                    Boolean hasActiveNonAdminRecord = false;
                    Boolean hasSystemAdminRecord = false;
                    Set<Id> systemAdminRecordIds = new Set<Id>();
                    
                    // Check for Channel Partner type with specific partner
                    if (recordType == 'Channel Partner' && r.Channel_Partner1__c != null) {
                        String cpCompositeKey = r.SLead__c + '_' + recordType + '_' + r.Channel_Partner1__c;
                        System.debug('CP Composite Key: ' + cpCompositeKey);
                        
                        // Check existing records for this specific partner
                        if (leadTypeCPToAllRecordsMap.containsKey(cpCompositeKey)) {
                            List<Related_Source__c> existingRecords = leadTypeCPToAllRecordsMap.get(cpCompositeKey);
                            
                            for (Related_Source__c existingRec : existingRecords) {
                                Boolean isSystemAdmin = userIdToProfile.containsKey(existingRec.OwnerId) && 
                                                       userIdToProfile.get(existingRec.OwnerId).Profile.Name == 'System Administrator';
                                
                                Boolean isActiveStatus = existingRec.Lead_status1__c != 'Rejected' && 
                                                        existingRec.Lead_status1__c != 'Unqualified' && 
                                                        existingRec.Lead_status1__c != 'Closed Lost' &&  existingRec.Is_Locked__c == false;
                                
                                // Track System Admin records
                                if (isSystemAdmin) {
                                    hasSystemAdminRecord = true;
                                    systemAdminRecordIds.add(existingRec.Id);
                                    System.debug('Found System Admin record: ' + existingRec.Id);
                                    
                                    // If System Admin record is ACTIVE, it should be replaced
                                    if (isActiveStatus) {
                                        System.debug('System Admin record is ACTIVE - Will be replaced');
                                    }
                                     if (!isActiveStatus) {
                                        System.debug('System Admin record is ACTIVE - Will be replaced');
                                    }
                                }
                                
                                // Track active non-admin records
                                if (isActiveStatus && !isSystemAdmin) {
                                    hasActiveNonAdminRecord = true;
                                    existingOwnerId = existingRec.OwnerId;
                                    System.debug('Found ACTIVE non-admin record: ' + existingRec.Id + ', Owner: ' + existingOwnerId);
                                }
                                
                                // Track any active record
                                if (isActiveStatus) {
                                    hasActiveRecord = true;
                                }
                            }
                        }
                        
                        // Check same batch
                        if (batchLeadTypeCPMap.containsKey(cpCompositeKey)) {
                            isDuplicate = true;
                            Related_Source__c firstRecord = batchLeadTypeCPMap.get(cpCompositeKey);
                            // Only copy owner if it's not System Admin
                            if (userIdToProfile.containsKey(firstRecord.OwnerId) && 
                                userIdToProfile.get(firstRecord.OwnerId).Profile.Name != 'System Administrator') {
                                existingOwnerId = firstRecord.OwnerId;
                            }
                            System.debug('Found in same batch - Treating as DUPLICATE');
                        } else {
                            batchLeadTypeCPMap.put(cpCompositeKey, r);
                        }
                        
                        // DECISION LOGIC FOR CP WITH SPECIFIC PARTNER
                        if (hasActiveNonAdminRecord) {
                            // Active non-admin record exists -> DUPLICATE, copy owner
                            isDuplicate = true;
                            System.debug('Active non-admin record exists - DUPLICATE, copy owner: ' + existingOwnerId);
                        }
                        else if (hasActiveRecord && hasSystemAdminRecord) {
                            // Only System Admin records exist and they're active -> DUPLICATE but replace System Admin
                            isDuplicate = true;
                            System.debug('Only active System Admin records exist - DUPLICATE but will replace System Admin');
                            
                            // Store System Admin records for replacement
                            if (!leadTypeToOldAdminRecordsMap.containsKey(cpCompositeKey)) {
                                leadTypeToOldAdminRecordsMap.put(cpCompositeKey, new Set<Id>());
                            }
                            leadTypeToOldAdminRecordsMap.get(cpCompositeKey).addAll(systemAdminRecordIds);
                        }
                        else if (hasSystemAdminRecord && !hasActiveRecord) {
                            // Only inactive System Admin records exist -> NEW, update System Admin records
                            isDuplicate = false;
                            System.debug('Only inactive System Admin records exist - NEW, update System Admin');
                            
                            // Store System Admin records for update
                            if (!leadTypeToOldAdminRecordsMap.containsKey(cpCompositeKey)) {
                                leadTypeToOldAdminRecordsMap.put(cpCompositeKey, new Set<Id>());
                            }
                            leadTypeToOldAdminRecordsMap.get(cpCompositeKey).addAll(systemAdminRecordIds);
                        }
                        else if (!hasActiveRecord && !hasSystemAdminRecord) {
                            // No records exist -> NEW
                            isDuplicate = false;
                            System.debug('No records exist - NEW');
                        }
                        
                    } else {
                        // Non-CP types or CP without specific partner
                        String compositeKey = r.SLead__c + '_' + recordType;
                        System.debug('Composite Key: ' + compositeKey);
                        
                        // Check existing records
                        if (leadTypeToAllRecordsMap.containsKey(compositeKey)) {
                            List<Related_Source__c> existingRecords = leadTypeToAllRecordsMap.get(compositeKey);
                            
                            for (Related_Source__c existingRec : existingRecords) {
                                // For CP type without specific partner, skip if it has a partner
                                if (recordType == 'Channel Partner' && existingRec.Channel_Partner1__c != null) {
                                    continue;
                                }
                                
                                Boolean isSystemAdmin = userIdToProfile.containsKey(existingRec.OwnerId) && 
                                                       userIdToProfile.get(existingRec.OwnerId).Profile.Name == 'System Administrator';
                                
                                Boolean isActiveStatus = existingRec.Lead_status1__c != 'Rejected' && 
                                                        existingRec.Lead_status1__c != 'Unqualified' && 
                                                        existingRec.Lead_status1__c != 'Closed Lost'&& existingRec.Is_Locked__c == false;
                                Boolean inActiveStatus = (existingRec.Lead_status1__c == 'Rejected' ||
                                                        existingRec.Lead_status1__c == 'Unqualified' ||
                                                        existingRec.Lead_status1__c == 'Closed Lost') && existingRec.Is_Locked__c == false;
                                if (inActiveStatus) {
                                     System.debug('Found System inActiveStatus record: ' + existingRec.Id);
                                }
                                
                                // Track System Admin records
                                if (isSystemAdmin) {
                                    hasSystemAdminRecord = true;
                                    systemAdminRecordIds.add(existingRec.Id);
                                    System.debug('Found System Admin record: ' + existingRec.Id);
                                    
                                    // If System Admin record is ACTIVE, it should be replaced
                                    if (isActiveStatus) {
                                        System.debug('System Admin record is ACTIVE - Will be replaced');
                                    }
                                }
                                
                                // Track active non-admin records
                                if (isActiveStatus && !isSystemAdmin) {
                                    hasActiveNonAdminRecord = true;
                                    existingOwnerId = existingRec.OwnerId;
                                    System.debug('Found ACTIVE non-admin record: ' + existingRec.Id + ', Owner: ' + existingOwnerId);
                                }
                                
                                // Track any active record
                                if (isActiveStatus) {
                                    hasActiveRecord = true;
                                }
                            }
                        }
                        
                        // Check same batch
                        if (batchLeadTypeMap.containsKey(compositeKey)) {
                            isDuplicate = true;
                            Related_Source__c firstRecord = batchLeadTypeMap.get(compositeKey);
                            // Only copy owner if it's not System Admin
                            if (userIdToProfile.containsKey(firstRecord.OwnerId) && 
                                userIdToProfile.get(firstRecord.OwnerId).Profile.Name != 'System Administrator') {
                                existingOwnerId = firstRecord.OwnerId;
                            }
                            System.debug('Found in same batch - Treating as DUPLICATE');
                        } else {
                            batchLeadTypeMap.put(compositeKey, r);
                        }
                        
                        // DECISION LOGIC FOR NON-CP TYPES
                        if (hasActiveNonAdminRecord) {
                            // Active non-admin record exists -> DUPLICATE, copy owner
                            isDuplicate = true;
                            System.debug('Active non-admin record exists - DUPLICATE, copy owner: ' + existingOwnerId);
                        }
                        else if (hasActiveRecord && hasSystemAdminRecord) {
                            // Only System Admin records exist and they're active -> DUPLICATE but replace System Admin
                            //isDuplicate = true;
                            isDuplicate = false;
                            System.debug('Only active System Admin records exist - DUPLICATE but will replace System Admin');
                            
                            // Store System Admin records for replacement
                            if (!leadTypeToOldAdminRecordsMap.containsKey(compositeKey)) {
                                leadTypeToOldAdminRecordsMap.put(compositeKey, new Set<Id>());
                            }
                            leadTypeToOldAdminRecordsMap.get(compositeKey).addAll(systemAdminRecordIds);
                        }
                        else if (hasSystemAdminRecord && !hasActiveRecord) {
                            // Only inactive System Admin records exist -> NEW, update System Admin records
                            isDuplicate = false;
                            System.debug('Only inactive System Admin records exist - NEW, update System Admin');
                            
                            // Store System Admin records for update
                            if (!leadTypeToOldAdminRecordsMap.containsKey(compositeKey)) {
                                leadTypeToOldAdminRecordsMap.put(compositeKey, new Set<Id>());
                            }
                            leadTypeToOldAdminRecordsMap.get(compositeKey).addAll(systemAdminRecordIds);
                        }
                        //newly added by sandeep to if already exits record is inactive we need to lock it and new- will be unlocked
                        else if (!hasActiveRecord && recordType == 'Direct') {
                             System.debug('Direct inactive old record entered: ' );
                            // All existing records are INACTIVE (Direct inactive case)
                            isDuplicate = false;
                            // String compositeKey = r.SLead__c + '_' + recordType;
                            
                            // Lock OLD Direct inactive records
                            List<Related_Source__c> existingRecordsForKey = leadTypeToAllRecordsMap.get(compositeKey);
                            
                            if (existingRecordsForKey != null && !existingRecordsForKey.isEmpty()) {
                                for (Related_Source__c existingRec : existingRecordsForKey) {
                                    Boolean isInactive =(existingRec.Lead_status1__c == 'Rejected' || existingRec.Lead_status1__c == 'Unqualified' || existingRec.Lead_status1__c == 'Closed Lost') &&  existingRec.Is_Locked__c == false;
                                    
                                    if (isInactive) {
                                        oldDirectInactiveRSIds.add(existingRec.Id);
                                        System.debug('Direct inactive old record marked for locking: ' + existingRec.Id);
                                    }
                                }
                            }
                            else{
                                System.debug('No existing records found for compositeKey: ' + compositeKey);
                            }
                        }
                        else if (!hasActiveRecord && !hasSystemAdminRecord) {
                            // No records exist -> NEW
                            isDuplicate = false;
                            System.debug('No records exist - NEW');
                        }
                    }
                    
                    System.debug('Final Decision - isDuplicate: ' + isDuplicate + ', existingOwnerId: ' + existingOwnerId);
                    
                    if (isDuplicate) {
                          system.debug('duplicate entered :::===>');
                        // For duplicates, set owner if we have one (not from System Admin)
                        if (existingOwnerId != null) {
                            r.OwnerId = existingOwnerId;
                            System.debug('Setting OwnerId to existing non-admin: ' + existingOwnerId);
                        }
                        r.Is_Locked__c = true;
                        existingSourceRSList.add(r);
                        System.debug('Added to existingSourceRSList (DUPLICATE)');
                    } else {
                        // For new records, will go through round robin
                        system.debug('no duplicate entered :::===>');
                        r.Is_Locked__c = false;
                        newSourceRSList.add(r);
                        System.debug('Added to newSourceRSList (NEW) - will go to round robin');
                    }
                } else {
                    System.debug('Record has no Lead or not in type map - Treating as NEW');
                    r.Is_Locked__c = false;
                    newSourceRSList.add(r);
                }
            }
            
            System.debug('=== SUMMARY BEFORE ROUND ROBIN ===');
            System.debug('newSourceRSList size: ' + newSourceRSList.size());
            System.debug('existingSourceRSList size: ' + existingSourceRSList.size());
            System.debug('leadTypeToOldAdminRecordsMap: ' + leadTypeToOldAdminRecordsMap);
            
            System.debug('=== ROUND ROBIN FOR NEW RECORDS ===');
            if (!newSourceRSList.isEmpty()) {
                System.debug('Calling RoundRobinHandler with ' + newSourceRSList.size() + ' records');
                RoundRobinHandler.assignRelatedsource(newSourceRSList, false, 'Pre Sales');
                System.debug('Round robin completed');
                
                // Store composite key to new owner mapping for System Admin updates
                compositeKeyToNewOwnerMap = new Map<String, Id>();
                for (Related_Source__c rs : newSourceRSList) {
                    System.debug('After Round Robin - Lead: ' + rs.SLead__c + ', Source Type: ' + rs.Source_Type__c + ', Assigned Owner: ' + rs.OwnerId);
                    
                    if (rs.OwnerId != null && rs.SLead__c != null && rs.Source_Type__c != null) {
                        if (sourceToTypeMap.containsKey(rs.Source_Type__c)) {
                            String recordType = sourceToTypeMap.get(rs.Source_Type__c);
                            
                            // Build appropriate composite key
                            String compositeKey;
                            if (recordType == 'Channel Partner' && rs.Channel_Partner1__c != null) {
                                compositeKey = rs.SLead__c + '_' + recordType + '_' + rs.Channel_Partner1__c;
                            } else {
                                compositeKey = rs.SLead__c + '_' + recordType;
                            }
                            
                            if (!compositeKeyToNewOwnerMap.containsKey(compositeKey)) {
                                compositeKeyToNewOwnerMap.put(compositeKey, rs.OwnerId);
                                System.debug('Stored owner mapping - Key: ' + compositeKey + ', Owner: ' + rs.OwnerId);
                            }
                        }
                    }
                }
                
                System.debug('compositeKeyToNewOwnerMap after round robin: ' + compositeKeyToNewOwnerMap);
            } else {
                System.debug('No records to send to round robin');
            }
            
            // Sync owner for records in same batch
            System.debug('=== SYNCING OWNERS FOR BATCH DUPLICATES ===');
            for (Related_Source__c r : existingSourceRSList) {
                if (r.OwnerId == null && r.SLead__c != null && newRecordToTypeMap.containsKey(r.Id)) {
                    String recordType = newRecordToTypeMap.get(r.Id);
                    System.debug('Syncing owner for record type: ' + recordType + ', Lead: ' + r.SLead__c);
                    
                    if (recordType == 'Channel Partner' && r.Channel_Partner1__c != null) {
                        String cpCompositeKey = r.SLead__c + '_' + recordType + '_' + r.Channel_Partner1__c;
                        if (batchLeadTypeCPMap.containsKey(cpCompositeKey)) {
                            Related_Source__c firstRecord = batchLeadTypeCPMap.get(cpCompositeKey);
                            // Only sync if not System Admin
                            if (userIdToProfile.containsKey(firstRecord.OwnerId) && 
                                userIdToProfile.get(firstRecord.OwnerId).Profile.Name != 'System Administrator') {
                                r.OwnerId = firstRecord.OwnerId;
                                System.debug('Synced CP owner: ' + r.OwnerId);
                            }
                        }
                    } else {
                        String compositeKey = r.SLead__c + '_' + recordType;
                        if (batchLeadTypeMap.containsKey(compositeKey)) {
                            Related_Source__c firstRecord = batchLeadTypeMap.get(compositeKey);
                            // Only sync if not System Admin
                            if (userIdToProfile.containsKey(firstRecord.OwnerId) && 
                                userIdToProfile.get(firstRecord.OwnerId).Profile.Name != 'System Administrator') {
                                r.OwnerId = firstRecord.OwnerId;
                                System.debug('Synced owner: ' + r.OwnerId);
                            }
                        }
                    }
                }
            }
            
            // Update old System Admin records with new owner and lock them
            if (compositeKeyToNewOwnerMap != null && !compositeKeyToNewOwnerMap.isEmpty() &&
                leadTypeToOldAdminRecordsMap != null && !leadTypeToOldAdminRecordsMap.isEmpty()) {
                    
                System.debug('=== UPDATING OLD SYSTEM ADMIN RECORDS ===');
                System.debug('compositeKeyToNewOwnerMap: ' + compositeKeyToNewOwnerMap);
                System.debug('leadTypeToOldAdminRecordsMap: ' + leadTypeToOldAdminRecordsMap);
                
                List<Related_Source__c> oldRecordsToUpdate = new List<Related_Source__c>();
                
                for (String compositeKey : leadTypeToOldAdminRecordsMap.keySet()) {
                    System.debug('Processing composite key: ' + compositeKey);
                    
                    if (compositeKeyToNewOwnerMap.containsKey(compositeKey)) {
                        Id newOwner = compositeKeyToNewOwnerMap.get(compositeKey);
                        Set<Id> oldRecordIds = leadTypeToOldAdminRecordsMap.get(compositeKey);
                        
                        System.debug('New Owner from Round Robin: ' + newOwner);
                        System.debug('Old System Admin Record IDs to update: ' + oldRecordIds);
                        System.debug('Number of old records to update: ' + oldRecordIds.size());
                        
                        for (Id oldRecordId : oldRecordIds) {
                            Related_Source__c oldRec = new Related_Source__c(
                                Id = oldRecordId,
                                OwnerId = newOwner,
                                Is_Locked__c = true
                                //Lead_status1__c = 'Reassigned'  // Mark as reassigned
                            );
                            oldRecordsToUpdate.add(oldRec);
                            System.debug('Prepared update - Record ID: ' + oldRecordId + ', New Owner: ' + newOwner + ', Is_Locked__c: true');
                        }
                    } else {
                        System.debug('WARNING: No new owner found for composite key: ' + compositeKey);
                    }
                }
                
                if (!oldRecordsToUpdate.isEmpty()) {
                    System.debug('Updating ' + oldRecordsToUpdate.size() + ' old System Admin records');
                    try {
                        update oldRecordsToUpdate;
                        System.debug('Successfully updated old System Admin records');
                    } catch (Exception e) {
                        System.debug('ERROR updating old System Admin records: ' + e.getMessage());
                        System.debug('Stack trace: ' + e.getStackTraceString());
                    }
                } else {
                    System.debug('No old System Admin records to update');
                }
                
                // Clear static variables
                compositeKeyToNewOwnerMap = null;
                leadTypeToOldAdminRecordsMap = null;
            } else {
                System.debug('No data in static maps - skipping System Admin record updates');
            }
            
            System.debug('=== TRIGGER LOGIC COMPLETED ===');
            
        } else {
            System.debug('=== PROFILE DOES NOT MATCH - Setting owner to current user ===');
            for (Related_Source__c r : Trigger.new) {
                r.OwnerId = UserInfo.getUserId();
                System.debug('Set owner to current user: ' + UserInfo.getUserId());
            }
        }
    }
    
   
    
    if (Trigger.isAfter && Trigger.isInsert) {
        
        System.debug('================ AFTER INSERT : Related_Source__c =================');
        System.debug('Total records in Trigger.new : ' + Trigger.new.size());
        
        /* ============================================================
		STEP 1: LOCK NEW DUPLICATE RECORDS
		============================================================ */
        List<Id> recordsToLock = new List<Id>();
        
        for (Related_Source__c r : Trigger.new) {
            if (r.Is_Locked__c == true) {
                recordsToLock.add(r.Id);
                System.debug('New record marked for lock (duplicate): ' + r.Id);
            }
        }
        
        if (!recordsToLock.isEmpty()) {
            System.debug('Locking ' + recordsToLock.size() + ' newly inserted duplicate records');
            try {
                Approval.lock(recordsToLock);
                System.debug('SUCCESS: Newly inserted duplicate records locked');
            } catch (Exception e) {
                System.debug('ERROR while locking new records: ' + e.getMessage());
            }
        } else {
            System.debug('No new records require locking');
        }
        
        /* ============================================================
        STEP 2: MANUAL SHARING FOR CHANNEL PARTNER LEADS
        ============================================================ */
        Map<Id, Id> rsMap = new Map<Id, Id>();
        
        for (Related_Source__c r : Trigger.new) {
            if (r.Channel_Partner1__c != null) {
                rsMap.put(r.SLead__c, r.CP_Owner_ID__c);
                System.debug('Prepared manual share → Lead: ' + r.SLead__c +
                             ', CP Owner: ' + r.CP_Owner_ID__c);
            }
        }
        
        if (!rsMap.isEmpty()) {
            System.debug('Calling manual sharing for ' + rsMap.size() + ' leads');
            manulaSharingClass.manualShareLeadVisit(rsMap);
        } else {
            System.debug('No Channel Partner records found for manual sharing');
        }
        
        /* ============================================================
        STEP 3: LOCK OLD DIRECT INACTIVE RECORDS
        ============================================================ */
        System.debug('================ DIRECT INACTIVE LOCK CHECK =================');
        
        Set<Id> directLeadIds = new Set<Id>();
        Boolean hasNewDirectRecord = false;
        
        for (Related_Source__c r : Trigger.new) {
            if (r.SLead__c != null) {
                directLeadIds.add(r.SLead__c);
            }
            if (r.Source_Type__c != 'Channel Partner') {
                hasNewDirectRecord = true;
            }
        }
        
        System.debug('Has new Direct record? ' + hasNewDirectRecord);
        System.debug('Direct Lead IDs collected: ' + directLeadIds);
        
        if (hasNewDirectRecord && !directLeadIds.isEmpty()) {
            
            List<Related_Source__c> oldInactiveDirectRecords = [
                SELECT Id
                FROM Related_Source__c
                WHERE SLead__c IN :directLeadIds
                AND Source_Type__c != 'Channel Partner'
                AND Lead_status1__c IN ('Rejected','Unqualified','Closed Lost')
                AND Is_Locked__c = false
                AND Id NOT IN :Trigger.new
            ];
            
            System.debug('Old inactive Direct records found: ' + oldInactiveDirectRecords.size());
            
            if (!oldInactiveDirectRecords.isEmpty()) {
                for (Related_Source__c rs : oldInactiveDirectRecords) {
                    rs.Is_Locked__c = true;
                    System.debug('Marking old Direct inactive record for lock: ' + rs.Id);
                }
                
                update oldInactiveDirectRecords;
                Approval.lock(oldInactiveDirectRecords);
                
                System.debug('SUCCESS: Old Direct inactive records locked');
            } else {
                System.debug('No old inactive Direct records to lock');
            }
        } else {
            System.debug('Skipping Direct inactive lock (no new Direct record)');
        }
        
        /* ============================================================
        STEP 4: LOCK OLD CHANNEL PARTNER INACTIVE RECORDS
        ============================================================ */
        System.debug('================ CHANNEL PARTNER INACTIVE LOCK CHECK =================');
        
        Set<Id> cpLeadIds = new Set<Id>();
        Set<Id> cpPartnerIds = new Set<Id>();
        Boolean hasNewCPRecord = false;
        
        for (Related_Source__c r : Trigger.new) {
            if (r.Source_Type__c == 'Channel Partner'
                && r.SLead__c != null
                && r.Channel_Partner1__c != null) {
                    
                    hasNewCPRecord = true;
                    cpLeadIds.add(r.SLead__c);
                    cpPartnerIds.add(r.Channel_Partner1__c);
                    
                    System.debug('New CP record detected → Lead: ' + r.SLead__c +
                                 ', Partner: ' + r.Channel_Partner1__c);
                }
        }
        
        System.debug('Has new Channel Partner record? ' + hasNewCPRecord);
        System.debug('CP Lead IDs: ' + cpLeadIds);
        System.debug('CP Partner IDs: ' + cpPartnerIds);
        
        if (hasNewCPRecord) {
            
            List<Related_Source__c> oldInactiveCPRecords = [
                SELECT Id
                FROM Related_Source__c
                WHERE SLead__c IN :cpLeadIds
                AND Channel_Partner1__c IN :cpPartnerIds
                AND Source_Type__c = 'Channel Partner'
                AND Lead_status1__c IN ('Rejected','Unqualified','Closed Lost')
                AND Is_Locked__c = false
                AND Id NOT IN :Trigger.new
            ];
            
            System.debug('Old inactive CP records found: ' + oldInactiveCPRecords.size());
            
            if (!oldInactiveCPRecords.isEmpty()) {
                for (Related_Source__c rs : oldInactiveCPRecords) {
                    rs.Is_Locked__c = true;
                    System.debug('Marking old CP inactive record for lock: ' + rs.Id);
                }
                
                update oldInactiveCPRecords;
                Approval.lock(oldInactiveCPRecords);
                
                System.debug('SUCCESS: Old Channel Partner inactive records locked');
            } else {
                System.debug('No old inactive Channel Partner records to lock');
            }
        } else {
            System.debug('Skipping CP inactive lock (no new CP record)');
        }
        
        /* ============================================================
        EXTRA: LOCK OLD ACTIVE CP RECORDS (CASE-5)
        SPECIAL RULE:
        - If OLD CP (Sales RT) has COMPLETED Site Visit → lock NEW CP
        ============================================================ */
        
        List<Related_Source__c> oldActiveCPRecords = [
            SELECT Id, RecordType.DeveloperName,Channel_Partner1__c
            FROM Related_Source__c
            WHERE SLead__c IN :cpLeadIds
            AND Source_Type__c = 'Channel Partner'
            AND Lead_status1__c NOT IN ('Rejected','Unqualified','Closed Lost')
            AND Is_Locked__c = false
            AND Id NOT IN :Trigger.new
        ];
        
        System.debug('Old ACTIVE CP records found: ' + oldActiveCPRecords.size());
        
        /* ---------------------------------
        STEP A: Check Site Visit COMPLETED for Sales RT
        --------------------------------- */

        Set<Id> salesRsIds = new Set<Id>();
        
        System.debug('--- STEP A DEBUG START ---');
        System.debug('Total oldActiveCPRecords: ' + oldActiveCPRecords.size());
        
        for (Related_Source__c rs : oldActiveCPRecords) {
            
            System.debug(
                'RS CHECK → Id=' + rs.Id +
                ' | RecordTypeId=' + rs.RecordTypeId +
                ' | RecordType DevName=' + rs.RecordType.DeveloperName
            );
            
            if (rs.RecordType.DeveloperName == 'Sales') {
                salesRsIds.add(rs.Id);
                System.debug('✔ Added to Sales RS set: ' + rs.Id);
            } else {
                System.debug('✖ Not a Sales RT, skipped: ' + rs.Id);
            }
        }
        
        System.debug('Final Sales RS Ids: ' + salesRsIds);
        
        Boolean hasCompletedSalesVisit = false;
        
        if (!salesRsIds.isEmpty()) {
            
            System.debug('Querying Site Visits for Sales RS...');
            
            Integer completedCount = [
                SELECT COUNT()
                FROM Site_Visit__c
                WHERE Related_Source__c IN :salesRsIds
                AND Status__c = 'Completed'
            ];
            
            System.debug('Completed Site Visit count: ' + completedCount);
            
            hasCompletedSalesVisit = completedCount > 0;
            
        } else {
            System.debug('No Sales RS records found → skipping Site Visit query');
        }
        
        System.debug('FINAL RESULT → Has completed Sales Site Visit? '
                     + hasCompletedSalesVisit);
        System.debug('--- STEP A DEBUG END ---');        
        /* ---------------------------------
        STEP B: Decide locking target
        --------------------------------- */
        List<Related_Source__c> recordsToLock1 = new List<Related_Source__c>();
        
        if (hasCompletedSalesVisit) {
            
            for (Related_Source__c rs : Trigger.new) {
                if (rs.Source_Type__c == 'Channel Partner') {
                    
                    recordsToLock1.add(new Related_Source__c(
                        Id = rs.Id,
                        Is_Locked__c = true
                    ));
                    
                    System.debug(
                        'Locking NEW CP due to completed Sales visit: ' + rs.Id
                    );
                }
            }
            
        } else {
            Set<Id> newCPIds = new Set<Id>();
            
            for (Related_Source__c r : Trigger.new) {
                if (r.Source_Type__c == 'Channel Partner'
                    && r.Channel_Partner1__c != null) {
                        newCPIds.add(r.Channel_Partner1__c);
                    }
            }
            
            // LOCK OLD CP RECORDS (NORMAL FLOW)
            for (Related_Source__c rs : oldActiveCPRecords) {
                // Skip if OLD CP == NEW CP
                if (rs.Channel_Partner1__c != null
                    && newCPIds.contains(rs.Channel_Partner1__c)) {
                        
                        System.debug('Skipping lock – SAME CP as newly inserted record. ' +'Old RS: ' + rs.Id +' | CP: ' + rs.Channel_Partner1__c );
                        continue;
                    }
                rs.Is_Locked__c = true;
                recordsToLock1.add(rs);
                
                System.debug('Locking OLD CP (normal flow): ' + rs.Id +' | CP: ' + rs.Channel_Partner1__c);
            }
        }
        
        /* ---------------------------------
        STEP C: Execute Lock
        --------------------------------- */
        if (!recordsToLock1.isEmpty()) {
            update recordsToLock1;
            Approval.lock(recordsToLock1);
        }
        
        
        
        /* ============================================================
        LEAD VISIBILITY BASED ON Is_Locked__c Rule:
        - Is_Locked__c = false → Lead VISIBLE
        - Is_Locked__c = true  → Lead NOT visible
        ============================================================ */
        System.debug('================ CALLING SHARING CLASS METHOD =================');
        manulaSharingClass.manageLeadSharingFromRelatedSource(Trigger.new);
        System.debug('================ SHARING CLASS METHOD COMPLETED =================');
        
        System.debug('================ AFTER INSERT COMPLETED =================');
    }

    
    if (Trigger.isBefore && Trigger.isUpdate) {
        List<Related_Source__c> rsUnqualifiedList = new List<Related_Source__c>();

        for (Related_Source__c r : Trigger.new) {
            Related_Source__c oldRecord = Trigger.oldMap.get(r.Id);

            if (r.Mark_Unqualified__c == true && RelatedSourceStatusController.markleadUnqualified && 
                r.Lead_status1__c == 'New' && !r.Lead_Assigned__c && r.No_Of_Times_Unqualified__c <= 2) {
                rsUnqualifiedList.add(r);
            }
        }

        if (rsUnqualifiedList.Size() > 0) {
            RelatedSourceHandler.reassignUnqualifiedLead1(rsUnqualifiedList);
        }
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        RelatedSourceHandler.sendReassignNotifications(Trigger.new, Trigger.oldMap);
      
         /* ============================================================
        LEAD VISIBILITY BASED ON Is_Locked__c Rule:
        - Is_Locked__c = false → Lead VISIBLE
        - Is_Locked__c = true  → Lead NOT visible
        ============================================================ */
        System.debug('================ CALLING SHARING CLASS METHOD =================');
        manulaSharingClass.manageLeadSharingFromRelatedSource(Trigger.new);
        System.debug('================ SHARING CLASS METHOD COMPLETED =================');
    }
}