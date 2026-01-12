/****************************************************************
* Class Name   : SummaryReport_MobileAPI
* Company      : Fingertipplus
* Created Date : 27-05-2025
*
* @description :
* This Apex REST API exposes the endpoint `/SummaryReportAPI/*` and is
* designed to generate a consolidated summary report for a Channel
* Partner within a given date range.
*
* The API aggregates key business metrics such as Leads, Allocations,
* Site Visits, Revisits, and Bookings, and also generates a public
* PDF summary report link for download.
*
* Functional Overview:
* - Accepts a JSON POST request containing:
*     • userId (mandatory)
*     • fromDate (mandatory)
*     • endDate (mandatory)
* - Validates the Channel Partner using User_Id__c and Active__c flag.
* - Updates the Channel Partner record with selected From and To dates.
* - Calculates summary counts within the provided date range.
*
* Summary Metrics Generated:
* - Total Leads
* - Allocated Leads
* - Site Visits
* - Revisit Count
* - Booked Leads
* - Leads vs Allocation
* - Allocation vs Site Visits
* - Site Visit vs Revisit
* - Revisit vs Bookings
* - Site Visits vs Bookings
* - Leads vs Bookings
*
* PDF Report Generation:
* - Generates a publicly accessible PDF summary report
*   using a Visualforce-based PDF generator.
* - Returns the PDF download URL in the API response.
*
* Response & Logging:
* - Returns structured JSON response containing:
*     • Summary metrics list
*     • Public PDF report URL
* - Logs request, response, and error details in Apex_Log__c.
* - Provides clear error messages for invalid input or user validation.
*
* Key Features:
* - Channel Partner–specific reporting
* - Date-range based aggregation
* - Single API for dashboard & reporting
* - Public (no-login) PDF generation
* - Mobile-friendly response structure
*
* Author       : Praveen Kumar
*
* Change Log:
* --------------------------------------------------------------------------
* Ver | Author         | Date       | Description
* --------------------------------------------------------------------------
* 1.0 | Praveen Kumar  | 27-12-2025 | Initial implementation
* --------------------------------------------------------------------------
**************************************************************/

@RestResource(urlMapping='/SummaryReportAPI/*')
global without sharing class SummaryReport_MobileAPI {

    @HttpPost
    global static void getSummaryReport() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
         Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'SummaryReportAPI';
        log.Request__c = requestBody;
       

        SummaryRequestWrapper input;
        try {
            input = (SummaryRequestWrapper)
                JSON.deserialize(requestBody, SummaryRequestWrapper.class);
        } catch (Exception e) {
             log.Response__c = 'Invalid request format';
                log.Status__c = 'FAIL';
                insert log;
               
            sendError('Invalid request format');
            return;
        }

        if (input.userId == null || input.fromDate == null || input.endDate == null) {
             log.Response__c = 'userId, fromDate and endDate are mandatory';
                log.Status__c = 'FAIL';
                insert log;
               
            sendError('userId, fromDate and endDate are mandatory');
            return;
        }

        Datetime fromDT = input.fromDate;
        Datetime toDT   = input.endDate;
        List<Channel_Partner__c> cmList = [ SELECT Id,To_Date__c,From_Date__c FROM Channel_Partner__c  WHERE User_Id__c = :input.userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                log.Response__c = 'User Not Found';
                log.Status__c = 'FAIL';
                insert log;
                sendError('User Not Found in System');
                return;
            }
         cmList[0].From_Date__c = Date.ValueOf(fromDT);
        cmList[0].To_Date__c = Date.ValueOf(toDT);

        Update cmList[0];


        List<SummaryItem> summaryList = new List<SummaryItem>();

        /* =======================
           1. TOTAL LEADS
           ======================= */
        Integer totalLeads = [SELECT COUNT()  FROM Lead WHERE CreatedDate >= :fromDT AND CreatedDate <= :toDT And Channel_Partner__c =:cmList[0].Id];
        summaryList.add(new SummaryItem('Lead Summary', totalLeads));

        /* =======================
           2. LEAD ALLOCATED SUMMARY
           ======================= */
        Integer allocatedLeads = [SELECT COUNT() FROM Lead WHERE Lead_Status__c = 'Allocated' AND CreatedDate >= :fromDT AND CreatedDate <= :toDT And Channel_Partner__c =:cmList[0].Id];
        summaryList.add(new SummaryItem('Lead Allocated Summary', allocatedLeads));

        /* =======================
           3. SITE VISIT SUMMARY
           ======================= */
        Integer siteVisitCount = [ SELECT COUNT()  FROM Site_Visit__c WHERE CreatedDate >= :fromDT AND CreatedDate <= :toDT AND Channel_Partner__c=:cmList[0].Id];
        summaryList.add(new SummaryItem('Site Visit Summary', siteVisitCount));

        /* =======================
           4. REVISIT SUMMARY
           ======================= */
        Integer revisitCount = [SELECT COUNT() FROM Site_Visit__c WHERE Visit_Type__c = 'Revisit' AND CreatedDate >= :fromDT AND CreatedDate <= :toDT AND Channel_Partner__c=:cmList[0].Id];
        summaryList.add(new SummaryItem('Revisit Summary', revisitCount));

        /* =======================
           5. BOOKED LEADS
           ======================= */
        Integer bookedLeads = [SELECT COUNT() FROM Lead WHERE Lead_Status__c = 'Booked' AND CreatedDate >= :fromDT AND CreatedDate <= :toDT AND Channel_Partner__c=:cmList[0].Id];
        summaryList.add(new SummaryItem('Booked Leads', bookedLeads));

        /* =======================
           6. LEADS v ALLOCATION
           ======================= */
        summaryList.add(new SummaryItem('Leads v Allocation',allocatedLeads));

        /* =======================
           7. ALLOCATION v SITE VISITS
           ======================= */
        summaryList.add(new SummaryItem('Allocation v Site Visits',Math.min(allocatedLeads, siteVisitCount) ));

        /* =======================
           8. SITE VISIT v REVISIT
           ======================= */
        summaryList.add(new SummaryItem('Site Visit v Revisit',Math.min(siteVisitCount, revisitCount)));

        /* =======================
           9. REVISIT v BOOKINGS
           ======================= */
        summaryList.add(new SummaryItem('Revisit v Bookings', Math.min(revisitCount, bookedLeads)));

        /* =======================
           10. SITE VISITS v BOOKINGS
           ======================= */
        summaryList.add( new SummaryItem('Site Visits v Bookings', Math.min(siteVisitCount, bookedLeads)));

        /* =======================
           11. LEADS v BOOKINGS
           ======================= */
        summaryList.add(new SummaryItem( 'Leads v Bookings',Math.min(totalLeads, bookedLeads)));

        /* =======================
           PDF URL (VF PDF)
           ======================= */
        // -----------------------------------------
// Generate PUBLIC (no-login) PDF URL
// -----------------------------------------
String publicPdfUrl = PublicPdfGenerator.generatePublicSummaryPdf(  input.fromDate,   input.endDate, cmList[0].Id);
        

        SummaryResponseWrapper response = new SummaryResponseWrapper();
        response.status = true;
        response.message = 'Summary Report';
        response.data = summaryList;
       response.reportUrl = publicPdfUrl;

        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(response));
    }

    /* =======================
       REQUEST WRAPPER
       ======================= */
    public class SummaryRequestWrapper {
        public String userId;
        public Datetime fromDate;
        public Datetime endDate;
    }

    /* =======================
       RESPONSE WRAPPERS
       ======================= */
    public class SummaryResponseWrapper {
        public Boolean status;
        public String message;
        public List<SummaryItem> data;
        public String reportUrl;
    }

    public class SummaryItem {
        public String reportName;
        public Integer count;

        public SummaryItem(String name, Integer cnt) {
            reportName = name;
            count = cnt;
        }
    }

    /* =======================
       ERROR HANDLER
       ======================= */
    private static void sendError(String msg) {
        RestContext.response.statusCode = 400;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'status' => false,
                'message' => msg
            }));
    }
}