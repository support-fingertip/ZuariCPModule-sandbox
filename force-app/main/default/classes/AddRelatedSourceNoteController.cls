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

}