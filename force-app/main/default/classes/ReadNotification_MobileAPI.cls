/****************************************************************
* Class Name   : ReadNotification_MobileAPI
* Company      : Fingertipplus
* Created Date : 22-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API marks notifications as read
* for a Channel Partner using userId and notificationIds.
*
* Input JSON:
* {
*   "userId": "9",
*   "notificationIds": [998, 999]
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Notification readed"
* }
*
* Author       : Sandeep Kumar
******************************************************************************************/
@RestResource(urlMapping='/ReadNotificationAPI/*')
global without sharing class ReadNotification_MobileAPI {

    @HttpPost
    global static void readNotifications() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'ReadNotification_MobileAPI',
            Request__c = requestBody
        );
        Boolean logInserted = false;

        try {
            ReadNotificationRequestWrapper input =
                (ReadNotificationRequestWrapper) JSON.deserialize(requestBody, ReadNotificationRequestWrapper.class);

            if (String.isBlank(input.userId) || input.notificationIds == null || input.notificationIds.isEmpty()) {
                sendError('userId and notificationIds are required', log, logInserted);
                return;
            }

            // Validate Channel Partner
            Channel_Partner__c cp = [
                SELECT Id, User_Id__c
                FROM Channel_Partner__c
                WHERE Active__c = TRUE AND User_Id__c = :input.userId
                LIMIT 1
            ];

            if (cp == null) {
                sendError('Channel Partner not found for userId: ' + input.userId, log, logInserted);
                return;
            }

            // Fetch notifications to update
            List<Notification__c> notificationsToUpdate = [
                SELECT Id, Name, isRead__c
                FROM Notification__c
                WHERE Channel_Partner__c = :cp.Id
                AND Name IN :input.notificationIds
            ];

            if (!notificationsToUpdate.isEmpty()) {
                for (Notification__c n : notificationsToUpdate) {
                    n.isRead__c = true;
                }
                update notificationsToUpdate;
            }

            // Success response
            SimpleResponseWrapper res =
                new SimpleResponseWrapper(true, 'Notification readed');

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

            // Log success
            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            logInserted = true;

        } catch (Exception e) {
            log.Status__c = 'FAIL';
            log.Error_Message__c = e.getMessage();
            log.Response__c = e.getStackTraceString();
            insert log;
            logInserted = true;

            sendError('Failed to update notifications: ' + e.getMessage(), log, logInserted);
        }
    }

    // ---------- Input Wrapper ----------
    public class ReadNotificationRequestWrapper {
        public String userId;
        public List<String> notificationIds;
    }

    // ---------- Response Wrapper ----------
    public class SimpleResponseWrapper {
        public Boolean status;
        public String message;

        public SimpleResponseWrapper(Boolean s, String m) {
            status = s;
            message = m;
        }
    }

    // ---------- Error Helper ----------
    private static void sendError(String msg, Apex_Log__c log, Boolean logInserted) {

        SimpleResponseWrapper res =
            new SimpleResponseWrapper(false, msg);

        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = JSON.serialize(res);

        if (logInserted) {
            update log;
        } else {
            insert log;
        }
    }
}