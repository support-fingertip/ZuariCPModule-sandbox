public class AddRelatedSourceNoteController {

    @AuraEnabled
    public static void updateLastNote(String relatedSourceId, String newNote) {
        if (String.isBlank(newNote)) {
            return;
        }

        // Fetch Related_Source__c record
        Related_Source__c rsRecord = [
            SELECT Id, Last_Note__c, Execuive_Count__c, SLead__c
            FROM Related_Source__c 
            WHERE Id = :relatedSourceId 
            LIMIT 1
        ];

        // Get current user
        User currentUser = [
            SELECT Id, Name, Profile.Name 
            FROM User 
            WHERE Id = :UserInfo.getUserId() WITH SYSTEM_MODE
        ];

        // Current datetime in IST
        Datetime dt = Datetime.now();
        TimeZone tz = TimeZone.getTimeZone('Asia/Kolkata');
        String strTimeInAMorPM = dt.format('dd-MM-yy HH:mm a', 'Asia/Kolkata');

        // Handle numbering
        Integer noteCount = 1;
        if (rsRecord.Last_Note__c == null) {
            rsRecord.Last_Note__c = '';
        } else if (!rsRecord.Last_Note__c.trim().equals('')) {
            List<String> notes = rsRecord.Last_Note__c.split('\n');
            noteCount = notes.size() + 1;
        }

        // Update Related Source notes field
        rsRecord.Execuive_Count__c = noteCount;
        rsRecord.Last_Note__c += '\nCall Summary ' + noteCount + ': ' 
                                 + currentUser.Name + ' [' + strTimeInAMorPM + ']: ' 
                                 + newNote;

        update rsRecord;

        // Create Call_Comments__c record
        Call_Comments__c comment = new Call_Comments__c();
        comment.Comments__c = newNote;
        comment.User_Profile__c = currentUser.Profile.Name;
        comment.Related_Source__c = rsRecord.Id;
        comment.Created_User__c = currentUser.Id;
        comment.Created_Date__c = System.now();

       
        insert comment;
        system.debug('=========== updating folowup to completed  call comment is created =========== ');
        completeRelatedSourceFollowups(rsRecord.Id);
        system.debug('=========== updated folowup to completed  call comment is created ===========');
    }

     @AuraEnabled
    public static void updateTLRHSNote(String relatedSourceId, String newNote) {
        User currentUser = [
            SELECT Id, Name, Profile.Name 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ];
        Related_Source__c rsRecord = [
            SELECT Id, Last_Note__c, Execuive_Count__c, SLead__c,TL_RHS_Count__c,TL_RHS_Review__c
            FROM Related_Source__c 
            WHERE Id = :relatedSourceId 
            LIMIT 1
        ];
        User us = [select id,name from User where id =: userInfo.getUserId()];
        Datetime dt = Datetime.now();
        Timezone tz = Timezone.getTimeZone('Asia/Kolkata');
        //dt = dt.addSeconds(tz.getOffset(dt)/1000);
       // String strTimeInAMorPM = dt.format('MMMMM dd, yyyy hh:mm a');
           String strTimeInAMorPM = dt.format('dd-MM-yy HH:mm a');

        Integer noteCount = 1;
        if (rsRecord.TL_RHS_Review__c == null) {
            rsRecord.TL_RHS_Review__c = '';
        } else if (!rsRecord.TL_RHS_Review__c.trim().equals('')) {
            List<String> notes = rsRecord.TL_RHS_Review__c.split('\n');
            noteCount = notes.size() + 1;
        }
       rsRecord.TL_RHS_Count__c = noteCount;
       // leadRecord.Last_Note__c += '\nNote ' + noteCount +' : ('+us.Name+')' + ' - (' + strTimeInAMorPM + ') :      '+newNote  ;
       rsRecord.TL_RHS_Review__c += '\nTL/RHS Comment ' + noteCount + ': ' + us.Name + ' [' + strTimeInAMorPM + ']: ' + newNote;
   
        update rsRecord;
        
        Call_Comments__c comment = new Call_Comments__c();
        comment.Comments__c = newNote;
        comment.User_Profile__c = currentUser.Profile.Name;
        comment.Related_Source__c = relatedSourceId;
        comment.Created_User__c = currentUser.Id;
        comment.Created_Date__c = System.now();

       

        insert comment;
    }
    
@AuraEnabled
public static List<String> fetchLeadLastNotes(String relatedSourceId) {
    // Query Call Comments related to the Related Source
    List<Call_Comments__c> callComments = [
        SELECT Id, Comments__c, Created_Date__c, Created_User__c, User_Profile__c, 
               Lead__c, Related_Source__c, CreatedDate, CreatedBy.Name
        FROM Call_Comments__c 
        WHERE Related_Source__c = :relatedSourceId
        ORDER BY Created_Date__c DESC NULLS LAST, CreatedDate DESC 
    ];
    
    List<String> formattedNotes = new List<String>();
    
    // Return each comment text
    for (Call_Comments__c comment : callComments) {
        if (String.isNotBlank(comment.Comments__c)) {
            formattedNotes.add(comment.Comments__c);
        }
    }
    
    return formattedNotes;
}
    
private static void completeRelatedSourceFollowups(Id relatedSourceId) {
    System.debug('>>> completeRelatedSourceFollowups called for RelatedSourceId: ' + relatedSourceId);

    if (relatedSourceId == null) {
        System.debug('>>> RelatedSourceId is null, exiting.');
        return;
    }

    String mode = System.Label.Followup_Completion_Mode; // "today" or "all" or "True"
    System.debug('>>> Custom Label Followup_Completion_Mode value: ' + mode);

    Datetime nowDt = System.now();
    Date today = nowDt.date();
    System.debug('>>> Current Datetime: ' + nowDt + ' | Today: ' + today);

    List<Follow_up__c> followupsToComplete = new List<Follow_up__c>();

    if (mode == 'True') {
        System.debug('>>> Mode is True: completing only today\'s followups whose time has passed');

        // Query all scheduled follow-ups for this Related Source
        List<Follow_up__c> allFollowups = [
            SELECT Id, Status__c, Comments__c, Scheduled_Date__c
            FROM Follow_up__c
            WHERE Related_Source__c = :relatedSourceId
            AND Status__c = 'Scheduled'
            AND Scheduled_Date__c != null
        ];
        System.debug('>>> Total scheduled followups fetched: ' + allFollowups.size());

        // Filter in Apex: only today's datetime that has already passed
        for (Follow_up__c fu : allFollowups) {
            System.debug('>>> Checking followup Id: ' + fu.Id + ' | Scheduled_Date__c: ' + fu.Scheduled_Date__c);
            if (fu.Scheduled_Date__c.date() == today && fu.Scheduled_Date__c <= nowDt) {
                System.debug('>>> Adding followup to complete: ' + fu.Id);
                followupsToComplete.add(fu);
            }
        }

    } else if (mode == 'False') {
        System.debug('>>> Mode is all: completing all scheduled followups');

        // Normal flow: all scheduled follow-ups
        followupsToComplete = [
            SELECT Id, Status__c, Comments__c
            FROM Follow_up__c
            WHERE Related_Source__c = :relatedSourceId
            AND Status__c = 'Scheduled'
        ];
        System.debug('>>> Total followups to complete: ' + followupsToComplete.size());
    } else {
        System.debug('>>> Mode does not match "True" or "all", no followups will be completed');
    }

    // Mark as completed
    for (Follow_up__c fu : followupsToComplete) {
        System.debug('>>> Completing followup Id: ' + fu.Id);
        fu.Status__c = 'Completed';
        fu.Comments__c = 'Called the customer, added call comments';
    }

    if (!followupsToComplete.isEmpty()) {
        System.debug('>>> Updating followups: ' + followupsToComplete);
        update followupsToComplete;
    } else {
        System.debug('>>> No followups to update');
    }
}


}