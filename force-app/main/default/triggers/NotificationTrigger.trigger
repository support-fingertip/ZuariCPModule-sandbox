trigger NotificationTrigger on Notification__c (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {

         Set<Id> notificationIds = new Set<Id>();

        for (Notification__c noti : Trigger.new) {

            if (noti.IsActive__c == true &&  noti.IsNotificationSent__c == false) {

                notificationIds.add(noti.Id);
            }
        }

        // Invoke dispatcher once per trigger execution
        if (!notificationIds.isEmpty()) {
            NotificationTriggerDispatcher.invokeFromTrigger(notificationIds);
        }
    }
    
}
