public without sharing class RelatedSourceStatusController {

    public static Boolean markleadUnqualified = false;

    public class dataWrapper {
        @AuraEnabled public String profileName { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
    }

    //  Fetch Profile + Record Type Name for Related_Source__c
    @AuraEnabled
    public static dataWrapper getLeadRecordTypeName(Id relatedSourceId) {
        dataWrapper dw = new dataWrapper();

        Related_Source__c rs = [
            SELECT RecordType.Name, Lead_Record_Type__c
            FROM Related_Source__c
            WHERE Id = :relatedSourceId
            LIMIT 1
        ];
        System.debug('rs' + rs);

        Id profileId = UserInfo.getProfileId();
        Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id = :profileId];

        dw.profileName = userProfile.Name;
        dw.recordTypeName = rs.RecordType.Name;
        return dw;
    }

    // Update Related_Source__c with status & create related records
    @AuraEnabled
    public static String updateLeadWithStatus(
        Id relatedSourceId,
        String status,
        String lastnote,
        Datetime scheduleDate,
        String rating,
        String othercom,
        String openreason,
        String alloctreason
    ) {
        String returnMessage = '';
        List<Lead_Unqualification__c> lqList = new List<Lead_Unqualification__c>();
        User currentUser = [
            SELECT Id, Name, Profile.Name 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ];
        try {
            Related_Source__c rsRecord = [
                SELECT Id,SLead__c,Lead_status1__c,Last_Note__c,RecordTypeId, RecordType.Name, Rating__c, Lead_Status__c,
                       Unqualified_Reason__c, Last_Unqualified_At__c, Remark__c, OwnerId,
                       Last_Unqualified_by__c, Mark_Unqualified__c, No_Of_Times_Unqualified__c,
                       Lead_Assigned__c, Closed_Lost_Reason__c, Reasons_in_Detail__c,
                       Reason_For_Rejection__c, Open_Reason__c, Allocated_Reason__c
                FROM Related_Source__c
                WHERE Id = :relatedSourceId
                LIMIT 1
            ];
            

            // Insert Follow-up if applicable
            if (status == 'RNR' || status == 'Open' || status == 'Allocated'|| status == 'Pre Sales Follow Up' || status == 'Sales Follow up') {
                insert new Follow_Up__c(
                    Related_Source__c = relatedSourceId,
                    Scheduled_Date__c = scheduleDate,
                    Subject__c = 'Follow up for ' + othercom
                );
            }

            // Insert Site Visit if applicable
            if (status == 'Site Visit Schedule') {
                insert new Site_Visit__c(
                    Related_Source__c = relatedSourceId,
                    Date__c = scheduleDate,
                    Status__c = 'Scheduled'
                );
            }

            User u = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
             rsRecord.Lead_status1__c = status;
            //  --- Append Notes Section ---
            if (String.isNotBlank(lastnote)) {
                // Current datetime in IST
                Datetime dt = Datetime.now();
                String strTimeInAMorPM = dt.format('dd-MM-yy hh:mm a', 'Asia/Kolkata');
                
                // Handle numbering
                Integer noteCount = 1;
                if (rsRecord.Last_Note__c == null) {
                    rsRecord.Last_Note__c = '';
                } else if (!rsRecord.Last_Note__c.trim().equals('')) {
                    List<String> notes = rsRecord.Last_Note__c.split('\nCall Summary ');
                    noteCount = notes.size(); // increment automatically
                }
                
                // Append the new note in formatted style
                rsRecord.Execuive_Count__c = noteCount;
                rsRecord.Last_Note__c += '\nCall Summary ' + noteCount + ': '
                    + u.Name + ' [' + strTimeInAMorPM + ']: '
                    + lastnote;
                
                
                Call_Comments__c comment = new Call_Comments__c();
                comment.Comments__c = lastnote;
                comment.User_Profile__c = currentUser.Profile.Name;
                comment.Related_Source__c = rsRecord.id;
                comment.Created_User__c = currentUser.Id;
                comment.Created_Date__c = System.now();
                
                // If Related_Source__c has a Lead__c field, link it
                if (rsRecord.SLead__c != null) {
                    comment.Lead__c = rsRecord.SLead__c;
                }

        insert comment;
            }

           System.debug('STATUS RAW STRING = "' + status + '"');
            System.debug('STATUS LENGTH = ' + status.length());
            System.debug('COMPARISON = ' + (status == 'Request for Rejection'));
            System.debug('RECORD TYPE = ' + rsRecord.RecordType.Name);
            System.debug('No. Unqualified = ' + rsRecord.No_Of_Times_Unqualified__c);
            Integer unqCount = (rsRecord.No_Of_Times_Unqualified__c == null) ? 0 : Integer.valueOf(rsRecord.No_Of_Times_Unqualified__c);
            //Integer unqCount = (rsRecord.No_Of_Times_Unqualified__c == null) ? 0 : Integer.valueOf(rsRecord.No_Of_Times_Unqualified__c.intValue());
             System.debug('No. Unqualified = ' + unqCount);

            // --- Handle Unqualified ---
            if (status == 'Request for Rejection' && rsRecord.RecordType.Name == 'Pre Sales' && unqCount< 3) {
                  System.debug('entered Request for Rejection in pre-sales ');
                markleadUnqualified = true;
                rsRecord.Last_Unqualified_At__c = System.now();
                rsRecord.Last_Unqualified_by__c = UserInfo.getUserId();
                rsRecord.Mark_Unqualified__c = true;
                rsRecord.No_Of_Times_Unqualified__c = unqCount + 1;
                rsRecord.Lead_Assigned__c = false;
                rsRecord.Lead_status1__c = 'New';
                rsRecord.Closed_Lost_Reason__c = rating;
                rsRecord.Reasons_in_Detail__c = othercom;

                Lead_Unqualification__c lq = new Lead_Unqualification__c();
                System.debug('LQ Before adding: ' + lq);
                lq.User__c = UserInfo.getUserId();
                lq.Unqualified_Reason__c = (rating == 'Other') ? (rating + ' : ' + othercom) : rating;
                lq.Unqualified_At__c = System.now();
                lq.Related_Source__c = rsRecord.Id;//  linked to Related_Source__c now
                lq.Lead__c = rsRecord.SLead__c;
                lq.Type__c = 'Pre Sales';
                lqList.add(lq);
               System.debug('LQ LIST SIZE NOW: ' + lqList.size());
            }
            else if(status == 'Request for Rejection' && rsRecord.RecordType.Name=='Sales'){
                 System.debug('entered Request for Rejection in sales ');
                User ur = [SELECT Id, ManagerId FROM User WHERE Id = :rsRecord.OwnerId];
                rsRecord.OwnerId = ur.ManagerId;
                rsRecord.Closed_Lost_Reason__c = rating;
                rsRecord.Reasons_in_Detail__c = othercom;

                Lead_Unqualification__c lq = new Lead_Unqualification__c();
                System.debug('LQ Before adding: ' + lq);
                lq.User__c = UserInfo.getUserId();
                lq.Unqualified_Reason__c = rating + ' : ' + othercom;
                lq.Unqualified_At__c = System.now();
                lq.Related_Source__c = rsRecord.Id;
                 lq.Lead__c = rsRecord.SLead__c;
                lq.Type__c = 'Sales';
                system.debug('added to list');
                lqList.add(lq);
                 System.debug('LQ LIST SIZE NOW: ' + lqList.size());
            }
             if(status == 'Unqualified'){
                rsRecord.Unqualified_Reason__c=rating;
            }

            // --- Handle Rejected ---
            if (status == 'Rejected') {
                rsRecord.Reason_For_Rejection__c = rating;
            }

            // --- Handle Open ---
            if (status == 'Open') {
                rsRecord.Open_Reason__c = openreason;
            }

            // --- Handle Allocated ---
            if (status == 'Allocated') {
                rsRecord.Allocated_Reason__c = alloctreason;
            }
             if(status == 'Closed Lost'){
                rsRecord.Closed_Lost_Reason__c=rating;
            }

            // --- Insert unqualification records if any ---
            if (!lqList.isEmpty()) {
                System.debug('entered');
                

                insert lqList;
            }

             //rsRecord.Lead_status1__c = status;
            //rsRecord.Closed_Lost_Reason__c = rating;

            update rsRecord;
            //AddRelatedSourceNoteController.updateLastNote(rsRecord.Id,lastnote);
            returnMessage = 'Updated Successfully';
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            returnMessage = e.getMessage();
        }

        return returnMessage;
    }

    //  Get Unqualified Reasons Picklist
    @AuraEnabled
    public static List<String> getUnqualifiedReasons() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Related_Source__c.Unqualified_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            options.add(entry.getLabel());
        }
        return options;
    }

    //  Get Closed Lost Reasons Picklist
    @AuraEnabled
    public static List<String> getClosedLostReason() {
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldDescribe = Related_Source__c.Closed_Lost_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            stages.add(entry.getLabel());
        }
        return stages;
    }

    //  Get Open Reason Picklist
    @AuraEnabled
    public static List<String> getOpenReason() {
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldDescribe = Related_Source__c.Open_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            stages.add(entry.getLabel());
        }
        return stages;
    }

    //  Get Allocated Reason Picklist
    @AuraEnabled
    public static List<String> getAllocatedReason() {
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldDescribe = Related_Source__c.Allocated_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            stages.add(entry.getLabel());
        }
        return stages;
    }
    
    @AuraEnabled
    public static String getLeadCurrentStatus(Id relatedSourceId) {
        return [SELECT Lead_status1__c FROM Related_Source__c WHERE Id = :relatedSourceId LIMIT 1].Lead_status1__c;
    }
}