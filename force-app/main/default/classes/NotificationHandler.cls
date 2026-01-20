public with sharing class NotificationHandler {
     /**
 * @description
 * Handler class responsible for creating Notification__c records
 *
 * This class is invoked from the RelatedSourceTrigger during the
 * after update context and detects lead status field changes
 * to initiate notification creation.
 *
 * Business Rules Implemented:
 * - Detects change in Lead_status1__c field
 * - Verifies Channel_Partner1__c lookup is populated
 * - Creates a Notification__c record when both conditions are satisfied
 *
 *
 * @usage
 * Called from RelatedSourceTrigger (after update context).
 *
 * @author
 * Praveen Kumar
 *
 */

    public static void createNotificationRecordsForRelatedSource(List<Related_Source__c> newList, Map<Id, Related_Source__c> oldMap  ) {

        List<Notification__c> notificationsToInsert = new List<Notification__c>();

        for (Related_Source__c newRec : newList) {

            Related_Source__c oldRec = oldMap.get(newRec.Id);

            // ✅ Condition 1: Lead status changed
            Boolean isStatusChanged =
                newRec.Lead_status1__c != oldRec.Lead_status1__c;

            // ✅ Condition 2: Channel Partner exists
            Boolean hasChannelPartner = newRec.Channel_Partner1__c != null;

            if (isStatusChanged && hasChannelPartner) {

                Notification__c noti = new Notification__c();
                noti.Related_Source__c = newRec.Id;
                noti.Notification_Type__c = 'Lead Notification';
                noti.Notification_Heading__c = 'Lead Status Changed';
                noti.Notification_Content__c = 'Status has been updated by this Lead Owner';
                noti.IsActive__c = true;
                noti.Channel_Partner__c = newRec.Channel_Partner1__c;
                noti.Notification_Redirect_Id__c= newRec.Lead_Id__c;
                noti.IsNotificationSent__c = false;
                noti.Notification_Category__c='User Specific';

                notificationsToInsert.add(noti);
            }
        }

        if (!notificationsToInsert.isEmpty()) {
            insert notificationsToInsert;
        }
    }
}