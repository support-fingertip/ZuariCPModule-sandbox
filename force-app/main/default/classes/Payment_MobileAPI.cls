@RestResource(urlMapping='/GetPaymentAPI/*')
global without sharing class Payment_MobileAPI {

    @HttpPost
    global static void getPayments() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(Request_Type__c = 'GetPayment_MobileAPI',Request__c = requestBody);

        try {
            // ---------- Deserialize ----------
            PaymentRequestWrapper input =
                (PaymentRequestWrapper) JSON.deserialize(requestBody, PaymentRequestWrapper.class);

            if (String.isBlank(input.userId)) {
                sendError('UserId is required', log);
                return;
            }

            // ---------- Channel Partner ----------
            Channel_Partner__c cp = [
                SELECT Id
                FROM Channel_Partner__c
                WHERE User_Id__c = :input.userId
                AND Active__c = TRUE
                LIMIT 1
            ];

            // ---------- Build SOQL ----------
            String soql =
                'SELECT Id, Name,Payment_Line_Item__c, Property_Address__c, Payament_Status__c, ' +
                'Commission_Amount__c, Booking_Amount__c, Pending_Amount__c ' +
                'FROM Payment_Line_Item__c ' +
                'WHERE Channel_Partner__c = \'' + cp.Id + '\'';

            if (String.isNotBlank(input.paymentStatusId) && input.paymentStatusId != '0') {
                soql += ' AND Payament_Status__c = \'' +
                        String.escapeSingleQuotes(input.paymentStatusId) + '\'';
            }

            if (String.isNotBlank(input.projectId)) {
                soql += ' AND Project_name__c = \'' +
                        String.escapeSingleQuotes(input.projectId) + '\'';
            }

            Integer offsetSize = input.pageSize != null ? input.pageSize * 15 : 0;
            soql += ' ORDER BY CreatedDate DESC LIMIT 15 OFFSET ' + offsetSize;

            List<Payment_Line_Item__c> payments = Database.query(soql);

            // ---------- Build Response ----------
            PaymentSummary data = new PaymentSummary();
            data.paymentList = new List<PaymentLineItemWrapper>();

            Decimal totalProcessed = 0;
            Decimal totalPending = 0;
            Integer index = 1;

            for (Payment_Line_Item__c li : payments) {

                PaymentLineItemWrapper pw = new PaymentLineItemWrapper();
                pw.id = li.Payment_Line_Item__c;
                pw.personName = li.Name;
                pw.propertyAddress = li.Property_Address__c;
                pw.paymentStatus = li.Payament_Status__c;
                pw.commissionAmount = li.Commission_Amount__c;
                pw.bookingAmount = li.Booking_Amount__c;
                pw.pendingAmount = li.Pending_Amount__c;

                data.paymentList.add(pw);

                totalProcessed += (li.Commission_Amount__c != null ? li.Commission_Amount__c : 0);
                totalPending += (li.Pending_Amount__c != null ? li.Pending_Amount__c : 0);
            }

            data.processedAmount = formatInLakhs(totalProcessed);
            data.pendingAmount = formatInLakhs(totalPending);

            SuccessResponseWrapper res =
                new SuccessResponseWrapper(true, 'Payment data', data);

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody =
                Blob.valueOf(JSON.serialize(res));

            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;

        } catch (Exception e) {
            sendError('Failed to fetch payment data: ' + e.getMessage(), log);
        }
    }

    // ================= Helpers =================

    private static String formatInLakhs(Decimal amount) {
        if (amount == null) return '0L';
        Decimal lakhs = amount / 100000;
        return lakhs.setScale(1) + 'L';
    }

    // ================= Request =================
    public class PaymentRequestWrapper {
        public String userId;
        public String paymentStatusId;
        public String projectId;
        public Integer pageSize;
    }

    // ================= Response =================
    public class PaymentSummary {
        public String processedAmount;
        public String pendingAmount;
        public List<PaymentLineItemWrapper> paymentList;
    }

    public class PaymentLineItemWrapper {
        public String id;
        public String personName;
        public String propertyAddress;
        public String paymentStatus;
        public Decimal commissionAmount;
        public Decimal bookingAmount;
        public Decimal pendingAmount;
    }

    public class SuccessResponseWrapper {
        public Boolean status;
        public String message;
        public PaymentSummary data;

        public SuccessResponseWrapper(Boolean status, String message, PaymentSummary data) {
            this.status = status;
            this.message = message;
            this.data = data;
        }
    }

    public class ResponseWrapper {
        public Boolean status;
        public String message;
        public ResponseWrapper(Boolean status, String message) {
            this.status = status;
            this.message = message;
        }
    }

    private static void sendError(String msg, Apex_Log__c log) {

        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(new ResponseWrapper(false, msg)));

        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        insert log;
    }
}