public class ChannelPartnerPDFQueueable
        implements Queueable, Database.AllowsCallouts {

    private Set<Id> channelPartnerIds;

    public ChannelPartnerPDFQueueable(Set<Id> cpIds) {
        this.channelPartnerIds = cpIds;
    }

    public void execute(QueueableContext context) {

        // 🔹 Delete old "Summary Report" PDFs
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :channelPartnerIds
        ];

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : links) {
            docIds.add(cdl.ContentDocumentId);
        }

        if (!docIds.isEmpty()) {
            List<ContentDocument> docs = [
                SELECT Id
                FROM ContentDocument
                WHERE Id IN :docIds
                AND Title = 'Summary Report'
            ];
            if (!docs.isEmpty()) {
                delete docs;
            }
        }

        // 🔹 Generate & upload new PDFs
        List<ContentVersion> versions = new List<ContentVersion>();

        for (Id cpId : channelPartnerIds) {

            PageReference pr =
                Page.SummaryReportPDF;
            pr.getParameters().put('id', cpId);

            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test PDF');
            } else {
                pdfBlob = pr.getContentAsPDF();
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Summary Report';
            cv.PathOnClient = 'Summary Report.pdf';
            cv.VersionData = pdfBlob;
            cv.FirstPublishLocationId = cpId;

            versions.add(cv);
        }

        if (!versions.isEmpty()) {
            insert versions;
        }
    }
}