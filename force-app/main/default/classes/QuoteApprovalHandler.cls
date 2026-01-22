public class QuoteApprovalHandler {
    public static void processQuotes(List<Quote__c> quoteList) {
        try {
            if (quoteList.isEmpty()) return;

            // Collect User IDs and Project Names for bulk processing
            Set<Id> userIds = new Set<Id>();
            Set<String> projectNames = new Set<String>();

         /*   for (Quote__c q : quoteList) {
                if (q.OwnerId != null && q.Project__c != null) {
                    userIds.add(q.OwnerId);
                    projectNames.add(q.Project__c);
                }
            }

            if (userIds.isEmpty() || projectNames.isEmpty()) return;

            // Query Discount Limits in bulk
            Map<String, Decimal> discountLimitMap = new Map<String, Decimal>();
            for (Discount_Limit__c dl : [SELECT Executive__c, Project__c, Maximum_Discount__c  FROM Discount_Limit__c WHERE Executive__c IN :userIds AND Project__c IN :projectNames ]) {
                String key = dl.Executive__c + '-' + dl.Project__c;
                discountLimitMap.put(key, dl.Maximum_Discount__c);
            }
*/
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();

            for (Quote__c q : quoteList) {
                    // Submit for Approval
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setObjectId(q.Id);
                    req.setSubmitterId(q.OwnerId);
                    req.setProcessDefinitionNameOrId('Quote_Approval'); // Ensure this process exists
                    req.setSkipEntryCriteria(false);
                    approvalRequests.add(req);
                
            }

            if (!approvalRequests.isEmpty()) {
                Approval.ProcessResult[] results = Approval.process(approvalRequests);
                
                // Error Handling - Log failed approval processes
                for (Approval.ProcessResult result : results) {
                    if (!result.isSuccess()) {
                        System.debug('Approval submission failed: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in QuoteApprovalHandler: ' + e.getMessage());
        }
    }
}