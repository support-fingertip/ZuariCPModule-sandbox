trigger NotificationTrigger on Notification__c (after insert, after update) {

    
    if(Trigger.IsAfter){
        Set<Id> notificationIds = new Set<Id>();

    for (Notification__c noti : Trigger.new) {

        if (Trigger.isInsert) {

            if (noti.IsActive__c == true && noti.IsNotificationSent__c == false) {

                notificationIds.add(noti.Id);
            }
        }

        if (Trigger.isUpdate) {

            Notification__c oldNoti = Trigger.oldMap.get(noti.Id);

            if (noti.IsActive__c == true && oldNoti.Updated_Status__c != noti.Updated_Status__c) {

                notificationIds.add(noti.Id);
            }
        }
    }

    if (!notificationIds.isEmpty()) {
        NotificationTriggerDispatcher.invokeFromTrigger(notificationIds);
    }
    }
}
