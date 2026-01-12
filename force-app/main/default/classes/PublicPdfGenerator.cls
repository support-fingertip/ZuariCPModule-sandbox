public class PublicPdfGenerator {

    public static String generatePublicSummaryPdf(
        Datetime fromDate,
        Datetime toDate,String CPId
    ) {

        // 1️⃣ Build VF page
        PageReference pdfPage = Page.SummaryReportPDF;
        pdfPage.getParameters().put(
            'fromDate',
            fromDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
        );
        pdfPage.getParameters().put(
            'toDate',
            toDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
        );
        pdfPage.getParameters().put(
            'CPId',CPId
        );

        // 2️⃣ Generate PDF
        Blob pdfBlob = pdfPage.getContentAsPDF();

        // 3️⃣ Save file
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Summary_Report_' + Datetime.now().getTime();
        cv.PathOnClient = 'Summary_Report.pdf';
        cv.VersionData = pdfBlob;
        insert cv;

        // 4️⃣ Re-query to get Id
        cv = [
            SELECT Id
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        // 5️⃣ CHECK existing public link
        List<ContentDistribution> existing = [
            SELECT Id, DistributionPublicUrl
            FROM ContentDistribution
            WHERE ContentVersionId = :cv.Id ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!existing.isEmpty()) {
            // 🔁 Reuse existing link
            return existing[0].DistributionPublicUrl;
        }

        // 6️⃣ Create public link ONLY if none exists
        ContentDistribution dist = new ContentDistribution();
        dist.Name = 'Summary Report PDF';
        dist.ContentVersionId = cv.Id;
        dist.PreferencesAllowViewInBrowser = true;
        dist.PreferencesAllowOriginalDownload = true;
        dist.PreferencesLinkLatestVersion = true;
        insert dist;

        // 7️⃣ Fetch URL
        dist = [
            SELECT DistributionPublicUrl
            FROM ContentDistribution
            WHERE Id = :dist.Id
        ];

        return dist.DistributionPublicUrl;
    }
}