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

    // Related Source
    public static void createNotificationRecordsForRelatedSource(List<Related_Source__c> newList, Map<Id, Related_Source__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> relatedSourceIds = new Set<Id>();
        for (Related_Source__c r : newList) {
            if (r != null && r.Id != null) relatedSourceIds.add(r.Id);
        }
        if (relatedSourceIds.isEmpty()) return;

        Map<Id, Notification__c> existingNotifications = new Map<Id, Notification__c>();
        for (Notification__c n : [
            SELECT Id, Related_Source__c, IsActive__c, Notification_Category__c,
                   Updated_Status__c, Channel_Partner__c, Notification_Redirect_Id__c
            FROM Notification__c
            WHERE Related_Source__c IN :relatedSourceIds
              AND Notification_Category__c = 'User Specific'
              AND IsActive__c = true
        ]) {
            if (n.Related_Source__c != null) existingNotifications.put(n.Related_Source__c, n);
        }

        List<Notification__c> toInsert = new List<Notification__c>();
        List<Notification__c> toUpdate = new List<Notification__c>();

        for (Related_Source__c newRec : newList) {
            if (newRec == null) continue;
            Related_Source__c oldRec = (oldMap != null) ? oldMap.get(newRec.Id) : null;
            if (oldRec == null) continue;

            if (newRec.Lead_status1__c != oldRec.Lead_status1__c && newRec.Channel_Partner1__c != null) {
                Notification__c noti;
                if (existingNotifications.containsKey(newRec.Id)) {
                    noti = existingNotifications.get(newRec.Id);
                } else {
                    noti = new Notification__c();
                    noti.Related_Source__c = newRec.Id;
                    noti.Notification_Category__c = 'User Specific';
                    noti.IsActive__c = true;
                    noti.IsNotificationSent__c = false;
                    toInsert.add(noti);
                }

                noti.Updated_Status__c = newRec.Lead_status1__c;
                noti.Notification_Type__c = 'Lead Notification';
                noti.Notification_Heading__c = 'Lead Status Changed';
                noti.Notification_Content__c = 'Status has been updated by this Lead Owner';
                noti.Channel_Partner__c = newRec.Channel_Partner1__c;
                noti.Notification_Redirect_Id__c = (newRec.Lead_Id__c != null) ? String.valueOf(newRec.Lead_Id__c) : String.valueOf(newRec.Id);

                if (noti.Id != null) toUpdate.add(noti);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }


    // Site Visit - now follows same pattern as Related Source: query existing notifications and update or create
    public static void createNotificationRecordsForSiteVisit(List<Site_Visit__c> newList, Map<Id, Site_Visit__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> siteVisitIds = new Set<Id>();
        for (Site_Visit__c sv : newList) {
            if (sv != null && sv.Id != null) siteVisitIds.add(sv.Id);
        }
        if (siteVisitIds.isEmpty()) return;

        Map<Id, Notification__c> existingNotifications = new Map<Id, Notification__c>();
        for (Notification__c n : [
            SELECT Id, Site_Visit__c, IsActive__c, Notification_Category__c,
                   Updated_Status__c, Channel_Partner__c, Notification_Redirect_Id__c
            FROM Notification__c
            WHERE Site_Visit__c IN :siteVisitIds
              AND Notification_Category__c = 'User Specific'
              AND IsActive__c = true
        ]) {
            if (n.Site_Visit__c != null) existingNotifications.put(n.Site_Visit__c, n);
        }

        List<Notification__c> toInsert = new List<Notification__c>();
        List<Notification__c> toUpdate = new List<Notification__c>();

        for (Site_Visit__c newRec : newList) {
            if (newRec == null) continue;
            Site_Visit__c oldRec = (oldMap != null) ? oldMap.get(newRec.Id) : null;
            if (oldRec == null) continue;

            if (newRec.Status__c != oldRec.Status__c && newRec.Channel_Partner1__c != null) {
                Notification__c noti;
                if (existingNotifications.containsKey(newRec.Id)) {
                    noti = existingNotifications.get(newRec.Id);
                } else {
                    noti = new Notification__c();
                    noti.Site_Visit__c = newRec.Id;
                    noti.Notification_Category__c = 'User Specific';
                    noti.IsActive__c = true;
                    noti.IsNotificationSent__c = false;
                    toInsert.add(noti);
                }

                noti.Updated_Status__c = newRec.Status__c;
                noti.Notification_Type__c = 'Site Visit Notification';
                noti.Notification_Heading__c = 'Site Visit Status Changed';
                noti.Notification_Content__c = 'Status has been updated by Site Visit Owner';
                noti.Channel_Partner__c = newRec.Channel_Partner1__c;
                noti.Notification_Redirect_Id__c = String.valueOf(newRec.Id);

                if (noti.Id != null) toUpdate.add(noti);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }


    // Follow Up - same pattern: check existing Notification__c by Follow_up__c
    public static void createNotificationRecordsForFollowUp(List<Follow_up__c> newList, Map<Id, Follow_up__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> followUpIds = new Set<Id>();
        for (Follow_up__c fu : newList) {
            if (fu != null && fu.Id != null) followUpIds.add(fu.Id);
        }
        if (followUpIds.isEmpty()) return;

        Map<Id, Notification__c> existingNotifications = new Map<Id, Notification__c>();
        for (Notification__c n : [
            SELECT Id, Follow_up__c, IsActive__c, Notification_Category__c,
                   Updated_Status__c, Channel_Partner__c, Notification_Redirect_Id__c
            FROM Notification__c
            WHERE Follow_up__c IN :followUpIds
              AND Notification_Category__c = 'User Specific'
              AND IsActive__c = true
        ]) {
            if (n.Follow_up__c != null) existingNotifications.put(n.Follow_up__c, n);
        }

        List<Notification__c> toInsert = new List<Notification__c>();
        List<Notification__c> toUpdate = new List<Notification__c>();

        for (Follow_up__c newRec : newList) {
            if (newRec == null) continue;
            Follow_up__c oldRec = (oldMap != null) ? oldMap.get(newRec.Id) : null;
            if (oldRec == null) continue;

            if (newRec.Status__c != oldRec.Status__c && newRec.Channel_Partner__c != null) {
                Notification__c noti;
                if (existingNotifications.containsKey(newRec.Id)) {
                    noti = existingNotifications.get(newRec.Id);
                } else {
                    noti = new Notification__c();
                    noti.Follow_up__c = newRec.Id;
                    noti.Notification_Category__c = 'User Specific';
                    noti.IsActive__c = true;
                    noti.IsNotificationSent__c = false;
                    toInsert.add(noti);
                }

                noti.Updated_Status__c = newRec.Status__c;
                noti.Notification_Type__c = 'Followup Notification';
                noti.Notification_Heading__c = 'Follow Up Status Changed';
                noti.Notification_Content__c = 'Status has been updated by Follow Up Owner';
                noti.Channel_Partner__c = newRec.Channel_Partner__c;
                noti.Notification_Redirect_Id__c = String.valueOf(newRec.Id);

                if (noti.Id != null) toUpdate.add(noti);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }


    // Payment - same pattern: check existing Notification__c by Payment_Line_Item__c
    public static void createNotificationRecordsForPayment(List<Payment_Line_Item__c> newList, Map<Id, Payment_Line_Item__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> paymentIds = new Set<Id>();
        for (Payment_Line_Item__c p : newList) {
            if (p != null && p.Id != null) paymentIds.add(p.Id);
        }
        if (paymentIds.isEmpty()) return;

        Map<Id, Notification__c> existingNotifications = new Map<Id, Notification__c>();
        for (Notification__c n : [
            SELECT Id, Payment_Line_Item__c, IsActive__c, Notification_Category__c,
                   Updated_Status__c, Channel_Partner__c, Notification_Redirect_Id__c
            FROM Notification__c
            WHERE Payment_Line_Item__c IN :paymentIds
              AND Notification_Category__c = 'User Specific'
              AND IsActive__c = true
        ]) {
            if (n.Payment_Line_Item__c != null) existingNotifications.put(n.Payment_Line_Item__c, n);
        }

        List<Notification__c> toInsert = new List<Notification__c>();
        List<Notification__c> toUpdate = new List<Notification__c>();

        for (Payment_Line_Item__c newRec : newList) {
            if (newRec == null) continue;
            Payment_Line_Item__c oldRec = (oldMap != null) ? oldMap.get(newRec.Id) : null;
            if (oldRec == null) continue;

            if (newRec.Payament_Status__c != oldRec.Payament_Status__c && newRec.Channel_Partner__c != null) {
                Notification__c noti;
                if (existingNotifications.containsKey(newRec.Id)) {
                    noti = existingNotifications.get(newRec.Id);
                } else {
                    noti = new Notification__c();
                    noti.Payment_Line_Item__c = newRec.Id;
                    noti.Notification_Category__c = 'User Specific';
                    noti.IsActive__c = true;
                    noti.IsNotificationSent__c = false;
                    toInsert.add(noti);
                }

                noti.Updated_Status__c = newRec.Payament_Status__c;
                noti.Notification_Type__c = 'Payment Notification';
                noti.Notification_Heading__c = 'Payment Status Changed';
                noti.Notification_Content__c = 'Status has been updated by Payment Owner';
                noti.Channel_Partner__c = newRec.Channel_Partner__c;
                noti.Notification_Redirect_Id__c = String.valueOf(newRec.Id);

                if (noti.Id != null) toUpdate.add(noti);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }
}
