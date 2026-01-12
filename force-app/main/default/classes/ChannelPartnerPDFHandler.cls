public class ChannelPartnerPDFHandler {

    public static void process(
        List<Channel_Partner__c> newList,
        Map<Id, Channel_Partner__c> oldMap
    ) {
        Set<Id> partnerIds = new Set<Id>();

        for (Channel_Partner__c cp : newList) {
            Channel_Partner__c oldCp = oldMap.get(cp.Id);

            if (cp.From_Date__c != oldCp.From_Date__c ||
                cp.To_Date__c   != oldCp.To_Date__c) {
                partnerIds.add(cp.Id);
            }
        }

        if (!partnerIds.isEmpty()) {
            System.enqueueJob(
                new ChannelPartnerPDFQueueable(partnerIds)
            );
        }
    }
}