public with sharing class NotificationHandler {
   /**
 * @description
 * Handler class responsible for creating Notification__c records
 *
 * This class is invoked from the RelatedSourceTrigger,FollowUpTrigger,SiteVisitTrigger and PaymentTrigger during the
 * after update context and detects status field changes
 * to initiate notification creation.
 *
 *
 * @usage
 * Called from RelatedSourceTrigger (after update context).
 * Called from SiteVisitTrigger (after update context).
 * Called from FollowUpTrigger (after update context).
 * Called from PaymentTrigger (after update context).
 *
 * @author
 * Praveen Kumar
 *
 */
    public static void createNotificationRecordsForRelatedSource(List<Related_Source__c> newList,  Map<Id, Related_Source__c> oldMap) {
    Map<Id, Notification__c> existingNotifications = new Map<Id, Notification__c>();

    // Fetch existing notifications
    for (Notification__c n :[SELECT Id, Related_Source__c
         					FROM Notification__c
         					WHERE Related_Source__c IN :newList
         					AND Notification_Category__c = 'User Specific'
         					AND IsActive__c = true]) {
        existingNotifications.put(n.Related_Source__c, n);
    }

    List<Notification__c> toInsert = new List<Notification__c>();
    List<Notification__c> toUpdate = new List<Notification__c>();

    for (Related_Source__c newRec : newList) {
        Related_Source__c oldRec = oldMap.get(newRec.Id);

        if (newRec.Lead_status1__c != oldRec.Lead_status1__c &&
            newRec.Channel_Partner1__c != null) {

            Notification__c noti;

            if (existingNotifications.containsKey(newRec.Id)) {
               
                noti = existingNotifications.get(newRec.Id);
            } else {
                // CREATE
                noti = new Notification__c();
                noti.Related_Source__c = newRec.Id;
                noti.Notification_Category__c = 'User Specific';
                noti.IsActive__c = true;
                noti.IsNotificationSent__c = false;
                toInsert.add(noti);
            }

            // Common field updates
            noti.Updated_Status__c = newRec.Lead_status1__c;
            noti.Notification_Type__c = 'Lead Notification';
            noti.Notification_Heading__c = 'Lead Status Changed';
            noti.Notification_Content__c = 'Status has been updated by this Lead Owner';
            noti.Channel_Partner__c = newRec.Channel_Partner1__c;
            noti.Notification_Redirect_Id__c = newRec.Lead_Id__c;

            if (noti.Id != null) {
                toUpdate.add(noti);
            }
        }
    }

    if (!toInsert.isEmpty()) insert toInsert;
    if (!toUpdate.isEmpty()) update toUpdate;
}


public static void createNotificationRecordsForSiteVisit(List<Site_Visit__c> newList, Map<Id, Site_Visit__c> oldMap  ) {
        List<Notification__c> notificationsToInsert = new List<Notification__c>();
    for (Site_Visit__c newRec : newList) {

        Site_Visit__c oldRec = oldMap.get(newRec.Id);

        // ✅ Condition 1: Visit Status changed
        Boolean isStatusChanged = newRec.Status__c != oldRec.Status__c;

        // ✅ Condition 2: Channel Partner exists
        Boolean hasChannelPartner = newRec.Channel_Partner1__c != null;
        if (isStatusChanged && hasChannelPartner) {

            Notification__c noti = new Notification__c();
            noti.Site_Visit__c = newRec.Id;
            
            noti.Updated_Status__c = newRec.Status__c;
            noti.Notification_Type__c = 'Site Visit Notification';
            noti.Notification_Heading__c = 'Site Visit Status Changed';
            noti.Notification_Content__c = 'Status has been updated by Site Visit Owner';
            noti.IsActive__c = true;
            noti.Channel_Partner__c = newRec.Channel_Partner1__c;
            noti.Notification_Redirect_Id__c= newRec.Name;
            noti.IsNotificationSent__c = false;
            noti.Notification_Category__c='User Specific';

            notificationsToInsert.add(noti);
        }
}
    
    if (!notificationsToInsert.isEmpty()) {
        insert notificationsToInsert;
    }
}
    public static void createNotificationRecordsForFollowUp(List<Follow_up__c> newList, Map<Id, Follow_up__c> oldMap  ) {
        List<Notification__c> notificationsToInsert = new List<Notification__c>();
    for (Follow_up__c newRec : newList) {

        Follow_up__c oldRec = oldMap.get(newRec.Id);

        // ✅ Condition 1: Follow Up Status changed
        Boolean isStatusChanged = newRec.Status__c != oldRec.Status__c;

        // ✅ Condition 2: Channel Partner exists
        Boolean hasChannelPartner = newRec.Channel_Partner__c != null;
        if (isStatusChanged && hasChannelPartner) {

            Notification__c noti = new Notification__c();
            noti.Follow_up__c = newRec.Id;
            
            noti.Updated_Status__c = newRec.Status__c;
                noti.Notification_Type__c = 'Followup Notification';
            noti.Notification_Heading__c = 'Follow Up Status Changed';
            noti.Notification_Content__c = 'Status has been updated by Follow Up Owner';
            noti.IsActive__c = true;
            noti.Channel_Partner__c = newRec.Channel_Partner__c;
            noti.Notification_Redirect_Id__c= newRec.Name;
            noti.IsNotificationSent__c = false;
            noti.Notification_Category__c='User Specific';

            notificationsToInsert.add(noti);
        }
    }
    if (!notificationsToInsert.isEmpty()) {
        insert notificationsToInsert;
    }
    }
    public static void createNotificationRecordsForPayment(List<Payment_Line_Item__c> newList, Map<Id, Payment_Line_Item__c> oldMap  ) {
        List<Notification__c> notificationsToInsert = new List<Notification__c>();
    for (Payment_Line_Item__c newRec : newList) {

        Payment_Line_Item__c oldRec = oldMap.get(newRec.Id);

        // ✅ Condition 1: Payment Status changed
        Boolean isStatusChanged = newRec.Payament_Status__c != oldRec.Payament_Status__c;

        // ✅ Condition 2: Channel Partner exists
        Boolean hasChannelPartner = newRec.Channel_Partner__c != null;
        if (isStatusChanged && hasChannelPartner) {

            Notification__c noti = new Notification__c();
            noti.Payment_Line_Item__c = newRec.Id;
            
            noti.Updated_Status__c = newRec.Payament_Status__c;
            noti.Notification_Type__c = 'Payment Notification';
            noti.Notification_Heading__c = 'Payment Status Changed';
            noti.Notification_Content__c = 'Status has been updated by Payment Owner';
            noti.IsActive__c = true;
            noti.Channel_Partner__c = newRec.Channel_Partner__c;
            noti.Notification_Redirect_Id__c= newRec.Payment_Line_Item__c;
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