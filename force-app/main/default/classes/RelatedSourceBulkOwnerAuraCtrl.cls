public with sharing class RelatedSourceBulkOwnerAuraCtrl {

    @AuraEnabled
    public static List<Related_Source__c> fetchRelatedSources(
        Date fromDate,
        Date toDate,
        Id fromUserId,
        String allocatedProjectValue // picklist value filter
    ) {

        String query = 'SELECT Id, Name, OwnerId, Owner.Name, Allocated_Project__c, CreatedDate ' +
                       'FROM Related_Source__c WHERE Id != null';

        if (fromDate != null) {
            query += ' AND CreatedDate >= :fromDate';
        }
        if (toDate != null) {
            query += ' AND CreatedDate <= :toDate';
        }
       if (fromUserId != null) {
            query += ' AND OwnerId = :fromUserId';
        }
        if (allocatedProjectValue != null && allocatedProjectValue != '') {
            query += ' AND Allocated_Project__c = :allocatedProjectValue';
        }

        query += ' ORDER BY CreatedDate DESC LIMIT 500';

        return Database.query(query);
    }

    // Fetch active users for combobox
    @AuraEnabled
    public static List<Map<String,String>> getUsers() {
        List<Map<String,String>> options = new List<Map<String,String>>();
        for(User u : [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name]) {
            options.add(new Map<String,String>{ 'label' => u.Name, 'value' => u.Id });
        }
        return options;
    }

    // Bulk owner update
    @AuraEnabled
    public static void bulkUpdateOwner(List<Id> recordIds, Id toUserId) {
        if(recordIds == null || recordIds.isEmpty()) {
            throw new AuraHandledException('Please select at least one record.');
        }
        if(toUserId == null) {
            throw new AuraHandledException('To User is required.');
        }

        List<Related_Source__c> updateList = new List<Related_Source__c>();
        for(Id recId : recordIds) {
            updateList.add(new Related_Source__c(Id = recId, OwnerId = toUserId));
        }
        update updateList;
    }

    // Fetch Allocated Project picklist values
    @AuraEnabled
    public static List<String> getAllocatedProjectPicklistValues() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldDesc = Related_Source__c.Allocated_Project__c.getDescribe();
        for(Schema.PicklistEntry pe : fieldDesc.getPicklistValues()) {
            values.add(pe.getValue());
        }
        return values;
    }
}