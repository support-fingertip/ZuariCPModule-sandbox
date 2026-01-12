public without sharing class ChannelPartnerController {
    
    @AuraEnabled
    public static String createChannelPartner(Map<String, Object> fieldValues) {
        try {
            // Create Channel_Partner__c record
            Channel_Partner__c cp = new Channel_Partner__c();
            
            // Map all fields from the form
            if (fieldValues.containsKey('Company_Name__c')) {
                cp.Name = (String) fieldValues.get('Company_Name__c');
                cp.Company_Name__c = (String) fieldValues.get('Company_Name__c');
            }
            if (fieldValues.containsKey('Company_Head_Name__c')) {
                cp.Company_Head_Name__c = (String) fieldValues.get('Company_Head_Name__c');
            }
            if (fieldValues.containsKey('Company_Owner_Name__c')) {
                cp.Company_Owner_Name__c = (String) fieldValues.get('Company_Owner_Name__c');
            }
            if (fieldValues.containsKey('Team_Strength__c')) {
                cp.Team_Strength__c = (String) fieldValues.get('Team_Strength__c');
            }
            if (fieldValues.containsKey('Company_Website__c')) {
                cp.Company_Website__c = (String) fieldValues.get('Company_Website__c');
            }
            if (fieldValues.containsKey('Email__c')) {
                cp.Email__c = (String) fieldValues.get('Email__c');
            }
            if (fieldValues.containsKey('Company_Head_Email_ID__c')) {
                cp.Company_Head_Email_ID__c = (String) fieldValues.get('Company_Head_Email_ID__c');
            }
            if (fieldValues.containsKey('Company_Owner_Email_ID__c')) {
                cp.Company_Owner_Email_ID__c = (String) fieldValues.get('Company_Owner_Email_ID__c');
            }
            if (fieldValues.containsKey('Company_Head_Contact_No__c')) {
                cp.Company_Head_Contact_No__c = (String) fieldValues.get('Company_Head_Contact_No__c');
            }
            if (fieldValues.containsKey('Company_Owner_Contact_No__c')) {
                cp.Company_Owner_Contact_No__c = (String) fieldValues.get('Company_Owner_Contact_No__c');
            }
            if (fieldValues.containsKey('Company_Address__c')) {
                cp.Company_Address__c = (String) fieldValues.get('Company_Address__c');
            }
            if (fieldValues.containsKey('City__c')) {
                cp.City__c = (String) fieldValues.get('City__c');
            }
            if (fieldValues.containsKey('City_you_reside_in__c')) {
                cp.City_you_reside_in__c = (String) fieldValues.get('City_you_reside_in__c');
            }
            if (fieldValues.containsKey('Select_Region__c')) {
                cp.Select_Region__c = (String) fieldValues.get('Select_Region__c');
            }
            if (fieldValues.containsKey('Company_GST_No__c')) {
                cp.Company_GST_No__c = (String) fieldValues.get('Company_GST_No__c');
            }
            if (fieldValues.containsKey('Company_PAN_Card_No__c')) {
                cp.Company_PAN_Card_No__c = (String) fieldValues.get('Company_PAN_Card_No__c');
            }
            if (fieldValues.containsKey('PAN_Card_No__c')) {
                cp.PAN_Card_No__c = (String) fieldValues.get('PAN_Card_No__c');
            }
            if (fieldValues.containsKey('Company_RERA_No__c')) {
                cp.Company_RERA_No__c = (String) fieldValues.get('Company_RERA_No__c');
            }
            if (fieldValues.containsKey('RERA_Validity__c')) {
                // Handle date field
                Object dateValue = fieldValues.get('RERA_Validity__c');
                if (dateValue instanceof String) {
                    cp.RERA_Validity__c = Date.valueOf((String) dateValue);
                } else if (dateValue instanceof Date) {
                    cp.RERA_Validity__c = (Date) dateValue;
                }
            }
            
            insert cp;
            
            // CRITICAL FIX: Return the ID, not the Name
            return cp.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating record: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String saveFileToRecord(String recordId, String fileName, String base64Data, String contentType) {
        try {
            // Validate inputs
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required');
            }
            if (String.isBlank(fileName)) {
                throw new AuraHandledException('File name is required');
            }
            if (String.isBlank(base64Data)) {
                throw new AuraHandledException('File data is required');
            }
            
            // Create ContentVersion (the actual file)
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.IsMajorVersion = true;
            // Don't use FirstPublishLocationId - it's unreliable
            
            insert cv;
            
            // Get the ContentDocumentId from the newly created ContentVersion
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            
            // Check if link already exists
            List<ContentDocumentLink> existingLinks = [
                SELECT Id 
                FROM ContentDocumentLink 
                WHERE ContentDocumentId = :cv.ContentDocumentId 
                AND LinkedEntityId = :recordId 
                LIMIT 1
            ];
            
            // Create ContentDocumentLink only if it doesn't exist
            if (existingLinks.isEmpty()) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.LinkedEntityId = recordId;
                cdl.ShareType = 'V'; // V = Viewer permission
                cdl.Visibility = 'AllUsers'; // Visible to all users with access to record
                
                insert cdl;
            }
            
            return cv.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
        }
    }
}