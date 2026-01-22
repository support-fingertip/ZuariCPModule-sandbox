@IsTest
private class RelatedSourceStatusController_Test {
    @IsTest
    static void fullCoverageTest() {
        List<RecordType> rts = [
            SELECT Id, DeveloperName, Name
            FROM RecordType
            WHERE SObjectType = 'Related_Source__c'
        ];
        
        Id rtPre;
        Id rtSales;
        
        for (RecordType rt : rts) {
            if (rt.Name == 'Pre Sales') rtPre = rt.Id;
            if (rt.Name == 'Sales') rtSales = rt.Id;
        }

        

        Related_Source__c rsPre = new Related_Source__c(
            RecordTypeId = rtPre,
            No_Of_Times_Unqualified__c = 0,
            Lead_status1__c = 'New'
        );
        Related_Source__c rsSales = new Related_Source__c(
            RecordTypeId = rtSales,
            No_Of_Times_Unqualified__c = 1,
            Lead_status1__c = 'New sales enquiry'
        );

        insert new List<Related_Source__c>{ rsPre, rsSales };

        // ONE startTest
        Test.startTest();

        // ------------------- ALL TEST EXECUTIONS BELOW ---------------------

        // 1) getLeadRecordTypeName
        RelatedSourceStatusController.dataWrapper dw =
            RelatedSourceStatusController.getLeadRecordTypeName(rsPre.Id);

        // 2) updateLeadWithStatus - RNR
        String msgRNR = RelatedSourceStatusController.updateLeadWithStatus(
            rsPre.Id, 'RNR', 'First follow up note', Datetime.now().addDays(2),
            null, 'FollowUpContext', null, null
        );

        // 3) Site Visit
        String msgSite = RelatedSourceStatusController.updateLeadWithStatus(
            rsPre.Id, 'Site Visit Schedule', 'Visit note', Datetime.now().addDays(5),
            null, 'VisitContext', null, null
        );

        // 4) Request For Rejection (Pre Sales)
        String msgRejectPre = RelatedSourceStatusController.updateLeadWithStatus(
            rsPre.Id, 'Request For Rejection', 'Reject pre', Datetime.now(),
            'Other', 'Other reason', null, null
        );

        // 5) Request For Rejection (Sales)
        String msgRejectSales = RelatedSourceStatusController.updateLeadWithStatus(
            rsSales.Id, 'Request For Rejection', 'Reject sales', Datetime.now(),
            'Price Issue', 'details', null, null
        );

        // 6) Unqualified
        String msgUnq = RelatedSourceStatusController.updateLeadWithStatus(
            rsSales.Id, 'Unqualified', null, null,
            'Duplicate', null, null, null
        );

        // 7) Rejected
        String msgRejected = RelatedSourceStatusController.updateLeadWithStatus(
            rsSales.Id, 'Rejected', null, null,
            'No Budget', null, null, null
        );

        // 8) Open
        String msgOpen = RelatedSourceStatusController.updateLeadWithStatus(
            rsSales.Id, 'Open', null, null,
            null, null, 'Callback reason', null
        );

        // 9) Allocated
        String msgAlloc = RelatedSourceStatusController.updateLeadWithStatus(
            rsSales.Id, 'Allocated', null, null,
            null, null, null, 'Allocated system'
        );

        // 10) Closed Lost
        String msgClosed = RelatedSourceStatusController.updateLeadWithStatus(
            rsSales.Id, 'Closed Lost', null, null,
            'LostReason', null, null, null
        );

        // 11) getLeadCurrentStatus
        String status = RelatedSourceStatusController.getLeadCurrentStatus(rsSales.Id);

        // 12) Picklist describe methods
        List<String> uq = RelatedSourceStatusController.getUnqualifiedReasons();
        List<String> cr = RelatedSourceStatusController.getClosedLostReason();
        List<String> op = RelatedSourceStatusController.getOpenReason();
        List<String> al = RelatedSourceStatusController.getAllocatedReason();

        // ------------------- END OF TEST EXECUTIONS ---------------------

        Test.stopTest();

      
    }
}